# VNLF API Notes: Network Protocol & Data Contracts

All endpoints, payload schemas, and realtime events documented here are derived directly from `vietnamlinuxfamily.net` production client bundles and live network inspection. Never invent endpoints.

## Current live persistence evidence — 2026-11-06

This supplements the pinned source contracts and supersedes historical
unauthenticated-only assumptions below. Using only the authorized owner account
and its own newly created content, the production repositories confirmed:

- Draft POST creation, versioned body PATCH, separate poll PUT, then publication.
  Fresh article reads contained the published body and the poll with two options.
- Comment creation with a stable client identity, fresh-read persistence, editing,
  voting and deletion; fresh reads confirmed the edited body, vote and deletion.
- Poll voting persisted in a fresh article read. The vote was removed afterward.
- On the named controlled, accepted DM conversation, sending, editing and reacting
  persisted in fresh history reads. The reaction and message were removed, and
  a further history read confirmed the test message absent.

Cleanup removed the test comment vote, comment, poll vote and post. The owner
projection returned status REMOVED and an independent guest GET returned 404.
Sessions were logged out and fresh session reads were empty. No credentials,
cookies, private message bodies or response dumps were retained in the repository
or reports. These checks do not establish desktop keyring persistence or device UI.

Composer poll input is saved through the shared PollRepository adapter, separately
from the body. The poll PUT does not advance the body version. A failed poll save
must keep the already acknowledged PATCH version; incomplete poll input stays in
owner-scoped secure recovery and blocks publishing. Text-only saves must not
replace a poll, because the server replaces option IDs on draft poll writes.

Pinned source re-check: realtime is raw JSON WebSocket at `/ws/community`, with
client events such as `channel:join`, `conversation:join`, `presence:heartbeat`
and `dm:typing`, rather than Socket.IO or dotted `dm.join` frames. Server
envelopes carry type/eventId/occurredAt/data. Native channel and DM views now use
an owner-bound shared connection with topic leases and reconnect catch-up. Its
synthetic tests cover routing, duplicate events, viewer-specific reactions and
polls, lifecycle, and in-flight history reconciliation. Source confirmation is
not live socket verification: on 2026-11-06 an authenticated owner probe received
HTTP 403 from Cloudflare for the WebSocket upgrade in this environment. No test
message was sent; the connection closed, logout succeeded, and cleanup was clear.
Whether this response is specific to this network or configuration remains unknown.

## Article slugs, error retry hints and client id — 2026-11-08

- `GET /api/v1/articles/:id` matches only the UUID column. Public links
  (`/a/{slug}`) must use `GET /api/v1/articles/slug/:slug`, which returns the
  same article projection and also resolves renamed (old) slugs; unpublished
  articles answer 404 `ARTICLE_NOT_FOUND`. Two read-only guest GETs on
  2026-11-08 confirmed it on production: the slug route returned 200 for a
  public article, while the id route given the same slug returned 500
  `INTERNAL_ERROR` with `retryable: false`. `LivePostRepository` now picks the
  route from the value's shape, and the thread view treats 404 as "not found".
- Error envelopes may carry `retryable`. `ApiClient` no longer retries a
  429/5xx response that says `retryable: false`; responses without the hint
  (for example proxy HTML) keep the bounded GET retry.
- Every API request now carries `x-vnlf-client`: one random UUID per app
  process, like the website's per-tab id (`apps/web/lib/api.ts`). The server
  only uses it as the `origin` of `read:synced` events after HTTP read marks
  (`apps/api/src/lib/read-sync.ts`). The native client does not yet consume
  `read:synced`, so this changes no behaviour today.

## Projects, account profile and member feedback (pinned source)

The following contracts were checked against upstream commit
`ab23799bf66ecec2176b89fa0c7e1151bf5782d3` and implemented with synthetic tests;
no live account or feedback writes were made in this pass. An owner-authenticated
read-only probe successfully loaded the matching owner profile, feedback history,
and the public projects listing with facets, then logged out successfully.

- `GET /api/v1/projects` supports `type`, `language`, `seeking`, `q`, `sort`,
  and an opaque `cursor`. The first response includes global type/language
  facets and `nextCursor`; subsequent pages are deduplicated by project ID.
  `GET /api/v1/projects/:slug` returns the detail, media and viewer rating
  projection. A real project detail was read successfully from the deployed API;
  no rating, project edit or other project write was performed. The native rating
  control uses the source-confirmed `PUT /api/v1/projects/:id/rating` with a
  1–5 `score` and `DELETE` to remove a rating. It requires the returned viewer
  score and summary, handles uncertain outcomes with a fresh read, and never
  automatically retries a write. Concurrent server queries can return a rating
  distribution that temporarily differs from the aggregate count.
- `GET /api/v1/users/:username` supplies profile fields.
  `PATCH /api/v1/me/profile` accepts optional username, displayName, bio and
  website and acknowledges with `ok: true`. For uncertain writes, the app
  verifies through a read rather than automatically resending. It checks that
  the returned profile ID matches the authenticated owner.
- `GET /api/v1/feedback/mine` lists the signed-in member's tickets,
  `GET /api/v1/feedback/:id/messages` reads an owned ticket and its messages,
  and `POST` to the same messages route submits a message with a stable
  `clientMessageId`. The source enforces ticket ownership.

## Notifications (pinned source and live read)

The upstream web notification center uses `GET /api/v1/notifications` with
`limit`, `filter`, `kind` (all/like/comment/follow/system), and an optional
cursor. The native sheet passes both filters to the server. Its API responds to
`POST /api/v1/notifications/seen` and `/read` with `{ok: true}`. The native
client now requires that acknowledgment before considering either write
confirmed. An owner-authenticated read-only notification-list probe succeeded
and logged out; it did not mark any notification read or seen.

## Push Notification Architecture & Server Source Analysis (2026-11-07)

- **Backend Protocol**: The backend (`apps/api/src/modules/push.ts`) implements **W3C Web Push with VAPID** (RFC 8291 / RFC 8292).
  - `GET /api/v1/push/config` returns `{ enabled: boolean, publicKey?: string }`.
  - `GET /api/v1/push/subscriptions` lists active endpoints for the current session.
  - `POST /api/v1/push/subscriptions` accepts `{ endpoint, keys: { p256dh, auth } }`.
  - Allowed push endpoints are restricted strictly to browser push services: `fcm.googleapis.com`, `updates.push.services.mozilla.com`, `web.push.apple.com`, and `*.notify.windows.com`.
  - Push delivery worker (`apps/worker/src/processors/push.ts`) uses npm `web-push` via BullMQ queues.
