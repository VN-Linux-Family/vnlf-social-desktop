# Community realtime implementation plan

> For agentic workers: use executing-plans to implement this plan serially in the existing Codex worktree. Checkboxes track verified work, not declarations of readiness.

**Goal:** Deliver incoming channel/DM messages, reactions, deletion, typing and read state through one authenticated native connection, with reliable catch-up after reconnect or resume.

**Architecture:** A pure Dart socket client owns protocol acknowledgments, heartbeat, bounded reconnects and reference-counted subscriptions. IoApiTransport supplies the authenticated upgrade without exposing cookies to presentation. Owner-scoped Riverpod bindings adapt verified event DTOs to existing controllers and refresh only affected caches; lifecycle binding stops background work and catches up on resume.

**Tech stack:** Existing dart:io, Riverpod and Flutter lifecycle APIs. No new package or Socket.IO dependency.

**Spec:** PLAN.md, AGENTS.md, docs/plans/2026-11-06-messaging-integration.md step 5, and pinned upstream ab23799bf66ecec2176b89fa0c7e1151bf5782d3: contracts/realtime.ts, API modules/realtime.ts and lib/auth.ts, web components/social/realtime-context.tsx. Read-only snapshots remain outside Git; do not copy the upstream implementation.

## Global constraints

- One local SDK job through tool/with_build_slot.sh; two CPUs, 3 GB and serialized tests.
- No credentials, cookies, private bodies or signed URLs in files/logs/reports.
- Raw JSON `/ws/community`, cookie-authenticated at upgrade. Client frames have type/requestId/data; acknowledgments have ok/requestId/data or error; events have type/eventId/occurredAt/data.
- Source uses `channel:join/leave`, `conversation:join/leave`, `presence:heartbeat`, `message:typing`, `dm:typing`; no invented dotted events.
- Acknowledgment timeout 8 seconds; heartbeat every 20 seconds. Source server expires presence after 45 seconds and idle sockets after 60.
- Continue sending content through the already verified REST repositories. Never replay send/edit/delete/vote writes on reconnect or acknowledgment failure.
- Source revocation code 4401 triggers session refresh, never an authentication retry loop. Owner changes close the old connection and reject old events/acknowledgments.
- Preserve typed poll viewer selection when another sender's event carries their projection.
- Push code to both private repositories, execute Actions only in luank3. Do not dispatch a full packaging matrix for this feature.

## Review focus

- Logout/account changes during a slow upgrade must close its eventual socket, preventing private cross-account delivery (task 1/2).
- A server event may arrive before initial REST history, or a REST refresh may complete after a newer event; neither may erase fresh messages or reinsert deleted ones (task 3).
- A message for a different conversation/channel must never appear in the active timeline, even when malformed/misrouted upstream (task 3).
- Duplicate mount/unmount and reconnect cycles must not multiply sockets, joins, heartbeats, typing timers or GET refreshes (task 2/4).
- Resume after an unreported network drop must fetch missed history and unread/read state without duplicating outgoing messages (task 4).

## Task 1: Authenticated upgrade and protocol models

Files: modify core/io_api_transport.dart; create features/realtime/domain/community_event.dart and community_connection.dart; create features/realtime/data/io_community_connection.dart; test/core/community_upgrade_test.dart and test/features/realtime/community_protocol_test.dart.

Interfaces: `CommunityConnection` exposes incoming frames, closeCode, send and close. `CommunityConnector` returns a Future<CommunityConnection>. Protocol decoding produces typed acknowledgment/event frames and ignores unknown event types safely; malformed known frames become typed failures. IoApiTransport opens only its own `/ws/community` origin, with its internally restored cookie and an ApiSessionScope guard.

- [x] Write loopback upgrade tests: supplied synthetic cookie/clear User-Agent, correct ws/wss URI, missing cookie refusal, clearCookies during blocked initialization/upgrade, and close/owner-scope invalidation.
- [x] Write protocol tests: separate ack/event envelopes, wrong field types, missing requestId/eventId/type/data, unknown fields and future event types. No payload is logged in an error.
- [x] Run focused tests red, implement the minimal adapters, then run green and analysis. Commit only this verified deliverable.

