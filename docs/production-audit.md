# Website parity and production audit — 2026-11-05

Scope: the user's request covers the whole native client, starting with comment
persistence, article media, Discord branding, and rich article rendering.
Worktree: `vnlf-production-audit`; baseline: `3c48ee3`, 202 tests pass.

## Confirmed defects

- Root comments send `parentId: null`. The live server rejects this with 422
  `INPUT_INVALID`; omitting `parentId` succeeds and survives a fresh GET.
  Submission catches and suppresses failure while displaying an invented local
  comment. Loading errors also appear as empty discussions.
- Article detail uses a hand-written partial decoder, discarding `contentJson`,
  attachments, timestamps, tags, viewer votes, and bookmarks. Errors silently
  fall back to feed excerpts, hiding missing detail.
- Post rendering flattens all structured content into plain paragraphs and
  chooses only the first image. Video attachments are treated as images.
- Discord is a generic gamepad icon. The web client uses `/social/discord.webp`.
- Vote/bookmark state ignores session changes, permits overlapping writes,
  suppresses failures, and does not invalidate the API GET cache after mutations.
- Chat/channel data, sends, voice rooms, join/mute/deafen/screen-share use local
  sample state even with live transport. These are not production implementations.
- Report action announces success without sending a report. Feed composer is
  not connected to an article creation flow.

## Feature matrix

| Website feature | Native state at audit start | Release acceptance |
| --- | --- | --- |
| Sign-in/register/session/logout | Live transport exists | Test session restore, logout, expiry; no secret logs |
| Feed tabs/pagination/refresh | Live reads; covered by tests | Refresh and pagination preserve server state |
| Article body and images | Partial fields/plain text/first media | Structured text and every attachment, zoom, video controls |
| Comments/replies/votes | Broken writes; flat list; inert votes | Server-confirmed records, typed failures, threaded replies |
| Article votes/bookmarks | Optimistic with silent rollback | Serialized writes, visible failures, authoritative server state |
| Compose/edit/publish/delete | Missing native composer | Verified draft/version/publish lifecycle and cleanup |
| Discover | Live reads | Open matching post/project/profile |
| Search | Searches loaded local content | Match web server search and result types |
| Profiles/public tabs | Live public reads, partial decor | Follow/block, guestbook, pagination, decor remain to verify |
| Projects | Directory/details | Submission, editing, comments/rating remain to verify |
| Leaderboard/check-in | Partial reads | Periods, own balance, check-in and history remain to verify |
| Channels/messages/reactions/mentions | Sample data | Verified live repository and realtime protocol |
| Direct messages/unread/receipts | Missing native DM flow | Own-account conversations and realtime verified |
| Voice | Simulated local state | Real room membership and LiveKit audio verified |
| Notifications/push | Missing | Native permissions, subscriptions, read state verified |
| Settings/privacy/customization | Appearance/session only | Account, privacy, block lists, wardrobe parity |
| Social menu | Working links; incorrect Discord icon | Match observed web branding |

Public client evidence: current website HTML and its static chunks, inspected
read-only. Authenticated verification uses only the owner-authorized test account.
All temporary posts/comments are isolated and must be deleted before finishing.
No private responses, credentials, cookies, tokens, or HAR files belong here.

## Implementation and verification plan

1. Add failing regression tests for server-confirmed comment writes, omitted
   root parent IDs, retained drafts on failure, cache refresh, reply hierarchy,
   and detail decoding/errors. Implement typed repositories and UI states.
2. Add rendering tests for the observed rich document nodes, resolved inline
   asset IDs, multiple images, mixed video/image attachments and unsafe links.
   Implement native structured content, media gallery/lightbox and video playback.
   Verify added packages on pub.dev before dependency changes.
3. Correct menu branding and interaction races/errors. Replace false-success
   actions and ensure live mode never presents fixture operations as real.
4. Audit remaining feature contracts; implement only observed endpoints. Record
   outstanding release blockers explicitly. Do not label fixture tests as live proof.
5. Run pub get, format, analyze, full test suite, native Linux build/run and
   screenshot comparisons; verify live own-post operations then delete test data.

## Progress

- Baseline: `flutter pub get`; `flutter test`: 202 passing.
- Live root-cause check: null parent 422; omitted parent 200; fresh GET contains
  exactly one confirmed comment. Native HTTP verification also confirms a root comment and reply persist. Cleanup remains mandatory before finishing.
- CodeRabbit installed (0.9.2); authentication requires the user's browser sign-in.

- Fixed native UTF-8 JSON writes, stale GET caches after mutations, empty 204
  acknowledgments, and dropped embedded query parameters. Each has a failing-then-
  passing regression test. A native HTTP live test confirmed persisted Vietnamese
  root/reply records using the real repository and transport.
- Structured text and all media now render; image zoom and video controls added.
  Media packages checked against their official pub.dev pages: media_kit 1.2.6,
  media_kit_video 2.0.1, media_kit_libs_video 1.0.7. Distribution must include the
  native codecs' applicable license notices. Discord uses the observed site asset;
  permission to redistribute the community logo/social artwork remains a release
  licensing check.
- Verification checkpoint: pub get succeeds; formatting applied; analyze reports
  no issues; full suite 216 passing. Debug Linux build and native run succeed.
  Desktop comparison artifacts are outside the repository under
  `/tmp/vnlf-audit/`. Video playback, Android, performance and remaining feature
  parity are not yet certified.