- **Native Android / Client Implications**:
  - The server repo has **NO native Firebase Cloud Messaging (FCM HTTP v1 / google-services.json)** or APNs or UnifiedPush server integration configured.
  - On native desktop/mobile clients (Flutter), active real-time updates and notifications arrive directly over the persistent WebSocket connection (`/ws/community`) with topic subscriptions (`channel:join`, `conversation:join`, etc.).
  - For future background push on Android without Play Services or via UnifiedPush, the backend would need an upstream gateway or endpoint whitelist update.

### Native client policy and v0.1.0 cleanup (2026-11-09)

[CONFIRMED from source `ab23799`] details that matter for cleanup:
- `POST` checks only the endpoint host, the 65-byte key starting with `0x04` and the 16-byte auth secret. It does not check that the key is a real P-256 point, and it caps an account at ten subscriptions.
- `DELETE /api/v1/push/subscriptions` with `{ endpoint }` deletes the signed-in user's row for that endpoint and returns `{ ok: true }` even when no row matched. The website calls it the same way (`push-settings.tsx`, `push-sw.js`).
- The worker deletes a subscription only after a 404 or 410 from the push service. Any other failure, such as an encryption error, keeps the row, marks the delivery failed and rethrows for a retry when no subscription succeeded.

The native client registers no Web Push subscription, because no native push service can receive one. v0.1.0 did register one from the Settings switch, with random bytes as `p256dh`/`auth` and an invented `https://fcm.googleapis.com/fcm/send/<random>` endpoint cached in shared preferences (`vnlf_push_endpoint`). The server cannot encrypt for that key, so every delivery fails. When a member signs in or a session loads, the client now sends one `DELETE` for the cached endpoint. It forgets the cached values after `{ ok: true }` and keeps them after a failure for the next sign-in; the delete is never retried automatically.

## Read Receipts & Real-time Read State (2026-11-07)

- `POST /api/v1/dm/conversations/:id/read` accepts `{ lastReadMessageId?: string }` and publishes `dm:peer-read` to peers.
- `POST /api/v1/channels/:id/read` accepts `{ lastReadMessageId?: string }` and updates `channelReadStates`.
- `GET /api/v1/dm/conversations` returns `unreadCount` calculated by counting non-deleted messages from other authors strictly after `member.lastReadMessageId`.
- The native client invalidates client cache and triggers `markRead` upon viewing conversations or receiving incoming peer messages.

## Public article sharing (2026-11-05)

- [CONFIRMED] The public feed links posts to `/a/{slug}`. Read-only inspection
  of the feed HTML and current `2k5v3l48k2d3c.js` chunk confirmed
  `e.href ?? \`/a/${e.slug}\``. The native `/thread/:id` route is internal and
  must not be copied as a website URL.
- Sharing copies `https://vietnamlinuxfamily.net/a/{slug}` to the local
  clipboard. A missing server slug shows an unavailable message rather than
  inventing a route. No server write or authenticated request is involved.

## Phase 2 fixture inventory

All fixture values are synthetic. Confidence applies to field names only; no
fixture demonstrates a live value or authenticated behavior.

- `test/fixtures/feed.json` and the matching inline `fixtureTransport` feed model `GET /api/v1/feed` (per-field audit: field names read from real unauthenticated response vs inferred; all values synthetic):
  - Query parameters [CONFIRMED from web client chunk `2k5v3l48k2d3c.js`]:
    - `type=latest`: Mới nhất (default feed)
    - `type=top`: Được chú ý (featured/top posts; server returns 422 if `trending` is used)
    - `type=articles`: Article (plural; server returns 422 if singular `article` is used)
    - `type=following`: Đang theo dõi (requires session; returns 401 `AUTH_REQUIRED` unauthenticated)
    - `limit`: page size (e.g., 20)
    - `cursor`: pagination cursor from `nextCursor`
  - `items`: [CONFIRMED] read from real unauthenticated response.
  - `nextCursor`: [CONFIRMED] read from real unauthenticated response.
  - `items[].id`: [CONFIRMED] read from real unauthenticated response.
  - `items[].excerpt`: [CONFIRMED] read from real unauthenticated response.
  - `items[].voteScore`: [CONFIRMED] read from real unauthenticated response.
  - `items[].commentCount`: [CONFIRMED] read from real unauthenticated response.
  - `items[].author`: [CONFIRMED] read from real unauthenticated response.
  - `items[].author.username`: [CONFIRMED] read from real unauthenticated response.
  - `items[].author.displayName`: [CONFIRMED] read from real unauthenticated response.
  (All 9 field names in `feed.json` were read from real unauthenticated response; 0 are inferred. All values are synthetic).
- The projects fixture models `GET /api/v1/projects`:
  `items`, `nextCursor`, and `facets` (`languages`, `types`) are [CONFIRMED] field names.
  Project item fields are [CONFIRMED]: `id`, `name`, `slug`, `tagline`, `type`, `tier`, `relation`,
  `seeking`, `featured`, `status`, `logoUrl`, `accentColor`, `owner`, `repo` (`provider`, `owner`, `name`,
  `url`, `stars`, `forks`, `language`, `languageColor`, `archived`, `fork`, `pushedAt`, `unavailable`),
  `rating` (`average`, `count`), `commentCount`, `approvedAt`.
- The leaderboard fixture models `GET /api/v1/leaderboards`:
  `period`, `periodStart`, `periodEnd`, `computedAt`, and `items` are [CONFIRMED] field names.
  Leaderboard item fields are [CONFIRMED]: `userId`, `username`, `displayName`, `avatarUrl`,
  `earnedPoints`, `rank`, `style` (frame, distroBadge, icon, nameplate, status).
- Channels: `GET /api/v1/channels` returns `HTTP 401 Unauthorized` when unauthenticated.
  Channel listing requires authentication; response fields remain [UNKNOWN] until authenticated HAR capture.

---

## 1. Client Protocol & Anti-Corruption Layer

### Base URL
- Production API: `https://vietnamlinuxfamily.net`
- Realtime WebSocket: `wss://vietnamlinuxfamily.net/ws/community`
- Voice SFU Server: `https://voice.vietnamlinuxfamily.net` / `wss://voice.vietnamlinuxfamily.net`
- Media CDN: `https://media.vietnamlinuxfamily.net`