Task 1 evidence: 12 new upgrade/protocol checks pass; all 84 core-plus-protocol
checks and analysis pass. A 302 with Connection: close reproduced a redirected
upgrade in the unguarded SDK path; the typed HttpClient adapter now disables
redirects. Logout/pending upgrade cancellation and immutable raw envelopes are
covered. The application is not connected until tasks 2–4 are complete.

## Task 2: Shared connection lifecycle

Files: create features/realtime/data/community_socket_client.dart; test/features/realtime/community_socket_client_test.dart.

Interfaces: `CommunitySocketClient` accepts connector and injectable timing/randomness, exposes events and connection status, provides request(type,data), join/leave leases and setForeground. It owns all timer/subscription disposal. Duplicate events are bounded by a recent event-ID set; pending ack map is bounded and drained on timeout/disconnect.

- [x] Write fake-connection tests for correlation, late/unrelated acks, eight-second timeout, negative ack, disconnect cleanup and no message-write replay.
- [x] Write tests for one initial heartbeat, twenty-second heartbeat scheduling, failure/reconnect, reference-counted joins/leaves and rejoin after reconnect.
- [x] Test stale connector completion after stop/owner change, 4401 without reconnect, bounded exponential backoff with jitter, and complete timer/listener disposal. Native backoff is 1/2/4/8/15 seconds plus 0–349ms jitter, stopping after six consecutive failed connection attempts until explicit retry/resume.
- [x] Implement, run green and analysis, then commit.

Task 2 evidence: 17 client lifecycle tests plus four protocol tests pass, with
analysis clean. A regression reproduced re-opening a revoked session on resume;
revocation is now terminal for the lifetime of that client. Stream-only cases use
real asynchronous scheduling; timing cases use Flutter's simulated clock. No
live sockets or app bindings have been enabled by these two foundation tasks.

## Task 3: Channel and DM event integration

Files: create features/realtime/presentation/community_realtime_providers.dart and feature-specific event adapters; modify direct_messages/presentation/direct_message_state.dart, dm_timeline_controller.dart, dm_inbox_controller.dart and channels/presentation/live_channel_state.dart. Add focused synthetic integration tests under test/features/realtime.

Interfaces: One provider per authenticated owner supplies the client from tasks 1/2. Active timelines hold topic leases and release them on disposal. Adapters use existing DTOs and verified source payload shapes. Existing `DmTimelineController.applyRealtimeMessage` gains an explicit conversation guard; channels gain equivalent typed insert/update/delete behavior. Access revocation clears inaccessible content and refreshes directory state.

- [ ] Inspect exact created/updated/deleted/reaction/typing/read/presence payloads in API source before writing fixtures; record only synthetic examples. Source typing/read-update frames omit the topic ID: bind them only to the active leased view, verify sender/peer identity, and never guess a topic when multiple candidates exist.
- [ ] Write regression checks for cross-conversation frames, duplicate own-send echo, peer poll projections, delete during history fetch, event before initial history, late REST completion and account changes.
- [ ] Write live-route widget/provider checks proving incoming messages/reactions/deletion/read status appear without reload and private events never affect another route/account. Debounce affected inbox/directory refetches; do not issue a GET per frame.
- [ ] Implement and run focused checks green, then commit.

## Task 4: App lifecycle, connection UI and end-to-end verification

Files: create features/realtime/presentation/community_realtime_binding.dart; modify main.dart and communication headers/composers for connection/typing state; update parity/API docs and tests.

- [ ] Test no socket for guest/offline fixtures, exactly one connection across channel/DM routes, controlled background suspension, immediate resume catch-up and failed heartbeat recovery. Inactive desktop focus alone must not masquerade as mobile backgrounding.
- [ ] Connect debounced typing state with expiration and an explicit stop when sending/leaving; only active writable topics may emit it. Read receipts keep their confirmed REST mutation paths.
- [ ] Add localized, accessible disconnected/retrying/error state and explicit reconnect action; normal state must not expose protocol/server IDs.
- [ ] Run pub get, formatting, analysis, headless fixture smoke and full tests serially. Build/capture Linux with synthetic data, restore lib/main.dart, and verify native architecture.
- [ ] Use only the existing accepted controlled DM and authorized owner for a short live subscription check. Track every test message/reaction, remove it and confirm fresh-read absence, logout and closed socket. Never read another account's conversations.
- [ ] Push identical commits to both remotes, verify one personal quality run and no organization jobs. Update current parity gates without claiming device/signing readiness.
