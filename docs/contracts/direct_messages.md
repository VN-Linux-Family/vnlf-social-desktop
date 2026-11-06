# Direct Messages (DM) Source-Derived Contract Report

- **Date**: 2026-11-05
- **Author**: Gemini 4 Argon (High)
- **Authoritative Source**: Private GitLab project `realfox99/vnlf-social` (`86991275`) pinned at commit `ab23799bf66ecec2176b89fa0c7e1151bf5782d3`
- **Inspected Source Modules**:
  - `apps/api/src/modules/dm.ts`
  - `apps/api/src/lib/dm-send.ts`
  - `apps/api/src/lib/dm-events.ts`
  - `apps/api/src/lib/chat-message.ts`
  - `apps/api/src/lib/chat-media.ts`
  - `apps/api/src/lib/message-access.ts`
  - `apps/api/src/lib/reactors.ts`
  - `apps/api/src/lib/read-sync.ts`
  - `apps/api/src/lib/media.ts`
  - `apps/api/src/modules/channels.ts`
  - `apps/api/src/modules/assets.ts`
  - `apps/api/src/modules/users.ts`
  - `apps/api/src/modules/realtime.ts`
  - `packages/contracts/src/social.ts`
  - `packages/contracts/src/realtime.ts`
  - `packages/contracts/src/reactions.ts`
  - `packages/contracts/src/message-text.ts`
  - `packages/contracts/src/gif.ts`
  - `apps/web/components/social/views/direct-message-live-view.tsx`
  - `apps/web/components/social/communication-list.tsx`
  - `apps/web/components/social/chat/chat-ui.tsx`
  - `apps/web/components/social/chat/use-chat-attachments.ts`
  - `apps/web/components/social/chat/conversation-search.tsx`
  - `apps/web/components/social/chat/conversation-media.tsx`
  - `apps/web/lib/dm-send.ts`
  - `apps/web/lib/chat-outbox.ts`
  - `apps/web/lib/chat-timeline.ts`
  - `docs/11-direct-messages.md`
- **Policy**: Source was inspected read-only as contract and design evidence. Zero upstream code was copied verbatim. Zero live requests or private account/DM accesses were performed. All native tests use synthetic data only.

---

## 1. Conversation & Request Lifecycle

1. **Direct 1-1 Invariant (`apps/api/src/modules/dm.ts:25,92`)**:
   - Every DM conversation is strictly 1-to-1 (`MVP không có group DM`).
   - Uniqueness per user pair is enforced by `directKey = [userA, userB].sort().join(":")` computed on the server. The client never supplies `directKey`.
   - Creating a conversation with oneself is rejected with `400 DM_SELF`.
2. **Conversation Statuses & Viewer States (`packages/contracts/src/social.ts:193-207`, `apps/api/src/modules/dm.ts:47-51`)**:
   - `conversation.status`: `"REQUESTED" | "ACTIVE" | "DECLINED" | "CLOSED"`
   - `conversation_members.status`: `"ACTIVE" | "REQUESTED" | "DECLINED" | "REMOVED"`
   - `ConversationDto.viewerState`:
     - `"BLOCKED_BY_ME"`: Either user has blocked the other (`isBlocked(services, userId, peer.id)` checks bidirectional `blocks` rows at `dm-send.ts:127`). Peer identity is redacted to `{ id: peer.id, username: "", displayName: "Người bạn đã chặn", avatarUrl: null, presence: "OFFLINE" }` (`style` omitted, `peerLastReadMessageId: null`).
     - `"ACTIVE"`: `conversation.status === "ACTIVE"` and not blocked.
     - `"AWAITING_ACCEPTANCE"`: `conversation.status === "REQUESTED"` and `conversation.createdBy === userId` (viewer initiated the request).
     - `"REQUEST_REQUIRED"`: Either an incoming pending request (`conversation.status === "REQUESTED"` and `conversation.createdBy !== userId`), or a `DECLINED`/`CLOSED` conversation that requires sending a new request (`POST /api/v1/dm/conversations`).