### Request Headers
Headers the native `ApiClient` sends (updated 2026-11-08; the earlier
`VNLF-Mobile` user agent and per-installation id were never implemented):
```http
x-vnlf-client: <uuid-v4, one per app process>
Content-Type: application/json   (requests with a body)
Accept: application/json
User-Agent: vlf-flutter-dev/0.1 (unofficial community client)
```
- `x-vnlf-client`: the website generates one per tab (`apps/web/lib/api.ts`); the
  native client generates one per process. See "Article slugs, error retry hints
  and client id" above.
- Session Management: Cookie-based session (`credentials: "include"`). Exact CSRF, cookie names, and set-cookie headers under authenticated states are **[UNKNOWN / INFERRED]** pending the coordinator receiving the user's Phase 3 HAR/cURL export.

### Standard Error Response Shape [CONFIRMED - observed unauthenticated (public)]
Observed live response from unauthenticated endpoints:
- Top-level field names: `code`, `message`, `requestId`.
All errors must be mapped into a typed Dart sealed class `ApiFailure` with status code, typed error code, localized message, and trace `requestId`.

### CORS & Web Platform Restriction [CONFIRMED - observed unauthenticated (public)]
- The production server returns `HTTP 500` on `OPTIONS` preflight requests and does NOT emit `Access-Control-Allow-Origin` headers.
- **Impact**: Flutter Web running in a browser from `localhost` or a separate domain will be blocked by browser CORS policy.
- **Native Targets**: Linux, Android, iOS, Windows, macOS do not enforce browser CORS and communicate directly without issue.
- **Web Workaround**: Flutter Web is dev-only through a local proxy and is not shipped.

---

## 2. Authentication & Session

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/auth/session` | [CONFIRMED] | No | Current session status. Unauthenticated: `HTTP 401 AUTH_REQUIRED`. Authenticated: returns `{user: {id, username, displayName, email, avatarUrl, role, style}}`. |
| `POST` | `/api/v1/auth/login` | [CONFIRMED] | No | Verified payload: `{"login": "<email|username>", "password": "<pwd>"}`. Success returns session JSON and emits `set-cookie: vnlf_session=...`. Invalid credentials returns `HTTP 401 INVALID_CREDENTIALS`. |
| `POST` | `/api/v1/auth/register` | [CONFIRMED] | No | Verified payload: `{"email": "<email>", "username": "<user>", "password": "<pwd>"}`. Success returns session JSON and emits `set-cookie`. Duplicate returns `HTTP 409`. |
| `POST` | `/api/v1/auth/refresh` | [INFERRED] | Cookie | Cookie/token rotation behavior. |
| `POST` | `/api/v1/auth/logout` | [CONFIRMED] | Cookie | Clears server-side session and cookie. |
| `GET` | `/api/v1/discover` | [CONFIRMED] | No | Returns `{articles: [...], users: [...], tags: [...], projects: [...], hasMore: bool}`. Powers the Discover screen with live community content. |
| `GET` | `/api/v1/users/{username}` | [CONFIRMED] | No | User profile entity: `{id, role, status, username, displayName, bio, website, totalPoints, level, currentStreak, followerCount, followingCount, avatarUrl, style, ...}`. |

> [!NOTE]
> `/api/v1/auth/session` field audit: The unauthenticated response observed contained solely the keys `code`, `message`, and `requestId`. It contained NO email, NO user id, and NO token. Zero real credentials or user session tokens were received, printed to terminal, written to file, or recorded in logs. Everything regarding the authenticated session state is treated as **[UNKNOWN]** for Phases 1 and 2.

---

## 3. Feed, Articles & Posts

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/feed` | [CONFIRMED - observed unauthenticated (public)] | Optional | Live response observed unauthenticated: `items`, `nextCursor`. Query: `type=latest\|trending\|article\|following`, `limit=20`. |
| `GET` | `/api/v1/articles/{id}` | [INFERRED] | Optional | Fetch full post detail with body, poll, and asset attachments. |
| `POST` | `/api/v1/articles` | [INFERRED] | Yes | Write endpoint: `{"title": "...", "contentJson": {...}, "contentText": "..."}` |
| `POST` | `/api/v1/articles/{id}/publish` | [INFERRED] | Yes | Write endpoint: publish drafted post. |
| `PUT` | `/api/v1/articles/{id}/vote` | [INFERRED] | Yes | Write endpoint: `{"value": 1 \| 0 \| -1}`. |
| `POST` | `/api/v1/articles/{id}/like` | [INFERRED] | Yes | Write endpoint: toggle like. |
| `POST` | `/api/v1/articles/{id}/bookmark` | [CONFIRMED - website source] | Yes | Adds a bookmark; it never removes one. See 2026-11-09 below. |
| `DELETE` | `/api/v1/articles/{id}/bookmark` | [CONFIRMED - website source] | Yes | Removes the viewer's bookmark. |
| `DELETE`| `/api/v1/articles/{id}` | [CONFIRMED - website source] | Yes | Deletes the author's own article (status `REMOVED`). |
| `POST` | `/api/v1/articles/{id}/hide` | [CONFIRMED - website source] | Yes | Hides a published article from the viewer's feed. |
| `GET` | `/api/v1/articles/{id}/comments`| [INFERRED] | Optional | Fetch comment hierarchy for article. |
| `POST` | `/api/v1/articles/{id}/comments`| [INFERRED] | Yes | Write endpoint: create comment. |

### Post Entity Schema [CONFIRMED shape from unauthenticated feed, INVENTED Vietnamese sample]
```json
{
  "id": "00000000-0000-7000-8000-000000000001",
  "authorId": "00000000-0000-7000-8000-000000000002",
  "format": "POST",
  "slug": "trai-nghiem-cai-dat-arch-linux-lan-dau",
  "title": null,
  "excerpt": "Hôm nay mình vừa cài thử Arch Linux trên máy ảo...",
  "contentJson": {
    "type": "doc",
    "content": [
      {
        "type": "paragraph",
        "content": [
          { "type": "text", "text": "Hôm nay mình vừa cài thử Arch Linux trên máy ảo..." }
        ]
      }
    ]
  },
  "contentText": "Hôm nay mình vừa cài thử Arch Linux trên máy ảo...",
  "contentHtml": "<p>Hôm nay mình vừa cài thử Arch Linux trên máy ảo...</p>",
  "coverAssetId": null,
  "coverUrl": null,
  "assets": [],
  "tags": [],
  "status": "PUBLISHED",
  "voteScore": 5,
  "viewerVote": 0,
  "commentCount": 2,
  "bookmarkCount": 1,
  "publishedAt": "2026-11-04T08:00:00.000Z",
  "author": {
    "id": "00000000-0000-7000-8000-000000000002",
    "username": "nguyenvanan",
    "displayName": "Nguyễn Văn An",
    "avatarUrl": "https://media.vietnamlinuxfamily.net/mock/avatar.webp",
    "role": "MEMBER",
    "style": {
      "nameColor": null,
      "nameGradient": {
        "from": { "light": "#0f766e", "dark": "#5eead4" },
        "to": { "light": "#0369a1", "dark": "#7dd3fc" },
        "angle": 90
      },
      "icon": {
        "url": "https://media.vietnamlinuxfamily.net/mock/icon.webp",
        "name": "Penguin",
        "pixelArt": true
      },
      "frame": { "id": "matrix", "color": null, "color2": null },
      "nameEffect": "rainbow",
      "nameplate": { "id": "waves", "color": null },
      "distroBadge": "arch"
    }
  }
}
```

