# Native Composer & WYSIWYG Editor Contract Review

- **Date**: 2026-11-05
- **Reviewer**: Gemini 4 Argon (read-only contract review)
- **Native baseline inspected**: `/home/dat/orca/workspaces/vnlfsocialapp/vnlf-production-audit`
- **Upstream reference snapshot**: `/home/dat/orca/reference/vnlf-social` pinned at `ab23799bf66ecec2176b89fa0c7e1151bf5782d3` (`SOURCE_REF:1`)
- **Policy**: No upstream code is copied into this repository or report. The native client is **not** production-ready; this document specifies the observed server contracts, exact native foundation conflicts, unknowns, and the bounded native WYSIWYG implementation plan.

---

## 1. Verified Server Contracts (`contracts/articles.ts`, `contracts/social.ts`, `articles.ts`, `media.ts`)

### 1.1 Lifecycle & Endpoint Matrix

| Operation | Endpoint | Source Location | Observed Contract & Constraints |
| :--- | :--- | :--- | :--- |
| **Create draft** | `POST /api/v1/articles` | `apps/api/src/modules/articles.ts:110` | Auth required. Takes no body; inserts a new draft (`slug: "draft-${id}"`, `contentJson: { type: "doc", content: [{ type: "paragraph" }] }`), returns HTTP `201` with `articleDto`. |
| **Load draft / post** | `GET /api/v1/articles/:id` | `apps/api/src/modules/articles.ts:111` | Returns `articleDto`. Non-authors receive `404 ARTICLE_NOT_FOUND` when status is `DRAFT`, `ARCHIVED`, or `REMOVED`. |
| **List own articles** | `GET /api/v1/me/articles` | `apps/api/src/modules/articles.ts:114` | Auth required. Optional query `status` (`DRAFT` \| `PUBLISHED` \| `ARCHIVED`), ordered by `updatedAt DESC`, limit 50. Returns `{ items: ArticleDto[] }`. |
| **Set draft poll** | `PUT /api/v1/articles/:id/poll` | `apps/api/src/modules/articles.ts:116-126` | Owner only. Body `{ poll: PollInput \| null }`. Allowed only while `publishedAt` is null; once published, throws `409 POLL_LOCKED` (`articles.ts:119`). |
| **Save draft / edit** | `PATCH /api/v1/articles/:id` | `apps/api/src/modules/articles.ts:127-159`, `packages/contracts/src/articles.ts:13-23` | Owner only (`status !== "REMOVED"`). Validates `ArticleSaveBodySchema`, checks `version === body.version` (`409 ARTICLE_VERSION_CONFLICT` at `articles.ts:140`), increments `version` by 1, replaces `article_tags` and `article_assets`, returns `articleDto`. |
| **Presign asset** | `POST /api/v1/articles/:id/assets/presign` | `apps/api/src/modules/articles.ts:160`, `packages/contracts/src/articles.ts:49-55`, `apps/api/src/lib/media.ts:14-21,72-81` | Owner only. Validates `PresignAssetBodySchema` (`fileName` 1..255, `mime`, `size` 1..200 MiB, `placement`: `COVER` \| `INLINE` \| `ATTACHMENT`). Returns `{ assetId, uploadUrl, expiresIn: 600, headers: { "content-type": mime } }`. |
| **Complete asset** | `POST /api/v1/articles/:id/assets/:assetId/complete` | `apps/api/src/modules/articles.ts:161`, `apps/api/src/lib/media.ts:45-55,83-92` | Owner only; verifies `asset.metadata.articleId === params.id` (`400 ARTICLE_ASSET_INVALID`) and S3 `HeadObject` size/mime (`409 ASSET_UPLOAD_INCOMPLETE`, `400 ASSET_MISMATCH`). Upserts `article_assets` row. Does **not** increment `articles.version`. |
| **Poll asset status** | `GET /api/v1/articles/:id/assets/:assetId` | `apps/api/src/modules/articles.ts:163` | Owner only. Used while video transcoding runs. Returns `{ id, status, mime, size, width, height, url, posterUrl, durationMs, state?, error? }`. |
| **Delete asset** | `DELETE /api/v1/articles/:id/assets/:assetId` | `apps/api/src/modules/articles.ts:164`, `apps/api/src/lib/media.ts:57-65` | Owner only. Deletes `article_assets` link, deletes S3 objects (`storageKey`, `sourceKey`, `posterKey`), marks asset `DELETED`. Does **not** increment `articles.version`. |
| **Publish** | `POST /api/v1/articles/:id/publish` | `apps/api/src/modules/articles.ts:165-209` | Owner only. Takes **no request body**; requires `idempotency-key` header (`400 IDEMPOTENCY_KEY_REQUIRED` at `articles.ts:169`). Rate-limited to 5 publishes/hour (`articles.ts:167`). Publishes current DB state, increments `version` by 1, writes `article_revisions`, returns `articleDto`. |
| **Archive / Restore / Delete** | `POST .../archive`, `POST .../restore`, `DELETE /api/v1/articles/:id` | `apps/api/src/modules/articles.ts:210-212` | Archive requires `PUBLISHED` (`409 ARTICLE_NOT_PUBLISHED`); Restore requires `ARCHIVED` + non-null `publishedAt` (`409 ARTICLE_NOT_RESTORABLE`) and not moderated (`409 ARTICLE_MODERATED` at `articles.ts:28`); Delete soft-deletes to `REMOVED`. |