3. **First-Message Request Rule (`apps/api/src/modules/dm.ts:45-50`, `apps/api/src/lib/dm-send.ts:152-156`)**:
   - While `conversation.status === "REQUESTED"`, the requester (`conversation.createdBy === userId`) is allowed to send **at most one** message (`requestUsed = sentCount > 0`).
   - `canSend` in `ConversationDto` is `!blocked && (conversation.status === "ACTIVE" || (requester && !requestUsed))`.
   - A second send before the recipient accepts is rejected by the server with `409 DM_REQUEST_PENDING`.
   - The recipient cannot send messages until accepting (`403 DM_REQUEST_REQUIRED`).

---

## 2. Confirmed REST Endpoints, Payloads, and Response Shapes

### 2.1 Conversation Inbox & Lifecycle (`apps/api/src/modules/dm.ts`)

| Method | Path | Request Query / Body | Confirmed Response Shape | Server Error Codes |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/dm/conversations` | None | `{ items: ConversationDto[] }` (excludes `membership.status === "REMOVED"`, ordered by `updatedAt DESC`) | `401 AUTH_REQUIRED` |
| `GET` | `/api/v1/dm/conversations/:id` | None | `ConversationDto` | `401 AUTH_REQUIRED`, `403 CONVERSATION_FORBIDDEN`, `404 CONVERSATION_NOT_FOUND` |
| `POST` | `/api/v1/dm/conversations` | `{ recipientUserId: string }` | Existing `ACTIVE`/`REQUESTED`: `200 { conversationId, status }`; Reopened: `200 { conversationId, status: "REQUESTED" }`; Created: `201 { conversationId, status: "REQUESTED", requestId }` | `400 DM_SELF`, `403 DM_BLOCKED`, `404 USER_NOT_FOUND`, `429 RATE_LIMITED` (10 requests / 24h) |
| `POST` | `/api/v1/dm/conversations/:id/accept` | None | `{ ok: true }` | `404 CONVERSATION_NOT_FOUND`, `409 DM_REQUEST_NOT_PENDING` |
| `POST` | `/api/v1/dm/conversations/:id/decline` | None | `{ ok: true }` | `404 CONVERSATION_NOT_FOUND`, `409 DM_REQUEST_NOT_PENDING` |
| `DELETE` | `/api/v1/dm/conversations/:id` | None | `{ ok: true }` (sets viewer membership to `REMOVED`) | `403 CONVERSATION_FORBIDDEN` |

#### `ConversationDto` Schema (`packages/contracts/src/social.ts:193-207`)
```json
{
  "id": "uuid",
  "status": "REQUESTED | ACTIVE | DECLINED | CLOSED",
  "viewerState": "ACTIVE | BLOCKED_BY_ME | REQUEST_REQUIRED | AWAITING_ACCEPTANCE",
  "canSend": true,
  "unreadCount": 2,
  "firstUnreadMessageId": "uuid | null",
  "lastReadMessageId": "uuid | null",
  "peerLastReadMessageId": "uuid | null",
  "lastMessageId": "uuid | null",
  "lastMessage": "string | null",
  "updatedAt": "2026-11-05T10:00:00.000Z",
  "peer": {
    "id": "uuid",
    "username": "string",
    "displayName": "string",
    "avatarUrl": "string | null",
    "style": "UserStyle | null",
    "presence": "ONLINE | OFFLINE"
  }
}
```

### 2.2 Conversation Messages, Context, Read Cursor, Search & Media (`apps/api/src/modules/dm.ts:97-104`)

| Method | Path | Request Query / Body | Confirmed Response Shape | Server Error Codes |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/dm/conversations/:id/messages` | Query: `cursor?` (string), `limit?` (`1..50`, default `30`, web uses `50`) | `{ items: MessageDto[], nextCursor: string \| null, viewerState: "BLOCKED_BY_ME" \| "ACTIVE" }` (chronological order; `deletedAt != null` excluded; when blocked, peer message `author` is `{ username: "", displayName: "Người bạn đã chặn" }`) | `403 CONVERSATION_FORBIDDEN` |
| `GET` | `/api/v1/dm/conversations/:id/messages/context` | Query: `around` (target message ID) | `{ items: MessageDto[], targetMessageId: string }` (up to 10 before + target + 10 after) | `403 CONVERSATION_FORBIDDEN`, `404 MESSAGE_NOT_FOUND` |
| `GET` | `/api/v1/dm/conversations/:id/messages/search` | Query: `q` (`2..100` chars), `limit?` (`1..50`, default `20`) | `{ items: Array<{ messageId, conversationId, sender: { id, username, displayName, avatarUrl }, excerpt, sentAt, contextCursor }>, nextCursor: null }` | `403 CONVERSATION_FORBIDDEN` |
| `GET` | `/api/v1/dm/conversations/:id/media` | Query: `cursor?` (string) | `{ items: Array<{ id, messageId, width, height, createdAt, downloadPath, author }>, nextCursor: string \| null }` | `403 CONVERSATION_FORBIDDEN` |
| `POST` | `/api/v1/dm/conversations/:id/messages` | `{ clientMessageId: string (1..100), content: string (0..4000), replyToId?: string, attachmentIds?: string[] (<=4), gif?: GifAttachment, poll?: PollInput }` | `MessageDto` (deduplicated by `(authorId, clientMessageId)`) | `400 MESSAGE_EMPTY`, `400 ATTACHMENT_INVALID`, `400 REPLY_INVALID`, `403 CONVERSATION_FORBIDDEN`, `403 DM_REQUEST_REQUIRED`, `403 DM_BLOCKED`, `404 CONVERSATION_NOT_FOUND`, `409 DM_REQUEST_PENDING`, `409 CLIENT_MESSAGE_ID_CONFLICT`, `429 RATE_LIMITED` |
| `POST` | `/api/v1/dm/conversations/:id/read` | `{ lastReadMessageId?: string }` (`{}` marks up to latest conversation message) | `{ ok: true, changed: boolean, lastReadMessageId: string \| null }` | `400 READ_MESSAGE_INVALID`, `403 CONVERSATION_FORBIDDEN` |