---

## 4. Comments & Moderation

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `PUT` | `/api/v1/comments/{id}/vote` | [INFERRED] | Yes | Write endpoint: `{"value": 1 \| 0 \| -1}` |
| `POST` | `/api/v1/comments/{id}/like` | [INFERRED] | Yes | Write endpoint: toggle comment like. |
| `PATCH`| `/api/v1/comments/{id}` | [INFERRED] | Yes | Write endpoint: edit comment content. |
| `DELETE`| `/api/v1/comments/{id}` | [INFERRED] | Yes | Write endpoint: remove comment. |

---

## 5. Leaderboards & Gamification

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/leaderboards` | [CONFIRMED - observed unauthenticated (public)] | Optional | Observed live response: `period`, `periodStart`, `periodEnd`, `computedAt`, `items`. |
| `GET` | `/api/v1/point-rules` | [CONFIRMED - observed unauthenticated (public)] | Optional | Observed live response: `items` array with karma activity rules. |
| `GET` | `/api/v1/me/points` | [INFERRED] | Yes | Current user point balance. Authenticated state **[UNKNOWN]**. |
| `GET` | `/api/v1/me/point-stats`| [INFERRED] | Yes | Authenticated points history **[UNKNOWN]**. |
| `POST` | `/api/v1/me/check-in` | [INFERRED] | Yes | Write endpoint: daily check-in claim. |

---

## 6. Community Channels, Chat & DMs

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/channels` | [CONFIRMED - requires auth (HTTP 401 unauthenticated)] | Yes | Public unauthenticated request returns 401 Unauthorized. |
| `GET` | `/api/v1/channels/{id}/messages` | [INFERRED] | Optional | Channel message history. |
| `POST` | `/api/v1/channels/{id}/messages` | [INFERRED] | Yes | Write endpoint: send chat message. |
| `GET` | `/api/v1/channels/{id}/mention-candidates` | [INFERRED] | Yes | Mention autocompletion. |
| `POST` | `/api/v1/messages/{id}/reactions` | [INFERRED] | Yes | Write endpoint: add emoji reaction. |
| `GET` | `/api/v1/dm/conversations` | [INFERRED] | Yes | Authenticated DM list **[UNKNOWN]**. |
| `GET` | `/api/v1/dm/conversations/{id}/messages` | [INFERRED] | Yes | Authenticated DM messages **[UNKNOWN]**. |
| `POST` | `/api/v1/dm/conversations/{id}/messages` | [INFERRED] | Yes | Write endpoint: send DM. |
| `POST` | `/api/v1/dm/conversations/{id}/read` | [INFERRED] | Yes | Write endpoint: mark DM read. |

---

## 7. Projects & Showcases

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/projects` | [CONFIRMED - observed unauthenticated (public)] | Optional | Observed live response: `items`, `nextCursor`, `facets`. |
| `POST` | `/api/v1/project-images/presign` | [INFERRED] | Yes | Write endpoint: presign upload URL. |
| `POST` | `/api/v1/project-images/{assetId}/complete` | [INFERRED] | Yes | Write endpoint: confirm upload. |
| `GET` | `/api/v1/users/{username}/projects` | [INFERRED] | Optional | Projects authored by user. |

---

## 8. Notifications & User Profile

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/notifications` | [INFERRED] | Yes | Authenticated notifications list **[UNKNOWN]**. |
| `POST` | `/api/v1/notifications/read` | [INFERRED] | Yes | Write endpoint: mark notification read. |
| `POST` | `/api/v1/notifications/seen` | [INFERRED] | Yes | Write endpoint: mark notification seen. |
| `GET` | `/api/v1/me/profile` | [INFERRED] | Yes | Authenticated current user profile **[UNKNOWN]**. |
| `PATCH`| `/api/v1/me/profile` | [INFERRED] | Yes | Write endpoint: update profile **[UNKNOWN]**. |

---

## 9. Realtime WebSocket Architecture

### Connection Endpoint [INFERRED]
```
wss://vietnamlinuxfamily.net/ws/community
```
Connection uses HTTP upgrade with existing session cookies.
- [CONFIRMED] Handshake Origin validation: The server (Caddy / Cloudflare) returns `HTTP 403 Forbidden` if the `Origin` header is absent during WebSocket handshake upgrade. Native clients must pass `Origin: https://vietnamlinuxfamily.net` (matching the origin of `baseUri`).
- [CONFIRMED] Unauthenticated closure: The server immediately closes unauthenticated WebSocket connections with close code `4401` ("Authentication required").
- [CONFIRMED from production chunk `03vhpiw_fgmse.js`]: Realtime provider module `8808` (`RealtimeProvider`) performs an initial `presence:heartbeat` frame upon open, and triggers invalidation / refetching for `dm-conversations`, `dm-messages`, `channels`, and `voice-rooms`.
- [CONFIRMED from source `ab23799`] Event payloads used for system notifications:
  - The gateway (`apps/api/src/modules/realtime.ts`) wraps every relayed pub/sub message with a fresh `eventId` and `occurredAt`.
  - `notification:created` and `notification:updated` carry only `{ id }` (`apps/worker/src/index.ts`). `updated` means another actor was folded into an existing notification, which becomes unread again. The website only refetches its notification queries on both events. The native client refreshes its unread count, and while in the background it reads the newest `GET /api/v1/notifications` page to describe the notice.
  - `dm:message-created` and channel `message:created` carry the chat message DTO: `id`, `conversationId` or `channelId`, `authorId`, `author { id, username, displayName, avatarUrl }`, `content`. The channel slug is not included. A direct message is published to `conversation:<id>` and to every member's `notification:<userId>`, so the same message can arrive twice; the client keys its system notification by message id.