### 1.2 Format-Specific Server Rules (`POST` vs `ARTICLE`)

| Dimension | `format: "POST"` | `format: "ARTICLE"` | Source Evidence |
| :--- | :--- | :--- | :--- |
| **Title** | Forced to `null` on save (`PATCH`) regardless of request payload; publish slug falls back to first non-empty body line (`<= 180` chars). | Nullable string (`maxLength: 180`); trimmed, empty string saved as `null`. | `contracts/articles.ts:16`, `articles.ts:139,191` |
| **Excerpt** | Server ignores `body.excerpt` and overwrites with normalized body text prefix (`<= 220` chars). | Optional string (`maxLength: 220`); falls back to body text prefix (`<= 220` chars) when empty. | `contracts/articles.ts:17`, `articles.ts:139` |
| **Tags** | Server ignores `body.tags` and extracts `#hashtags` from `body.contentJson` up to `HASHTAG_LIMIT`. | Deduplicated by `slugify(name)`, trimmed, capped at 3 tags (`minLength: 1, maxLength: 40`). | `contracts/articles.ts:18`, `articles.ts:137` |
| **Cover Image** | Forced to `coverAssetId: null` and `coverAlt: ""` on save (`PATCH`). | Nullable `coverAssetId` (UUID) and `coverAlt` (`maxLength: 300`), saved with `placement: "COVER"`. | `contracts/articles.ts:19-20`, `articles.ts:132,139,156` |
| **Inline Images (`contentJson`)** | **Forbidden**: if `collectAssetIds(body.contentJson)` is non-empty, `PATCH` fails with `400 POST_INLINE_IMAGE`. | Allowed (`placement: "INLINE"`). Linked in `article_assets` from `collectAssetIds(body.contentJson)`. | `articles.ts:130,148-149` |
| **Attachments (`attachments[]`)** | Up to 20 items (`{ assetId, alt <= 300 }`), no duplicates (`400 DUPLICATE_ATTACHMENT`). Supports images and at most **1 video**. | Up to 20 image attachments (`{ assetId, alt <= 300 }`). **Videos forbidden** (`400 VIDEO_POST_ONLY`). | `contracts/articles.ts:22`, `articles.ts:87-91,150-155` |
| **Video Rules** | Max 1 video (`400 VIDEO_LIMIT`), `placement: "ATTACHMENT"` only (`400 VIDEO_POST_ONLY`), `video/mp4` \| `video/quicktime` \| `video/webm`, `<= 200 MiB`, `<= 30s`, 20 uploads/day limit. | Rejected on save/publish with `400 VIDEO_POST_ONLY`. | `contracts/articles.ts:45-55`, `articles.ts:87-91,160`, `media.ts:72-75` |
| **Total Asset Limit** | Publish rejects if `attachments + inline + cover > 21` (`400 ARTICLE_IMAGE_LIMIT`). | Publish rejects if `attachments + inline + cover > 21` (`400 ARTICLE_IMAGE_LIMIT`). | `articles.ts:181-183` |
| **Polls** | Supported via `PUT /api/v1/articles/:id/poll` before first publish (`publishedAt == null`). | Not returned in `articleDto` (`row.article.format === "POST"` guard). | `articles.ts:54,116-126` |

### 1.3 Observed TipTap Document Schema (`ArticleNodeSchema` & `article-renderer.tsx`)

