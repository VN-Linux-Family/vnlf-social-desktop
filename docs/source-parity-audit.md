# Source parity review — 2026-11-05

Reference: private GitLab `realfox99/vnlf-social`, project 86991275,
commit `ab23799bf66ecec2176b89fa0c7e1151bf5782d3`. Review performed with
Gemini 4 Argon, then independently checked by Codex. The deployed website can
differ from this source revision; live observations take precedence for deployed
behavior. No upstream source is incorporated into the native client.

## Independently verified contracts and defects

| Area | Evidence | Native result and remaining work |
| --- | --- | --- |
| Comment nesting | `apps/api/src/modules/articles.ts` rejects a parent that is itself a reply | Reply UI must target the root and mention the selected recipient. |
| Comment duplicate protection | `packages/contracts/src/social.ts` permits clientCommentId of 1–100 characters; article module deduplicates by author and client id | Preserve one id while retrying an unchanged draft; writes must never retry automatically. |
| Root comments | Source allows nullable parentId, but deployed testing returned 422 for null and succeeded when omitted | Continue omitting parentId for roots; record this deployed/source difference. |
| Comment projection | Article module returns voteScore/viewerVote, permissions, pinned/canPin, editedAt, attachments and GIF | Score/vote are already parsed; callbacks, pin/edit/delete and attachments still need implementation. |
| Feedback | `packages/contracts/src/feedback.ts` requires UUID clientSubmissionId, detail 20–4000 characters, pagePath; kind is optional | Existing modal accepts too-short input, uses a timestamp id, catches errors and displays success. Must retain draft, validate and show server failure. |
| Article assets | Article detail includes an asset catalog; native `_resolveContent` resolves image ids | Preserve asset dimensions and existing src when assetId is empty; currently width/height are discarded. |
| Gallery | `apps/web/components/social/media-gallery.tsx` separates videos from images and carries processing/failed state | Native grid mixes videos and images and drops state/duration. Fix the projection and show meaningful non-playable states. |
| Realtime | `packages/contracts/src/realtime.ts` specifies JSON type/requestId/data envelopes and acknowledgements | Implement the raw community WebSocket protocol; the earlier review's Socket.IO claim was unsupported and is withdrawn. |
| Updates | Native app previously only displayed a version string | Public stable update repository/controller/UI added and tested. Missing repository is visible. Actual public publishing remains blocked by organization permissions. |
| Builds | Earlier Linux hosted job failed on the rolling Ubuntu image; private publishing only ran on tags | Pin runners, assert native ABI, inventory nine artifacts, store every build privately, and publish complete stable assets publicly. Actual hosted matrix remains unverified until run. |

## Full feature inventory and release gates

The following inventory is a work tracker, **not a statement of feature parity**.
Existing fixture behavior does not prove production behavior. Every write needs
failure/duplicate/session-change coverage and validation against the deployed
server with the authorized account, followed by cleanup.

| Website surface | Native status / remaining gate |
| --- | --- |
| Auth/session | Login/logout/session storage implemented; device and expiry checks remain. |
| Feed and article detail | Live loading and structured native rendering; media states, link previews, polls, and visual comparison remain. |
| Comments | Persistence verified and test content cleaned; nested replies and retry identity under repair. Votes, edit/delete/pin, media and mentions need complete coverage. |
| Post actions | Vote/bookmark confirmed, rollback and session guards tested; reporting now uses a validated, server-confirmed dialog with retry/error coverage. |
| Publishing | Typed draft/save/publish/upload foundation added; composer UI and full publish lifecycle remain incomplete. |
| Channels | Recovered REST implementation awaits integration and contract checks; realtime/read sync, uploads/search/context remain incomplete. |
| Direct messages | Inbox/requests and conversation lifecycle missing; channel navigation is not DM support. |
| Voice | Recovered LiveKit room/join/leave implementation awaits integration, real-device audio testing and room text chat. |
| Search/discover | Recovered live search awaits integration; verify scope filtering and live discovery. |
| Rankings/check-in | Recovered live weekly archive awaits integration; verify website navigation, check-in and personal activity. Do not invent an all-time endpoint. |
| Profile/social graph | Public reads implemented; follow/block, guestbook writes and full account customization need implementation. |
| Notifications | Live list/read/seen, unread filtering, pagination and routing implemented; real-account and visual checks remain. |
| Feedback/support | Submission defect under repair; history, attachments and ticket conversation remain incomplete. |
| Projects | Live listing; server filters/pagination, detail, media, ratings and submission lifecycle remain incomplete. |
| Settings | Local preferences and updater implemented; server account/profile/preferences/blocked-user management remain incomplete. |
| Accessibility/performance | Responsive fixture tests pass; fresh Linux screenshots, media playback, startup/frame/memory measurements and device checks remain. |
| Distribution | All architecture builds, signing, notarization, update download/install and artifact checks must pass before stable release. |

## Source and asset handling

The private upstream package declares no license field, and no root license was
found during review. Read access alone does not establish redistribution rights.
Keep the source snapshot outside this repository. Flag official logos, social
icons and other artwork for owner/license confirmation; do not assume their
terms. Preserve bundled font licenses and check the actual native media-library
licenses and notices before distribution. This is a release review item, not a
legal determination.

## Resource policy

Argon ran read-only review only: no builds, installs, test jobs or child agents.
Recovered worker worktrees remain intact. Codex integrates and verifies serially
through `tool/with_build_slot.sh`; do not restart parallel local build workers.