> [!NOTE]
> **Observation Audit**: The page's live `/ws/community` WebSocket connection was **NOT observed**, and its live frames were **NOT captured**. All endpoint strings, event names, and protocol patterns below were inferred solely by string-matching static JavaScript bundle `2bvq-3i0lg1dx.js`. All sample frames shown below are purely synthetic/invented.

### Heartbeat Loop [INFERRED]
- Client sends periodic heartbeat frame:
```json
{
  "type": "presence:heartbeat",
  "data": {}
}
```

### WebSocket Event Catalog [INFERRED from bundle string literals]
| Event Category | Inferred Event Names |
| :--- | :--- |
| **Channels** | `channel:join`, `channel:leave`, `channel:permission-changed` |
| **Messages** | `message:created`, `message:updated`, `message:deleted`, `message:typing`, `typing:changed`, `reaction:changed` |
| **Direct Messages** | `conversation:join`, `conversation:leave`, `conversation:access-revoked`, `dm:send`, `dm:message-created`, `dm:message-updated`, `dm:message-deleted`, `dm:peer-read`, `dm:read`, `dm:read-updated`, `dm:request-created`, `dm:request-updated`, `dm:typing`, `dm:typing-changed` |
| **Voice Rooms** | `voice:access-revoked`, `voice:chat-join`, `voice:chat-leave`, `voice:message-created`, `voice:message-updated`, `voice:message-deleted`, `voice:participant-count-changed`, `voice:reaction-changed`, `voice:room-updated` |
| **Presence & User** | `presence:changed`, `presence:heartbeat`, `user:style-changed`, `session:revoked`, `moderation:session-revoked`, `read:synced` |
| **Notifications** | `notification:created`, `notification:updated` |

---

## 10. Voice Infrastructure [INFERRED]
- Control API: `GET /api/v1/voice/rooms`, `POST /api/v1/voice/rooms/{id}/join-token`.
- RTC Engine: LiveKit SFU running at `wss://voice.vietnamlinuxfamily.net`.
- Dart integration: `livekit_client` official Flutter SDK for room connection and microphone streams.

## 11. Public profile fidelity audit (2026-11-05)

Evidence: anonymous public profile HTML at `/u/{username}`, its static client
chunk `2_3bhcnky9v-5.js`, and CSS chunks `24q1nvecqxecf.css`,
`1ni-9zdh0kfr0.css`, `0bu6vbbz82oz_.css`. A single anonymous GET of each
confirmed public read below checked response keys/types; no response body or
user content was saved in this repository. No authenticated requests or writes
were made. The web client's profile visit POST is deliberately not reproduced.

- `GET /api/v1/users/{username}`: confirmed `totalPoints`, `level`,
  `currentStreak`, `followerCount`, `followingCount`, `bio`, `style`, and `decor`.
  The web header shows total XP + level, streak, following and followers;
  loaded post/project counts and weekly leaderboard points are not these stats.
  Cover images use `decor.cover.imageUrl`; guestbook visibility uses
  `decor.guestbookEnabled` (static client evidence).
- `GET /api/v1/users/{username}/articles?limit=50`: confirmed public profile
  posts, `{items, nextCursor}`, using the existing article projection.
- `GET /api/v1/users/{username}/comments?limit=50`: confirmed `{items,
  nextCursor}` and comment keys `id`, `articleId`, `articleSlug`, `content`,
  `createdAt`, plus the existing public author/interaction fields. Native profile
  rows render text/date and open the article. Rich comment attachments are not
  implemented. Profile post/comment pagination beyond the client's first 50
  remains unverified; the app explicitly indicates a truncated result.
- `GET /api/v1/users/{username}/projects`: confirmed `{items}`; the public
  client uses this instead of filtering the general project directory.
- `GET /api/v1/profiles/{username}/guestbook`: confirmed `enabled`, `items`,
  `total`, `nextCursor`, `blockedReason`. Static client evidence confirms
  `?cursor={cursor}` pagination and entry `id`, `author`, `content`, `createdAt`,
  `status`. The inspected anonymous response had no entries, so entry fields are
  static-client confirmed, not observed populated live. Native reads display
  `VISIBLE` entries only and expose no guestbook write controls.
- Public tabs are posts, comments, projects and (when enabled) guestbook. The
  wardrobe is not a public profile content tab. Owner-only saved posts, profile
  editing/follow/block actions and custom music/machine-card/wallpaper effects
  are outside this read-only implementation.
- Static CSS confirms nameplate capsule radius `999px`, text-clipped gradients
  with light/dark colors, and 16×16 inline flair (`object-fit: contain`), with
  `pixelArt` controlling nearest-neighbor rendering rather than adding a second
  badge. H1/H2 web flair scales to 20px; native retains the requested 16px inline
  size. Exact distro artwork, frame/nameplate textures, animated name effects,
  non-90-degree gradients, profile visit counter and full decor fidelity remain
  unverified/unimplemented. Existing tinted nameplate alpha is retained pending
  confirmation of the client's computed plate-color variables.


## Article/comment verification (2026-11-05)

- Owner explicitly authorized their named test account and requires deleting all
  temporary posts/comments/reactions after verification. No credentials or
  authenticated response values are retained here.
- Current web chunks `03vhpiw_fgmse.js`, `0i3jl-zoc5vug.js`, and
  `2k5v3l48k2d3c.js` confirm article detail, draft creation (POST without body),
  versioned PATCH, publish POST with idempotency-key, DELETE, comment creation,
  comment PATCH/DELETE, article/comment vote PUT, and bookmark POST.
- Root comment payload MUST omit parentId. Live isolated test: null parent
  returns 422 INPUT_INVALID; omitted parent returns 200 and a complete comment
  record. A fresh comments GET confirms persistence. Reply parentId is a string.
- Comment response is a flat `{items}` list with parentId, content, author,
  createdAt, voteScore/viewerVote, canEdit/canDelete, attachments, gif, mentions,
  and pin/edit metadata. Parent links define the native tree.
- Detail uses the same article projection as feed, including structured
  contentJson, attachments, assets, viewer interactions, and timestamps.
- TipTap document nodes observed/supported by current web renderer: paragraph,
  heading (h2/h3), blockquote, bulletList, orderedList, listItem, codeBlock,
  horizontalRule, image, text, hardBreak. Marks: bold, italic, strike, code, link.
  Article image nodes resolve attrs.assetId against assets[].id/url; POST rich
  text filters inline images and renders attachments in a separate gallery.
- Media attachments have id, mime, size, width, height, url, alt; videos can add
  posterUrl and durationMs. Do not treat video URLs as image URLs.