- **Envelope** (`packages/contracts/src/articles.ts:4-10`): recursive node with `type` (`1..40` chars), optional `text` (`<= 200,000` chars), optional `attrs` (`Record<string, unknown>`), optional `marks` (`Array<{ type: string, attrs?: Record<string, unknown> }>`), and optional `content` (`Node[]`).
- **Rendered Block Nodes** (`apps/web/components/social/article-renderer.tsx:16-34`, `apps/web/app/globals.css:1048-1075,1103-1115`):
  - `paragraph`: inline children (or `<br />` when empty).
  - `heading`: `attrs.level === 3 ? 3 : 2` (`<h2>` or `<h3>` only).
  - `blockquote`: nested block children.
  - `bulletList` / `orderedList`: `listItem` children.
  - `listItem`: block children (typically `paragraph`, or nested lists).
  - `codeBlock`: plain text extracted recursively (`plainText(node)` at `article-renderer.tsx:50-53`).
  - `horizontalRule`: `<hr />`.
  - `image`: block figure with `attrs.assetId` (resolved to `src` by server/DTO), `attrs.src`, `attrs.alt`, `attrs.caption` (`<figcaption>`), and `attrs.layout` (`"normal"` default, `"wide"`, or `"full"`). Missing `src` renders the missing-image placeholder (`article-renderer.tsx:31`).
- **Rendered Inline Nodes & Marks** (`article-renderer.tsx:36-48`):
  - `text` and `hardBreak` (`<br />`).
  - Marks: `bold` (`<strong>`), `italic` (`<em>`), `strike` (`<s>`), `code` (`<code>`), and `link` (`<a>` only when `attrs.href` is a string matching `/^(https?:\/\/|mailto:)/i`).

---

## 2. Exact Conflicts in the Current Native Composer Foundation

Direct inspection of `lib/src/features/composer/` and `lib/src/core/api_client.dart` in `vnlf-production-audit` identified the following concrete contract mismatches:

1. **`ComposerDraft` & `draftFromJson` Drop Inline Asset Catalog, Cover URL, and Video Processing State** (`lib/src/features/composer/domain/composer_draft.dart:1-64`, `lib/src/features/composer/data/composer_repository.dart:10-40`):
   - `articleDto` (`articles.ts:61-64`) separates `assets` (all `READY` inline/cover/attachment assets with `id`, `url`, `width`, `height`, `mime`, `size`) from `attachments` (`placement === "ATTACHMENT"` only). `draftFromJson` (`composer_repository.dart:25-39`) reads only `json['attachments']` and ignores `json['assets']` and `json['coverUrl']`. Loading an `ARTICLE` draft leaves inline `image` nodes (`attrs.assetId`) and `coverAssetId` without resolved preview URLs.
   - `ComposerDraft.copyWith` (`composer_draft.dart:42-63`) omits `coverAssetId`, `coverAlt`, `status`, and `slug`, making it impossible to set or clear (`null`) a cover image or edit `coverAlt` through `copyWith`.
   - For author video attachments that are still transcoding or failed (`articles.ts:32-36,49-50,64`, `social.ts:17-21`), `articleDto` returns `url: null` and `state: "PROCESSING" | "FAILED"` (plus `error`, `posterUrl`, `durationMs`). `draftFromJson` (`composer_repository.dart:27-32`) coerces `url: null` to `""` and discards `state`, `error`, `posterUrl`, `durationMs`, `width`, and `height`.

2. **`LiveComposerRepository.upload` Hardcodes `ATTACHMENT`, Mismatches Image Size Limits, and Breaks on Video Completion** (`lib/src/features/composer/data/composer_repository.dart:100-132`):
   - Line `111` hardcodes `'placement': 'ATTACHMENT'` in `POST /api/v1/articles/:id/assets/presign`. It cannot upload `INLINE` article images (`placement: "INLINE"`) or article covers (`placement: "COVER"`).
   - Line `101` allows up to `209,715,200` bytes (200 MiB) for all uploads, whereas `presignImage` (`media.ts:15-16`) rejects images `> 10 MiB` (`400 ASSET_TOO_LARGE`) and non-image MIME types (`400 ASSET_MIME_INVALID`).
   - Lines `123-131` assume `POST .../complete` returns a non-null `url`. While `completeImage` (`media.ts:54`) returns `{ assetId, status: "READY", url }`, `completeVideo` (`media.ts:91`) returns `{ assetId, status: "PENDING", url: null }`. `LiveComposerRepository` has no method to poll `GET /api/v1/articles/:id/assets/:assetId` (`articles.ts:163`) until `status === "READY"`, so publishing after uploading a video immediately triggers `409 VIDEO_PROCESSING` (`articles.ts:185`).

