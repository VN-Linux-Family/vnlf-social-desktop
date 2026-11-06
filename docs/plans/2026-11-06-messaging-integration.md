# Native communication integration

Owner: Codex, `luank3/vnlf-production-audit`. Continue in the isolated worktree.
This plan extends the existing authorized production audit; it is not a release
readiness claim. The DM foundation passes 382 Flutter tests and analysis. Later
upload account-boundary changes pass targeted authentication/upload checks; run
the complete suite again after integration.

## Verified reference

Pinned GitLab project 86991275 at
`ab23799bf66ecec2176b89fa0c7e1151bf5782d3`, read through glab. Relevant source:
`communication-list.tsx`, `views/direct-message-live-view.tsx`, API modules
`dm.ts`, `channels.ts`, `polls.ts`, `realtime.ts`, and their contracts. Read-only
snapshots remain outside Git. No upstream implementation is copied into the app.

The website explicitly combines channels and private conversations in one
searchable list. Channels collapse; requests offer accept/decline; conversations
show actual unread counts. There are no separate channel/DM tabs. Live CSS uses a
240px communication rail (205px at the intermediate breakpoint), zero main
padding, and a 54px compact chat header. Phone list/detail views use the full
available area, with native safe areas and keyboard behavior.

## Implementation and verification sequence

1. Connect a shared communication directory to native channel and DM screens.
   Keep one search across both sections and persist channel collapse. Add native
   `/messages`, `/messages/:id`, `/channels/:slug` routing, correct selected
   navigation, bounded independent scrolling and direct link behavior. A direct
   conversation link must never briefly select or mark another conversation read.
   Remove redundant headers/empty sidebar reservations. Derive layout from the
   source reference; do not introduce separate tabs.
2. Connect the existing file selector to the verified private upload pipeline:
   JPEG/PNG/WebP/GIF, 10 MiB each, four attachments maximum. Use filenames and
   clear pending/error states; keep server asset IDs out of the normal UI. Keep
   bytes and every completion step bound to the account that initiated upload.
3. Consolidate any remaining fixture-only communication widgets so integration
   checks exercise the actual native UI with synthetic repositories/HTTP data.
   Add route, direct link, recipient search, account change, phone/tablet/desktop,
   large text, keyboard and attachment failure coverage. Re-run dependency,
   formatting, analysis, all tests and native Linux screenshot checks serially.
4. Integrate shared poll rendering/voting/editing, then draft poll authoring.
   Confirmed routes: POST `/api/v1/polls/:id/vote` with nullable optionId;
   PUT `/api/v1/polls/:id` with question/options, editable before the first vote;
   PUT `/api/v1/articles/:id/poll` while the article has never been published.
   Poll DTO: id/question/options(id,label,votes)/totalVotes/viewerOptionId.
   Limits: question 200, each choice 100, 2–6 distinct non-empty choices.
   Percentages appear after the viewer votes. Preserve recipient choice when
   merging another sender's realtime poll update. Share one typed poll slice;
   the DM model/builder already preserves the projection for integration.
5. Wire the confirmed raw `/ws/community` protocol, not Socket.IO. Check exact
   event names in the contract before implementation. Share one connection per
   authenticated account, guard stale acknowledgments/events, bound reconnects,
   and stop subscriptions when no longer needed. Connect chat/DM history,
   typing, unread/read receipts and access revocation without write retries.

## Runtime checks and limits

Use synthetic data first and keep one local SDK job under the build lock and
resource caps. Never substitute a simulation or a missing-control notice for a
working production path. Native media playback and physical-device voice,
accessibility/performance and stable signing remain separate release gates.

The user authorized the owner account and named controlled recipient `@mrd9999`
for live DM tests. Resolve that exact username through confirmed public data;
never send to a guessed recipient. Use only that conversation for DM write
checks. Track every newly created message/reaction/attachment and delete only
test content afterward; preserve existing account content. Ask for recipient
acceptance only if the actual conversation requires it. Never log credentials,
cookies, signed callback URLs, email addresses or private message bodies.

CodeRabbit needs a current authenticated CLI session before its review can run.
Argon’s follow-up review stopped at its provider quota limit without a report; its terminal is closed. Public update repository setup and
stable signing still require organization-owner actions already requested.

## Integration evidence — 2026-11-06

Steps 1–2 are implemented. Actual route checks cover 360/900/1440px and 1.6 text
scaling, including the 54px header, 240/205px rail, phone navigation and shared
filter/collapse behavior. Two direct-link regressions failed before the change:
collection routes opened the first conversation, and a missing requested ID fell
back to that row. They now pass without fetching or marking that other thread.
Image-picker tests cover streamed bytes, retained Vietnamese text/filenames,
four-image limits and account changes while the system picker is open.

The separate fixture channel screen/state/directories and unused DM-only inbox
were removed. Existing send/switch/read-back coverage now uses the actual routes
with a stateful synthetic HTTP backend. `flutter pub get`, formatting, analysis
and all 397 Flutter tests pass (serialized under the shared build lock). Native
Linux capture and live controlled-recipient checks remain pending. No new live
messages, posts, comments or reactions were created during this integration.

## Live controlled-recipient verification — 2026-11-06

The first read-only preflight resolved the exact named recipient but found no
conversation. The user established and accepted it. A subsequent fresh preflight
confirmed active send/edit/delete access before any test content was sent.
Using the real native repositories, one message, its edit and a reaction each
persisted in fresh history reads. The reaction and message were deleted and a
further read confirmed the test message absent. Existing conversation content
was preserved; the test session was logged out and its ID-only cleanup registry
cleared. Credentials/cookies stayed in anonymous stdin and memory.

REST persistence is now live-verified for this path. Realtime delivery, persistent
DM draft recovery, private attachment device checks and actual native account UI
writes remain separate work. The current suite has 438 passing Flutter tests.