- Current menu uses social image paths /social/facebook.webp,
  /social/telegram.webp, /social/discord.webp; Discord invite unchanged.

- Native JSON request bodies must be UTF-8 bytes with the byte content length.
  `HttpClientRequest.write` with the default encoding throws on Vietnamese before
  any HTTP request is sent. Root and reply writes verified with the corrected
  actual native transport and typed repository, followed by a fresh GET.
- Vote PUT response: voteScore, viewerVote, likeCount, viewerLiked. Bookmark POST
  returns `{ok: true}`; refreshed article projection supplies viewerBookmarked.
  Successful writes invalidate cached GET responses; mutation requests never retry.

## Authoritative source access (2026-11-05)

The owner granted read-only GitLab access through `glab` to
`realfox99/vnlf-social`, project 86991275. Source review is pinned to commit
`ab23799bf66ecec2176b89fa0c7e1151bf5782d3`. Relevant files are fetched selectively
outside this repository; no upstream source is copied into the native client.
Source HEAD and the deployed web bundle may differ: observed live behavior takes
precedence when documenting a production-server discrepancy. Contract changes
must be verified against both where practical.

Native draft foundation now follows the observed versioned article lifecycle:
create with POST `/api/v1/articles` (no body), PATCH `/api/v1/articles/:id`
with version/format/title/excerpt/tags/cover/contentJson/attachments, then POST
`/publish` with an idempotency-key header. The API client accepts per-request
headers without changing write retry policy. Native Markdown input is converted
to structured document nodes, never inserted as raw HTML. Draft and upload UI
wiring remains incomplete and must not be represented as a finished editor.


## Source review corrections — 2026-11-05

Pinned source: `ab23799bf66ecec2176b89fa0c7e1151bf5782d3`.
`apps/api/src/modules/articles.ts` permits only root-parent comment replies.
The native UI now flattens reply-to-reply to that root and prefills the recipient
mention. `clientCommentId` is 1–100 characters in the pinned contract and is
preserved for a manual retry of an unchanged draft. Native writes are never
automatically retried. Root `parentId` remains omitted because deployed testing
rejected explicit null, although the pinned source schema permits null.

`packages/contracts/src/feedback.ts` requires a UUID `clientSubmissionId`, detail
20–4000 characters, and pagePath. Kind is optional (FEEDBACK default); the native
form sends its selected kind and retains the draft/error on failure. The feedback
write is considered successful only after a successful server response.

Recovered channels use confirmed REST directory/history/send/edit/delete and
reaction POST/DELETE. Pinned `chat-message.ts` returns attachment `url: null`
with an authenticated `downloadPath`; the native adapter now requests this scoped JSON envelope and reads its signed
`downloadUrl`. It never forwards the session cookie to the media host. Private
media rendering and device playback still require runtime verification. Realtime contracts
use JSON envelopes over the community WebSocket, not an assumed Socket.IO stack.

Recovered voice uses LiveKit only after a confirmed join grant, starts muted,
and releases audio on leave/account change. Tests use injected room/audio
boundaries; no production audio call or real-device microphone check has yet
been performed. Weekly rankings use the observed Vietnam-time Monday anchor;
do not invent an all-time endpoint from old fixture labels.

## Native composer validation (2026-11-05)

Opening a new composition is read-only. The first save/upload/publish creates its
server draft. Edits debounce saves by two seconds; failed writes are never
retried automatically. Acknowledged versions advance without discarding newer
local edits. Version conflicts retain local and fresh server copies for an
explicit choice. HTTP failures retain a bounded server error code.

Recovery stores draft content and a pending publish UUID in platform secure
storage, partitioned by owner and composition slot. Credentials and presigned
upload URLs are excluded. The publish identity is stored before sending; lost
acknowledgment blocks further editing and manual retry reuses the identity.
Account changes stop subsequent mutations; corrupt recovery is not overwritten.

Images are limited to 10 MiB and videos to 200 MiB. Video completion can return
PENDING without a URL; the UI shows processing and offers a fresh status check.
Publishing waits for ready media. POST permits attachments and one video;
ARTICLE permits inline/cover images and rejects video. Format conversion moves
resolvable image IDs into attachments and stops on unresolved images.

A separate TipTap/Delta codec is tested through the actual Parchment model for
known marks, lists, headings, code, hard breaks and image attributes. Unsupported
blocks/marks and complex list structures remain preserved embeds. Poll editing,
advanced editor shortcuts/paste, new composer live-account writes/cleanup and
real-device file/media checks remain incomplete or unverified.

## Comment mutation and media contract — 2026-11-05

Pinned source `apps/api/src/modules/articles.ts:93` returns `pinned` (not
`isPinned`), canPin, editedAt, attachments and gif. Native DTOs now retain these.
Hidden VNLF stickers render a placeholder without fetching their image. Other
GIF/sticker media and photo attachments render through native media widgets.
Sticker pack browsing, media upload and mention suggestions remain separate gates.

- `PUT /api/v1/comments/:id/vote`: `{value:-1|0|1}`, acknowledgment must contain
  integer voteScore and valid viewerVote. Native callbacks were previously absent.
- `PATCH /api/v1/comments/:id`: `{content}`, maximum 4000 UTF-16 code units;
  server returns a full comment. Existing media remains, so empty text is valid
  when media is present. Emptying a text-only comment uses confirmed deletion,
  following the website's behavior.
- `DELETE /api/v1/comments/:id`: require `{ok:true}`. Replies remain; a deleted
  root's surviving replies are presented as roots rather than hidden.
- `PUT /api/v1/articles/:id/pinned-comment`: `{commentId:UUID|null}`; require a
  matching pinnedCommentId acknowledgment. Only canPin root comments expose it;
  only the acknowledged root leads the discussion, with its replies.

Requests serialize per comment, errors remain visible, failed edit text is kept,
account changes discard pending UI results, and delete requires confirmation.
New checks use synthetic transport data; these new actions have not yet been
verified with live owner-account writes. No test content was created this turn.

## Account request isolation — 2026-11-05

Reproduced two request-layer races with a synthetic transport and a loopback HTTP
server: clearing cached reads did not cancel an older queued write, and a write
waiting on secure-cookie restoration could still leave after logout. ApiClient
now tracks session generations, rejects stale queued requests before transport
and stale results after transport, and clears session-scoped cache on changes.
Login/register/logout and owner-state changes advance this generation. Native
transport snapshots cookies and checks cleanup revisions after restoration and
connection setup, so an older request cannot acquire the next account's cookie.
Already-sent server writes cannot be undone by local cancellation; their late
responses are ignored. Automatic write retry remains disabled.

