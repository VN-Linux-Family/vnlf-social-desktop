# Shared native polls

Owner: Codex in `luank3/vnlf-production-audit`. This continues the authorized
source-parity work. Baseline `e0ab3e5` passes 403 Flutter tests, analysis and actual
Linux image/video checks. The later feed-account fix has two red-to-green regressions, ten focused passing
checks, and a full 405-test pass with formatting and analysis clean.

Reference: GitLab project 86991275, pinned
`ab23799bf66ecec2176b89fa0c7e1151bf5782d3`. Verified source contracts are
`packages/contracts/src/polls.ts`, API `modules/polls.ts`, `lib/polls.ts` and the
web poll card. Use the source only to derive contracts and design.

1. Add immutable poll/option and validated input models, tolerant DTO parsing and
   a repository interface. POST `/api/v1/polls/:id/vote` accepts nullable UUID
   optionId; PUT `/api/v1/polls/:id` accepts question/options. Both acknowledge
   with a full Poll DTO. Validate acknowledgment identity. Writes are single
   attempts, with no automatic retry. Unknown fields remain tolerated.
2. Share one owner-scoped poll state across feed, detail and chat. Read tickets
   captured before history requests prevent late reads from replacing a newer
   acknowledged vote/edit. Only confirmed mutations change counts/selection;
   failed requests retain the existing poll. The ApiClient already invalidates
   its revision-guarded GET cache after writes. Reset all feed tabs on account
   changes, including stale manual refresh/pagination protection.
3. Render the actual question/choices and a total count everywhere the backend
   supplies a poll. Show percentage bars only after the viewer votes. Selecting
   the chosen choice removes the vote. Signed-out actions route to sign-in.
   Show pending/error states and allow author edits only before any votes.
   Remove the DM placeholder that currently says a message contains a poll.
4. Add poll authoring and recovery in the composer through the separately
   confirmed draft-poll route. First inspect its exact acknowledgment, draft
   eligibility, format constraints and save ordering. Never invent this behavior
   or claim authoring works before its native path and recovery tests run.
5. Verify DTO errors, mutation acknowledgments, single-flight controls, late
   reads, account changes, percentage/selection/edit UI, and actual parent-screen
   integration. Run dependency/format/analysis/all tests under the shared build
   lock, then a capped Linux capture and restore the normal app entry point.

Input limits: a 200 UTF-16-unit question, 100 per choice, two to six choices.
Whitespace is collapsed and trimmed, empty choices removed, and duplicate choice
text removed case-sensitively. The server refuses edits after a vote with
`POLL_HAS_VOTES`. Peer realtime updates must preserve this viewer's selection;
connect that path when the verified community socket is integrated.

Use synthetic repositories first. Live validation uses the owner's account and
its own test content or the controlled-recipient conversation. Remove all new
test writes and preserve existing content as required by the task authorization.

## Foundation evidence

Domain/DTO/repository and owner-scoped shared state are implemented. Twelve
focused tests and analysis pass. They cover exact payloads, missing/unrelated
acknowledgments, no automatic write retry, immutable parsing/input normalization,
single-flight writes, retained state on failure, older/in-flight read rejection,
account reset, and peer viewer-choice preservation. Parent model/provider/UI
integration is still in progress; the existing placeholder is not counted as a
working poll feature. No live poll writes have been made.

## Read, vote and edit integration

Steps 1–3 now use typed polls in feed/detail, discovery/profile and channel/DM
models. The native card replaces chat placeholders, uses the observed 420px
post/340px chat widths, hides percentages until voting, routes guests to sign-in
and exposes author edits before the first vote. The editor preserves failed
input and uses the server's UTF-16 limits with an honest counter and intact emoji.

Parent read tickets are captured for feed/detail, profile/discovery and chat
history/context/pagination. A regression first reproduced a stale 67% overlay
masking a fresh detail response; the integrated path now shows the server's 75%.
Typed peer message merges do not adopt another viewer's choice. Profile data now
reloads on owner changes as well. Seventy-five focused integration checks and all
424 Flutter tests pass, with pub get, formatting and analysis clean. Linux poll
captures, live owner-account writes and composer authoring remain pending.

The first native capture exposed a zero-height percentage fill despite correct
numeric labels. A geometry regression reproduced 0px versus a 48px option;
explicit full-height layout fixes it. Twenty focused poll checks and all 425
Flutter tests pass. Refresh the native capture before recording visual completion.