### 2.3 Shared Message Mutations (`apps/api/src/modules/channels.ts:146-150`, `apps/api/src/lib/message-access.ts:240-255`)

All `/api/v1/messages/:id*` endpoints enforce `requireMessageAccess`: for DM messages (`message.conversationId != null`), the viewer must have `conversation_members.status === "ACTIVE"`, `conversations.status === "ACTIVE"`, and no block between participants (`403 CONVERSATION_FORBIDDEN` / `403 DM_BLOCKED`).

| Method | Path | Request Body | Confirmed Response Shape | Constraints & Error Codes |
| :--- | :--- | :--- | :--- | :--- |
| `PATCH` | `/api/v1/messages/:id` | `{ content: string (1..4000) }` | `MessageDto` | Author only; non-empty after `tidyMessageText` (`400 MESSAGE_EMPTY`); must be within **15 minutes** of `createdAt` (`409 MESSAGE_EDIT_WINDOW_EXPIRED`). |
| `DELETE` | `/api/v1/messages/:id` | None | `{ ok: true }` | Author only; sets `content = ""` and `deletedAt = now()`, emits `dm:message-deleted`. |
| `POST` | `/api/v1/messages/:id/reactions` | `{ emoji: string (1..32) }` | `MessageDto` | Any active unblocked conversation member; idempotent `onConflictDoNothing()`, emits `reaction:changed`. |
| `DELETE` | `/api/v1/messages/:id/reactions/:emoji` | None | `MessageDto` | Removes viewer's reaction for URL-encoded `:emoji`, emits `reaction:changed`. |
| `GET` | `/api/v1/messages/:id/reactions` | None | `{ items: Array<{ emoji: string, users: Array<{ id, username, displayName, avatarUrl, style }> }> }` | Lists reactors grouped by emoji in first-used order. |

### 2.4 Private Media Upload & Signed URL Resolution (`apps/api/src/modules/dm.ts:100-101`, `apps/api/src/modules/assets.ts:36-52`, `apps/api/src/lib/media.ts:14-55`)

1. **Attachment projection in `chatMessageDto` (`apps/api/src/lib/chat-message.ts:28`)**:
   - Every DM message attachment has `url: null` and `downloadPath: "/api/v1/assets/${asset.id}/download"`.
   - If a message replies to a message with attachments, `replyTo.previewAttachment` also has `url: null` and `downloadPath: "/api/v1/assets/${preview.id}/download"`.