Fresh comment reads started after a mutation replace its temporary acknowledged
UI state. A read begun before a later mutation cannot erase that newer result.
This prevents an acknowledgment overlay from permanently overriding later server
edits or vote totals. Replies whose parent was deleted become root comments with
the recipient mention, since the verified API accepts only active root targets.
The upstream comments list is capped at 100 oldest active rows without a cursor;
viewing later comments needs an upstream contract change, not invented pagination.

## Upload operation account boundaries — 2026-11-06

Synthetic transfer tests reproduced a second-stage account race in both public
article and private DM uploads: a raw PUT could finish after login/logout and
then start its completion request with the next account. ApiClient now provides
an operation-wide session scope. Uploads check it before raw transfer, on each
file chunk and before completion; disposing the app's client also invalidates
its scopes. Already-transmitted bytes cannot be recalled. No automatic retry is
introduced. Completion must identify the presigned asset, and article completion
must carry an explicit supported processing status instead of implicit success.

The account-change and malformed-completion regressions pass, along with the
relevant authentication/request and DM tests. These checks use synthetic data;
no live upload was submitted. The owner named a controlled DM recipient for a
later live check; only created test content may be cleaned up.

## Poll contracts verified from pinned source — 2026-11-06

Reference: project 86991275, commit
`ab23799bf66ecec2176b89fa0c7e1151bf5782d3`, contracts `polls.ts`, API modules
`polls.ts` and `articles.ts`, API library `polls.ts`, and web poll card.

- Poll DTO: id, question, options(id/label/votes), totalVotes, nullable
  viewerOptionId. Article and chat DTOs contain an optional nullable poll.
- POST `/api/v1/polls/:id/vote`: `{optionId: UUID|null}`; full Poll DTO acknowledgment.
  Voting for a different option changes the choice; null removes it.
- PUT `/api/v1/polls/:id`: `{question, options: string[]}`; full Poll DTO.
  Author only, before any votes; `POLL_HAS_VOTES` rejects an edit after voting.
  Editing replaces option identities. This route also works on published posts.
- PUT `/api/v1/articles/:id/poll`: `{poll: PollInput|null}`; acknowledgment
  `{poll: PollDto|null}`. The owner may set/remove it only when publishedAt is
  absent. `POLL_LOCKED` rejects an article that has previously been published.
- Input limits: question 200 UTF-16 units, choices 100 each, two to six choices.
  Source cleanup collapses whitespace, trims, removes empty choices and
  de-duplicates case-sensitively. Native inputs validate before sending.
- Percentages are visible after this viewer votes; total votes remain visible.
  Peer realtime DTOs retain this viewer's selection rather than adopting the
  broadcaster's viewerOptionId.

Typed native repository/state checks use synthetic data only. Live poll mutation
behavior, composer integration and native visual parity are not yet verified.

## Profile relationships and feedback media — 2026-11-06

At source commit `ab23799bf66ecec2176b89fa0c7e1151bf5782d3`, profile
relationships use `POST`/`DELETE /api/v1/users/:id/follow` and
`POST`/`DELETE /api/v1/users/:id/block`, with an explicit `ok: true`
acknowledgment. A fresh profile read supplies `followedByViewer` and
`blockedByViewer`; missing values are unknown, not proof of a cleared state.
Server errors or interrupted writes are reconciled once and reported as
unconfirmed. Synthetic tests cover these paths; no live relationship write was
performed. Blocking also affects feeds and messaging, and an already-open DM
timeline may require a refresh.

The same source's feedback module allows up to five private media assets per
submission. Image MIME types are JPEG, PNG, WebP and GIF up to 10 MiB; MP4 and
WebM video may be up to 50 MiB. Presigning uses
`POST /api/v1/feedback/assets/presign`, a raw upload to the returned URL, and
`POST /api/v1/feedback/assets/:assetId/complete`; an unsubmitted asset can be
removed with `DELETE /api/v1/feedback/assets/:assetId`. Both the submission UUID
and feedback kind bind the asset to the submission. The authenticated native
dialog now selects, uploads, removes and submits attachments, and stores
owner-scoped draft metadata and uncertain outcomes without signed URLs. The
end-to-end flow has synthetic coverage only; no live upload was performed.
Guest attachment uploads and visual previews remain unimplemented. A process
termination inside the short edit debounce can lose the most recent text.

The guestbook source uses `GET` and `POST /api/v1/profiles/:username/guestbook`,
`PATCH` and `DELETE /api/v1/guestbook/:id`; write eligibility and visible/hidden
entries come from the server. Native write, hide, show, delete, block and report
controls have synthetic account and failure coverage; live writes remain
unverified. A guestbook notification opens the native profile's guestbook tab.

The personal activity screen reads `GET /api/v1/me/activity-calendar` with
inclusive `from` and `to` dates; the pinned source returns each date in the
requested range, Vietnam-local `today`, point totals, and streak information.
The screen and owner/session guards have synthetic coverage, including date
rollover. A read-only owner-account calendar request passed against the deployed
server and the test session was logged out. The native client now calls the
source-confirmed check-in endpoint automatically for a confirmed live session;
it coordinates with manual requests, app visibility, dialogs and the composer,
uses Vietnam-local days, and does not automatically repeat an uncertain write.
An unconfirmed result is reported with a link to activity. The automatic flow
has synthetic coverage only; device visual verification and live behavior remain
outstanding.
The pinned auth source also calls `recordAttendance` while creating a login or
session response. Consequently, the authorized test logins and session reads may
have recorded attendance even though no explicit check-in request was made. No
confirmed endpoint for removing that attendance is known.

The pinned website reads `GET /api/v1/me/preferences`, which may return JSON
`null`, and saves partial changes with `PATCH` to the same path. Native privacy,
notification and reduced-motion settings use the website's defaults, invert
`leaderboardOptOut` for display, and require an `ok: true` acknowledgment.
Only changed fields are sent. An uncertain save requires a fresh read before
another attempt. The reduced-motion setting combines with the device's own
accessibility setting. These flows have synthetic coverage only; no live
preference changes were made. Other website display and decoration preferences
are not yet implemented. The message-sound preference syncs to the website;
native message sound playback is not implemented.

The website also keeps its text-size choice on the device, independently of
the account: an integer from 12 through 18, default 13. The native setting is
stored locally and composes its scale with the operating system's text scaler;
its proportional mapping approximates the website's fixed heading offsets.
Synthetic tests cover storage races and keyboard use; visual device comparison
remains outstanding. Restoring a saved size is asynchronous and may change
text after the first frame.

