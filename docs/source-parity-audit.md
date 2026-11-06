# Source parity review — 2026-11-05

Reference: private GitLab `realfox99/vnlf-social`, project 86991275,
commit `ab23799bf66ecec2176b89fa0c7e1151bf5782d3`. Review performed with
Gemini 4 Argon, then independently checked by Codex. The deployed website can
differ from this source revision; live observations take precedence for deployed
behavior. No upstream source is incorporated into the native client.

## Independently verified contracts and defects

| Area | Evidence | Native result and remaining work |
| --- | --- | --- |
| Comment nesting | `apps/api/src/modules/articles.ts` rejects a parent that is itself a reply | Reply UI now targets the root and mentions the selected recipient; tested. |
| Comment duplicate protection | `packages/contracts/src/social.ts` permits clientCommentId of 1–100 characters; article module deduplicates by author and client id | One UUID is retained while manually retrying an unchanged draft; writes never retry automatically. |
| Root comments | Source allows nullable parentId, but deployed testing returned 422 for null and succeeded when omitted | Continue omitting parentId for roots; record this deployed/source difference. |
| Comment projection | Article module returns voteScore/viewerVote, permissions, pinned/canPin, editedAt, attachments and GIF | Vote/edit/delete/pin callbacks, strict acknowledgment checks, permissions, media and hidden-sticker rendering implemented with synthetic failure/session coverage; live writes, uploads and mentions remain. |
| Feedback | `packages/contracts/src/feedback.ts` requires UUID clientSubmissionId, detail 20–4000 characters, pagePath; kind is optional | UUID, validation, kinds, page path, retained failed drafts and acknowledgment-only success are implemented and tested. |
| Article assets | Article detail includes an asset catalog; native `_resolveContent` resolves image ids | Asset dimensions and existing src when assetId is empty are preserved; tested. Live computed 13px typography, collapsed block margins and the dedicated article layout are implemented and tested; images/captions and shared shell still need comparison. |
| Gallery | `apps/web/components/social/media-gallery.tsx` separates videos from images and carries processing/failed state | Videos now span the card above image thumbnails; processing/failure and duration survive parsing. Actual playback remains a device check. |
| Realtime | `packages/contracts/src/realtime.ts` specifies JSON type/requestId/data envelopes and acknowledgements | Implement the raw community WebSocket protocol; the earlier review's Socket.IO claim was unsupported and is withdrawn. |
| Updates | Native app previously only displayed a version string | Public stable update repository/controller/UI added and tested. Missing repository is visible. Actual public publishing remains blocked by organization permissions. |
| Builds | Earlier Linux hosted job failed on the rolling Ubuntu image; private publishing only ran on tags | Pinned runners/SDKs and binary architecture checks pass on all nine targets in run 42079702029 at the native-composer checkpoint. All nine binaries and checksums were automatically published privately and their uploaded digests verified. Default-branch recovery, public stable setup and signing remain gates. |

## Full feature inventory and release gates

The following inventory is a work tracker, **not a statement of feature parity**.
Existing fixture behavior does not prove production behavior. Every write needs
failure/duplicate/session-change coverage and validation against the deployed
server with the authorized account, followed by cleanup.

| Website surface | Native status / remaining gate |
| --- | --- |
| Auth/session | Login/logout/session storage implemented; device and expiry checks remain. |
| Feed and article detail | Live loading and structured native rendering. Guest Linux captures verify inline images and moving video frames after fixing decoder-fallback handling. More device/media states, link previews, polls and remaining visual differences still need work. |
| Comments | Persistence verified and test content cleaned; flattened replies and stable retry identity tested. Votes/edit/delete/pin and media display now implemented with failure, permission, acknowledgment and session tests; live checks, media uploads, mention suggestions and sticker packs remain. |
| Post actions | Vote/bookmark confirmed, rollback and session guards tested; reporting now uses a validated, server-confirmed dialog with retry/error coverage. |
| Publishing | Native rich composer, versioned autosave, owner-partitioned secure recovery, conflict handling, stable publish identity, images/cover/video processing and format conversion implemented and tested. Live UI write/cleanup checks, polls and advanced editor features remain. |
| Channels | REST implementation integrated with tests, including fresh signed media URLs and safe mutation handling; realtime/read sync, uploads/search/context remain incomplete. |
| Direct messages | Source-derived inbox/requests, lifecycle, history/search/context/media and message actions are integrated into the codebase, with strict acknowledgments and synthetic checks. Combined channel/DM navigation, explicit direct links and image picking are now connected and tested through actual screens. Realtime, persistent draft recovery and live controlled-peer verification remain pending. |
| Voice | LiveKit room/join/leave implementation integrated with session/lifecycle tests; real-device audio and room text chat remain. |
| Search/discover | Live search integrated with debounce/stale-response tests; verify website scope filtering and live discovery. |
| Rankings/check-in | Weekly archive integrated and tested; check-in and personal activity remain. Do not invent an all-time endpoint. |
| Profile/social graph | Public reads implemented; follow/block, guestbook writes and full account customization need implementation. |
| Notifications | Live list/read/seen, unread filtering, pagination and routing implemented; real-account and visual checks remain. |
| Feedback/support | Submission validation/acknowledgment defects fixed; history, attachments and ticket conversation remain incomplete. |
| Projects | Live listing; server filters/pagination, detail, media, ratings and submission lifecycle remain incomplete. |
| Settings | Local preferences and updater implemented; server account/profile/preferences/blocked-user management remain incomplete. |
| Accessibility/performance | Responsive fixture tests pass; fresh Linux screenshots, media playback, startup/frame/memory measurements and device checks remain. |
| Distribution | All nine architectures compile and their release asset digests match. Real-device checks, signing/notarization and public updater distribution remain stable-release gates. |

## Source and asset handling

The private upstream package declares no license field, and no root license was
found during review. Read access alone does not establish redistribution rights.
Keep the source snapshot outside this repository. Flag official logos, social
icons and other artwork for owner/license confirmation; do not assume their
terms. Preserve bundled font licenses and check the actual native media-library
licenses and notices before distribution. This is a release review item, not a
legal determination.

## Resource policy

The source-review Argon worker was released. The DM implementation was delivered and independently hardened by Codex. The same Argon worker now reviews coordinator changes; it runs no builds, installs, test jobs, live calls or child agents.
Recovered worker worktrees remain intact. Codex integrates and verifies serially
through `tool/with_build_slot.sh`; do not restart parallel local build workers.