2. **Signed URL resolution (`GET /api/v1/assets/:id/download`)**:
   - Authenticated API request verifies `assertCanViewAsset` (viewer is owner or non-removed/non-declined member of the conversation).
   - Returns `{ assetId: string, downloadUrl: string, expiresIn: number, mime: string, size: number }`.
   - The native client resolves `downloadPath` through `ApiClient` (with session cookie) and passes the returned `https://` `downloadUrl` to media widgets **without** forwarding session cookies or API headers to the R2/CDN host.
3. **Private DM Image Upload (`POST /api/v1/dm/assets/presign` -> `PUT uploadUrl` -> `POST /api/v1/dm/assets/:assetId/complete`)**:
   - `POST /api/v1/dm/assets/presign` body: `{ fileName: string, mime: string, size: number }`.
   - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`, `image/gif`. Max size: `10 * 1024 * 1024` bytes (`10 MiB`).
   - Returns `{ assetId: string, uploadUrl: string, expiresIn: 600, headers: { "content-type": mime } }`.
   - Client uploads bytes via raw `PUT` to `uploadUrl` with `Content-Type: <mime>` and `Content-Length: <size>` (no API credentials/cookies).
   - Client confirms via `POST /api/v1/dm/assets/:assetId/complete` -> `{ assetId: string, status: "READY", url: null }`.
   - Up to 4 `READY` DM `assetId`s can be attached to `POST /api/v1/dm/conversations/:id/messages`.

### 2.5 Block, Unblock & Conversation Report (`apps/api/src/modules/users.ts:445-446`, `apps/api/src/modules/dm.ts:105`)

| Method | Path | Request Body | Confirmed Response Shape | Behavior |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/users/:id/block` | None | `{ ok: true }` | Inserts `blocks` row, removes mutual follows, sets conversation `status = "CLOSED"`, publishes `access:revoked`. |
| `DELETE` | `/api/v1/users/:id/block` | None | `{ ok: true, viewerState: "REQUEST_REQUIRED" }` | Removes `blocks` row; conversation remains `CLOSED` with `viewerState: "REQUEST_REQUIRED"` until a new request is sent. |
| `POST` | `/api/v1/dm/conversations/:id/report` | `{ reason: "SPAM" \| "HARASSMENT" \| "SCAM" \| "OTHER", detail?: string (<=2000) }` | `{ reportId: string }` | Creates report (`targetType: "DM_CONVERSATION"`) and snapshots up to 20 most recent messages into `dm_report_snapshots`. |

---

## 3. Source vs. Internal Documentation Discrepancies Recorded

1. **Report Endpoint Path (`apps/api/src/modules/dm.ts:105` vs `docs/11-direct-messages.md` §9)**:
   - `docs/11-direct-messages.md` §9 lists `POST /api/v1/reports` with `targetType=DM_CONVERSATION`, whereas the pinned API (`dm.ts:105`) and web client (`direct-message-live-view.tsx:310,313`) use `POST /api/v1/dm/conversations/:id/report` which atomically captures the 20-message `dm_report_snapshots` rows. The native DM repository uses the confirmed `/api/v1/dm/conversations/:id/report` endpoint.
2. **Context Endpoint Path (`apps/api/src/modules/dm.ts:104` vs `docs/11-direct-messages.md` §9)**:
   - `docs/11-direct-messages.md` §9 writes `GET /api/v1/dm/conversations/:id/messages?around=:messageId&limit=21`, whereas the actual route in `dm.ts:104` and `chat-timeline.ts:311` is `GET /api/v1/dm/conversations/:id/messages/context?around=:messageId`. The native DM repository uses `/api/v1/dm/conversations/:id/messages/context?around=...`.
3. **Blocked Peer Author Redaction in Message History (`apps/api/src/modules/dm.ts:97`)**:
   - When `blocked` is true, `GET /api/v1/dm/conversations/:id/messages` overwrites peer `item.author` with `{ username: "", displayName: "Người bạn đã chặn" }`, omitting `author.id` while preserving top-level `item.authorId`. `DmMessageDto` tolerantly falls back to `item.authorId` when `author.id` is absent.