## Comment photos, mentions and session management — 2026-11-07

At the pinned source revision, comment photos use
`POST /api/v1/articles/:id/comment-assets/presign`, a raw signed upload, and
`POST /api/v1/articles/:id/comment-assets/:assetId/complete`. Up to ten JPEG,
PNG, WebP or GIF images of at most 10 MiB each may be included as
`attachmentIds` when creating a comment. The native composer has synthetic
upload, account-change, retry and recovery coverage. The server stores these
uploads publicly when selected; its audited comment-media module has no
delete route. No live comment-photo upload was performed. Thumbnail previews,
GIF/sticker selection and device verification remain open.

Authenticated mention suggestions use
`GET /api/v1/articles/:id/mention-candidates?q=...`. The source accepts a query
of at most 30 characters and returns up to eight candidates. Native input uses
debouncing, account-bound cancellation, keyboard selection and input-method
composition guards; this has synthetic coverage only.

The account session list uses `GET /api/v1/auth/sessions`; non-current
sessions may be revoked with `DELETE /api/v1/auth/sessions/:id`, and other
sessions collectively with `POST /api/v1/auth/logout-others`. A read-only
owner-account list check succeeded and the temporary test session was logged
out. Revocation paths have synthetic coverage and were not exercised live.

The account's blocked-people list uses `GET /api/v1/me/blocks`; unblocking uses
`DELETE /api/v1/users/:id/block` and requires an explicit `ok: true` response.
The native panel refreshes related profile, feed and inbox state after a possible
change. An owner-account list read succeeded and its temporary session was
logged out; unblock behavior has synthetic coverage and was not exercised live.

## Post menu, share dialog and link previews — 2026-11-09

Confirmed from the website source checked out beside this repository
(`apps/web/components/social-overlays.tsx`, `apps/web/lib/article-cache.ts`,
`apps/web/components/social/chat/link-preview.tsx`) and the routes in
`apps/api/src/modules/articles.ts` and `link-preview.ts`:

- `POST /api/v1/articles/:id/bookmark` only inserts a bookmark
  (`onConflictDoNothing`); `DELETE /api/v1/articles/:id/bookmark` removes it.
  Both return `{ok: true}`. Native builds before this note sent `POST` to
  unsave as well, so unsaving never reached the server.
- `DELETE /api/v1/articles/:id` is limited to the author and marks the article
  `REMOVED`, returning `{ok: true}`. The website asks for confirmation first,
  then refreshes feed, profile and bookmark lists and leaves the detail page.
- `POST /api/v1/articles/:id/hide` hides a published article for the signed-in
  viewer (`404 ARTICLE_NOT_FOUND` otherwise). The website offers it to everyone
  except the author.
- Sharing has no endpoint. Facebook
  (`https://www.facebook.com/sharer/sharer.php?u=`), Telegram
  (`https://t.me/share/url?url=`) and Email (`mailto:`) links are built on the
  client from `https://vietnamlinuxfamily.net/a/:slug`. The "Tin nhắn" option
  only opens `/messages`: the website passes `?share=` but nothing reads it.
- `GET /api/v1/link-preview?url=` returns
  `{preview: {url, title, description, siteName, imageUrl} | null}` for the
  first link of a post without photos or a poll; photos and YouTube thumbnails
  load through `GET /api/v1/link-preview/image?url=`.

None of these writes was exercised live: no test account was authorized for
this change. They have synthetic coverage through a fake transport and widget
tests, and failed writes are never retried.

## Comment mentions and sticker kinds — 2026-11-09

Comment payloads from `GET /api/v1/articles/:id/comments` carry
`mentions: [{token, username, displayName}]` for the @mentions the server
matched, and `gif.kind: "sticker"` for KLIPY stickers (VNLF stickers have
`provider: "VNLF"`). The website bolds and links only those server-known
mentions, draws stickers without a frame (at most 160px) and labels KLIPY media
with its provider. The native app reads both fields from 2026-11-09 and treats
missing values as none.

## Sticker and GIF picker — 2026-11-09

Confirmed from the website source (`apps/web/lib/klipy.ts`,
`apps/web/lib/stickers.ts`, `components/social/chat/gif-picker.tsx`) and the
API routes in `integrations.ts`, `stickers.ts` and `articles.ts`:

- `GET /api/v1/integrations/klipy` (signed in, `cache-control: private,
  no-store`) returns `{provider: "KLIPY", enabled, apiKey, customerId}`. The
  key is KLIPY's public app key; `customerId` is an HMAC pseudonym of the
  member, never an email or user id.
- The client then calls KLIPY directly, without cookies:
  `GET https://api.klipy.com/api/v1/{apiKey}/{gifs|stickers}/{trending|search}`
  with `page`, `per_page=24`, `customer_id`, `locale=vn`,
  `format_filter=gif,webp`, `content_filter=high` and `q` when searching.
  The native parser mirrors `parseKlipyPage`:
  - it refuses ads, malformed pages and media outside `static{,1,2}.klipy.com/ii/`;
  - it keeps ids of 16 or more digits exact;
  - it prefers `gif` for GIFs and `webp` for stickers among the `sm`, `md`, `hd`, `xs` renditions.
  
  After a comment with a KLIPY item is sent, it posts
  `POST https://api.klipy.com/api/v1/{apiKey}/{gifs|stickers}/share/{slug}`
  `{customer_id, q}` once. That call is analytics and never blocks the comment.
- `GET /api/v1/stickers/tray` → `{packs: StickerPackDto[]}` and
  `GET /api/v1/stickers/saved` → `{items: [{sticker, pack: {id, slug, title},
  savedAt}]}`. Only `READY` stickers with a URL are offered.
  `DELETE /api/v1/stickers/:id/save` removes a saved sticker.
- `POST /api/v1/articles/:id/comments` accepts `gif` beside `content` and
  `attachmentIds`:
  - KLIPY: `{provider: "KLIPY", id, slug, kind?: "sticker", title, url, width, height}`.
  - VNLF: `{provider: "VNLF", kind: "sticker", id, packId, packSlug, title, url, width, height}`.

  The server rebuilds VNLF stickers from the pack. The native client keeps the
  payload in the pending-comment record, so a retry sends the same item under the
  same `clientCommentId`.
- The last 16 stickers sent are kept on the device. The website keeps them per
  browser (`vnlf:recent-stickers`); the app keeps them per account.

No live call was made: the picker needs a signed-in account, and none was
authorized for testing. Parsing, requests and the picker have synthetic coverage.