3. **`PATCH /api/v1/articles/:id` Replaces All `article_assets` Rows on Every Save** (`apps/api/src/modules/articles.ts:147-156` vs `lib/src/features/composer/data/composer_repository.dart:63-81`):
   - `PATCH` executes `DELETE FROM article_assets WHERE article_id = :id` (`articles.ts:147`) and re-inserts only:
     1. `collectAssetIds(body.contentJson)` as `INLINE` (`articles.ts:148-149`),
     2. `body.attachments` as `ATTACHMENT` (`articles.ts:150-155`), and
     3. `coverAssetId` as `COVER` (`articles.ts:156`).
   - If an editor round-trip drops `attrs.assetId` from an inline `image` node in `contentJson`, or if an upload completes (`POST .../complete` inserts into `article_assets` at `articles.ts:161`) while an older autosave `PATCH` payload is in flight without that `assetId`, the `PATCH` unlinks the asset from `article_assets`. Subsequent `articleDto` reads and `publish` (`articles.ts:61,189-190`) then render an empty `src=""` (`article-image-missing`).

4. **Publish Takes No Body and Races with Unsaved Edits or Concurrent Saves** (`apps/api/src/modules/articles.ts:139-140,165-209` vs `lib/src/features/composer/data/composer_repository.dart:83-91`):
   - `POST /api/v1/articles/:id/publish` ignores local client state and publishes the database row at `articles.version` (`articles.ts:176-196`).
   - If the native client calls `publish` without first awaiting a successful `PATCH` of dirty local state, the server either publishes stale content or throws `400 ARTICLE_EMPTY` (`articles.ts:182`).
   - If an autosave `PATCH` and a manual `PATCH` or `publish` overlap, the second request fails with `409 ARTICLE_VERSION_CONFLICT` (`articles.ts:140,196`).

5. **Client Validation Gaps and Silent Error Body Loss in `ApiClient`** (`lib/src/core/api_client.dart:155-161`, `lib/src/domain/models.dart:6-9`):
   - `LiveComposerRepository.save` (`composer_repository.dart:63-81`) does not enforce `ArticleSaveBodySchema` bounds (`title <= 180`, `excerpt <= 220`, `tags` max 3 items of `1..40` chars, `coverAlt <= 300`, `attachments` max 20 unique items with `alt <= 300`). For example, passing `tags: [""]` or 4 tags causes Elysia schema validation to reject the entire `PATCH` with HTTP `422` before reaching `articles.ts:137`.
   - `ApiClient` (`api_client.dart:160`) throws `HttpFailure(response.statusCode)` and discards the JSON error payload (`{ code, message, requestId }`). Consequently, the presentation layer cannot distinguish `409 ARTICLE_VERSION_CONFLICT`, `409 VIDEO_PROCESSING`, `409 ARTICLE_MODERATED`, or `409 ASSET_UPLOAD_INCOMPLETE`, nor distinguish `400 POST_INLINE_IMAGE`, `400 VIDEO_POST_ONLY`, `400 VIDEO_LIMIT`, `400 ARTICLE_EMPTY`, or `400 VIDEO_FAILED`.

6. **`composeDocument` (`compose_document.dart`) is One-Way and Lossy for Existing Drafts & Images** (`lib/src/features/composer/domain/compose_document.dart:1-155`):
   - There is no `contentJson -> editor` deserializer; `documentPlainText` (`compose_document.dart:135-155`) strips all formatting, structure, links, and media.
   - `composeDocument` converts Markdown `<img>` tags into plain text of `alt` (`compose_document.dart:31-33`), losing `image` nodes, `assetId`, `src`, `caption`, and `layout`.

---

## 3. Unknowns & Unverified Source Areas

The selective snapshot at `/home/dat/orca/reference/vnlf-social` omits several internal helper modules and web composer files. Per `AGENTS.md`, these are labeled `[UNKNOWN]` rather than guessed:

- **`[UNKNOWN]` `apps/api/src/lib/article-content.ts` (`collectAssetIds`, `articleText`, `renderArticleHtml`)**: Imported at `articles.ts:12` but not present in the snapshot. While `article-renderer.tsx:16-48` and `globals.css:1110-1115` confirm the rendered node/mark set and `figure.article-image` (`normal` / `wide` / `full`) HTML output, the exact traversal rules in `collectAssetIds` (e.g. whether it inspects only `type === "image"` `attrs.assetId`) and `renderArticleHtml` sanitizer rules are not in the snapshot.
- **`[UNKNOWN]` `HASHTAG_LIMIT` and `extractHashtags` implementation**: Imported from `@vnlf/contracts` at `articles.ts:3` (`packages/contracts/src/common.ts` is not in the snapshot). Used when saving `format: "POST"` (`articles.ts:137`).
- **`[UNKNOWN]` `PollInputSchema` / `PollDtoSchema` (`packages/contracts/src/polls.ts`, `apps/api/src/lib/polls.ts`)**: Imported at `articles.ts:3,11` and `social.ts:6` but omitted from the snapshot. Poll option count, character limits, and duration constraints remain unverified.
- **`[UNKNOWN]` Web composer autosave debounce interval, video polling interval, and `apps/worker` transcoding timeouts**: The web composer source (`apps/web/...`) and `apps/worker` are not in the snapshot.
- **`[UNKNOWN]` Initial `version` value returned by `POST /api/v1/articles` on live server**: `packages/db` table defaults are not in the snapshot; `ArticleSaveBodySchema` (`contracts/articles.ts:14`) accepts `version >= 0`, so the native client must always read `version` from the server response rather than assuming `0` or `1`.

---

## 4. Native WYSIWYG Editor Choice & TipTap Schema Mapping Analysis

### 4.1 Maintained Native WYSIWYG Package Evaluation (Official pub.dev Sources)

Plain Markdown textareas do not provide website-editor parity (toolbar/slash formatting, WYSIWYG headings/lists/quotes/code, inline article image cards with layout/caption controls). Between the two maintained Flutter Delta-based WYSIWYG editors on pub.dev:

| Criteria | `fleather` (`^1.28.0`) + `parchment` | `flutter_quill` (`^11.6.0`) |
| :--- | :--- | :--- |
| **Platform Support (pub.dev)** | Linux, Android, iOS, macOS, Windows, Web (pure Flutter/Dart). | Linux, Android, iOS, macOS, Windows, Web. |
| **Dependency Footprint** | Minimal: `parchment`, `parchment_delta`, `collection`, `intl`, `flutter_localizations`. Zero native platform plugins. | Heavier: pulls in `quill_native_bridge`, `flutter_keyboard_visibility_temp_fork`, `url_launcher`, etc. (`flutter_quill_extensions` adds `image_picker`/`video_player`/`gal`, duplicating existing `file_selector` and `media_kit`). |
| **Document Model** | Quill Delta via `ParchmentDocument`, `ParchmentAttribute`, `BlockEmbed`, `SpanEmbed`. | Quill Delta via `Document`, `Attribute`, `CustomBlockEmbed`, `EmbedBuilder`. |
| **Fit for VNLF Client** | **Recommended**: Leanest dependency graph, zero native plugin risk on Linux/Android, clean `BlockEmbed` builder API for inline `ARTICLE` image cards and raw-node preservation. | Viable alternative **only if used without `flutter_quill_extensions`**, using custom `EmbedBuilder`s; adds unnecessary native bridge dependencies. |

### 4.2 TipTap (`ArticleNodeSchema`) <-> Delta Mapping Fidelity & Loss-Prevention Table

Both `fleather` and `flutter_quill` use a flat line-oriented Quill Delta model, whereas TipTap (`ArticleNodeSchema`) is a recursive block tree. A dedicated **`TipTapDeltaCodec`** is mandatory; built-in Delta converters lose VNLF fields.