4. **Delete ("Thu hồi") Window (`apps/api/src/modules/channels.ts:146-147` vs `docs/11-direct-messages.md` §6)**:
   - `PATCH /api/v1/messages/:id` enforces `Date.now() - createdAt <= 15 * 60000` (`409 MESSAGE_EDIT_WINDOW_EXPIRED`), whereas `DELETE /api/v1/messages/:id` only checks `authorId === user.userId` and `requireMessageAccess`.

---

## 4. Native Feature Slice Architecture & Integration Hooks

Because this worker owns only `lib/src/features/direct_messages/**`, `test/features/direct_messages/**`, and `docs/contracts/direct_messages.md`:

- **Implemented in this slice**:
  - Domain models, enums, text normalizer (`tidyDmMessageText`), and `DirectMessageRepository` interface (`lib/src/features/direct_messages/domain/`).
  - Tolerant DTOs (`direct_message_dto.dart`), scoped private media resolver & unauthenticated presigned uploader (`direct_message_media_repository.dart`), and `LiveDirectMessageRepository` (`live_direct_message_repository.dart`).
  - Session-guarded Riverpod controllers (`DmInboxController`, `DmTimelineController`) with single-flight request locks, stable `clientMessageId` across manual retries, draft/reply/attachment retention on failure, confirmed-write follow-up refresh guards, and account-change state resets (`direct_message_state.dart`).
  - Adaptive Vietnamese-first / English-secondary native UI (`DirectMessagesScreen`, `DirectMessageInbox`, `DirectMessageTile`, `DirectMessageComposer`, `DirectMessageMedia`, search/media/report/block dialogs).
- **Coordinator Integration Points & Deferred Scope**:
  - **Router / Navigation Shell**: Wire `DirectMessagesScreen` into `lib/src/app/app_router.dart` (e.g. `/messages` or alongside `/channels` in the communication workspace).
  - **File Picker Wiring for DM Image Uploads**: `DirectMessageRepository.uploadAttachment(DmUploadFile)` and `DmTimelineController.uploadAndAttach(DmUploadFile)` implement the full 3-step `/api/v1/dm/assets/presign` -> unauthenticated `PUT` -> `/api/v1/dm/assets/:assetId/complete` contract (validated for `image/jpeg`, `image/png`, `image/webp`, `image/gif`, `image/avif` up to 10 MiB, max 4 attachments per message). No fake upload button is shown in the UI until a global file picker is wired to `controller.uploadAndAttach(...)`.
  - **Shared Poll Integration Hook & Realtime `viewerOptionId` Preservation**: `DmMessage.poll` preserves the raw immutable `Map<String, dynamic>?` poll projection from `MessageDto`, and `DirectMessagesScreen` / `DirectMessageTile` expose `DmPollWidgetBuilder? pollBuilder` so the coordinator's shared native poll card can be injected directly without duplicating poll logic. For realtime message/poll updates (`apps/web/lib/chat-timeline.ts`), `DmMessage.withPreservedPollViewerChoice` and `DmTimelineController.applyRealtimeMessage(incoming, preservePollViewerOptionId: true)` preserve each recipient's existing `viewerOptionId` rather than adopting the sender's choice.
  - **Realtime WebSocket Push (`/ws/community`)**: REST history, pagination, context jump, search, media listing, read receipts, and mutations work standalone without fake optimistic acknowledgments. Live `/ws/community` subscription (`dm.join`, `dm.leave`, `typing.update`, `dm:message-created`, `dm:message-updated`, `dm:message-deleted`, `dm:request-created`, `dm:request-updated`, `dm:peer-read`, `conversation:access-revoked`) is gated on shared WebSocket session integration and can drive `DmTimelineController.applyRealtimeMessage(...)`, `DmTimelineController.refresh()`, and `DmInboxController.load(refresh: true)`.
  - **Unsupported / Deferred Gates**:
    - Group DMs (unsupported by backend; server enforces 1-to-1 `directKey`).
    - DM video/audio/document uploads (server `POST /api/v1/dm/assets/presign` only permits image MIME types `<= 10 MiB`).
    - Interactive GIF/sticker/poll creation pickers in the DM composer (incoming `gif` and `poll` projections are parsed and rendered).
    - Detailed reactor list modal (`GET /api/v1/messages/:id/reactions` is documented in §2.3; inline reaction counts and toggle mutations are active).