| TipTap Construct | Delta Representation (`fleather` / `flutter_quill`) | Round-Trip Preservation & Required Adapter Behavior |
| :--- | :--- | :--- |
| **Marks (`bold`, `italic`, `strike`, `code`, `link`)** | Inline attributes (`b`, `i`, `s`, `c`, `a: href`). | **Preserved** when mapped explicitly. Validate `link.attrs.href` against `/^(https?:\/\/|mailto:)/i` (`article-renderer.tsx:45`). If a text node carries an unknown mark or extra mark `attrs`, preserve the enclosing block via `vnlf_raw_block` to avoid silent mark stripping. |
| **Headings (`heading`, `attrs.level: 2 \| 3`)** | Line attribute `heading: 2` or `3`. | **Preserved**. Expose only H2 and H3 in the native toolbar (`article-renderer.tsx:19-22`). Clamp imported heading levels outside `{2, 3}` only if user edits the heading, or map `{1,2} -> 2` and `{3..6} -> 3` matching renderer semantics. |
| **`hardBreak` inside blocks** | Inline sentinel or custom `SpanEmbed('br')`. | **Conflict if unmapped**: Delta uses `\n` for block breaks. Mapping `hardBreak` to `\n` splits one paragraph/heading into two. Map `hardBreak` to a dedicated inline embed or `\u2028` sentinel so `TipTap <-> Delta` preserves intra-paragraph line breaks. |
| **Lists (`bulletList`, `orderedList`, `listItem`)** | Line attribute `block: ul` / `ol` + `indent`. | **Partial conflict**: Delta lists are flat lines. Single-paragraph `listItem`s (including nested lists via `indent`) round-trip if the codec reconstructs nested `bulletList`/`orderedList` inside the parent `listItem`. Multi-block `listItem`s or `orderedList` with custom `attrs.start != 1` cannot be represented flatly and must fall back to `vnlf_raw_block` unless edited. |
| **`blockquote`** | Line attribute `block: quote`. | **Preserved for paragraph quotes**: Group consecutive `quote` lines into one `blockquote` containing `paragraph` children on export; split `blockquote` paragraphs into `quote` lines on import. If a `blockquote` contains non-paragraph blocks (e.g. lists/code), preserve as `vnlf_raw_block`. |
| **`codeBlock`** | Line attribute `block: code`. | **Critical conflict if ungrouped**: Delta applies `code` per line. On export (`Delta -> TipTap`), consecutive `code` lines **must** be merged into a single `codeBlock` node with `\n`-joined text (`article-renderer.tsx:27`); otherwise each line becomes a separate code block widget. |
| **`horizontalRule`** | `BlockEmbed('hr')` / divider embed. | **Preserved 1:1** (`{ "type": "horizontalRule" }`). |
| **Inline `image` (`assetId`, `src`, `alt`, `caption`, `layout`)** | Custom `BlockEmbed('vnlf_image', data)` (`ARTICLE` only). | **Lost by default image embeds**. Must use a custom `vnlf_image` block embed storing `{ assetId, src, alt, caption, layout: "normal" \| "wide" \| "full", width, height }`. On export, emit `{ "type": "image", "attrs": { ... } }` with `assetId` intact so `PATCH` does not unlink `INLINE` assets (`articles.ts:148`). Forbidden in `POST` mode (`articles.ts:130`). |
| **Unsupported / unknown nodes (`ArticleNodeSchema`)** | Custom `BlockEmbed('vnlf_raw_block', rawJson)`. | **Preserved 1:1**: Any block node that fails a strict lossless `TipTap -> Delta -> TipTap` check is wrapped in a read-only `vnlf_raw_block` embed rendered with `VnlfRichContent`, emitting its original JSON unchanged on save. |
| **Cover (`coverAssetId`, `coverUrl`, `coverAlt`)** | Outside Delta: top-level `ComposerDraft` state (`ARTICLE` only). | Managed in the `ARTICLE` settings pane (`placement: "COVER"`). Cleared/hidden in `POST` mode (`articles.ts:132,139`). |
| **Attachments & Video Processing (`attachments[]`)** | Outside Delta: `ComposerDraft.media` tray (`POST` & `ARTICLE`). | `POST` attachments support up to 20 images or 1 video (`<= 30s`, `<= 200 MiB`). Video uploads return `status: "PENDING"` (`media.ts:91`) and must poll `GET /api/v1/articles/:id/assets/:assetId` (`articles.ts:163`) until `READY` before enabling Publish. |

---

## 5. Concrete Small Implementation Plan with User-Visible Loss Prevention

1. **Extend `HttpFailure` & `ComposerDraft` Contract Models (`domain` / `data`, no UI slop)**:
   - Add optional `code`, `serverMessage`, and `requestId` fields to `HttpFailure` in `lib/src/domain/models.dart` and populate them from `{ code, message, requestId }` in `ApiClient` (`lib/src/core/api_client.dart:155-161`).
   - Extend `DraftMedia` (`lib/src/features/composer/domain/composer_draft.dart:1-12`) with `status`/`state` (`READY` \| `PROCESSING` \| `FAILED`), `error`, `width`, `height`, `posterUrl`, `durationMs`, and `placement` (`ATTACHMENT` \| `INLINE` \| `COVER`).
   - Extend `ComposerDraft` (`composer_draft.dart:14-64`) with `coverUrl` (`String?`) and `assets` (`Map<String, DraftMedia>` parsed from `json['assets']` in `draftFromJson` so inline `assetId`s resolve their URLs and dimensions), and update `copyWith` to support updating/clearing `coverAssetId` and `coverAlt`.

2. **Fix `LiveComposerRepository` Upload, Asset Polling, and Client-Side Pre-Validation (`lib/src/features/composer/data/composer_repository.dart`)**:
   - Parameterize `upload(String id, ComposerUpload file, {required String placement})` (`ATTACHMENT` \| `INLINE` \| `COVER`).
   - Validate before presigning:
     - Images (`image/jpeg`, `image/png`, `image/webp`, `image/gif`): `1 <= size <= 10 * 1024 * 1024` (`10 MiB`).
     - Videos (`video/mp4`, `video/quicktime`, `video/webm`): allowed only when `format == 'POST'` and `placement == 'ATTACHMENT'`, max 1 video per draft, `1 <= size <= 200 * 1024 * 1024` (`200 MiB`).
   - Add `Future<DraftMedia> pollAsset(String id, String assetId)` calling `GET /api/v1/articles/:id/assets/:assetId` (`articles.ts:163`) with gentle backoff (`2s -> 4s`) while `status == 'PENDING'` / `state == 'PROCESSING'`.
   - Validate `save` payload locally before `PATCH` (`title <= 180`, `excerpt <= 220`, `tags` max 3 of `1..40` non-empty chars, `coverAlt <= 300`, `attachments` max 20 unique IDs, total assets `<= 21`).

3. **Build Bidirectional `TipTapDeltaCodec` with Lossless Guard (`lib/src/features/composer/domain/`)**:
   - Implement `TipTapDeltaCodec` converting between `Map<String, dynamic>` (`contentJson`) and the editor controller (`fleather` recommended; Core owner to approve `pubspec.yaml` addition).
   - Group consecutive `code` lines into single `codeBlock` nodes and consecutive `quote` lines into single `blockquote` nodes; preserve `hardBreak` via inline embed/sentinel; preserve inline `ARTICLE` images via `vnlf_image` `BlockEmbed` (`assetId`, `src`, `alt`, `caption`, `layout`); preserve any non-round-trippable block via `vnlf_raw_block` `BlockEmbed`.
   - Retain `composeDocument` (`compose_document.dart`) strictly as an optional "Paste/Import Markdown" helper.

4. **Serialized Save/Publish Controller & User-Visible Loss Prevention (`presentation`)**:
   - **Single-flight mutation queue**: Serialize all `PATCH /api/v1/articles/:id` and `POST /api/v1/articles/:id/publish` calls per draft. Never run concurrent saves; never auto-retry failed writes.
   - **Save-before-publish gate**: Clicking Publish when `isDirty` awaits `save(draft)` first, updates `version` from the `PATCH` response, verifies no attachment has `state == 'PROCESSING'` or `'FAILED'`, and then calls `publish(savedDraft, idempotencyKey: attemptUuid)`.
   - **Local recovery & failed-save banner**: Keep unsaved edits in memory and local preferences recovery keyed by `(userId, draft.id, baseVersion)`. On save/publish failure, keep the editor open, show the server error code/message in the composer status bar, and allow manual retry.
   - **`409 ARTICLE_VERSION_CONFLICT` dialog**: Fetch the latest server draft without clobbering local text and let the user choose between **"Ghi đè bằng bản đang sửa"** (rebase local state onto the latest server `version` and re-save) or **"Tải lại bản trên máy chủ"**.
   - **Format-switch guard (`ARTICLE` -> `POST`)**: Warn the user before switching to `POST` if `title`, `excerpt`, `tags`, `coverAssetId`, or inline `vnlf_image` embeds exist, offering to move inline images into `POST` attachments (up to 20) rather than triggering `400 POST_INLINE_IMAGE` or silently wiping `ARTICLE` metadata on the next save.
