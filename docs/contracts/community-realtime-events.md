# Community realtime event contract

Source audit only: GitLab project `realfox99/vnlf-social` (86991275), commit `ab23799bf66ecec2176b89fa0c7e1151bf5782d3`. Paths and line numbers below refer to that exact revision. No live socket or HTTP request was made for this card. Source describes intended behavior, not evidence of deployed delivery, ordering, completeness, or current production parity. Examples are entirely synthetic.

## Transport and envelope

The source upgrades an authenticated socket at `/ws/community` and exchanges raw JSON. Client frames carry `type`, `requestId`, and `data`; success and failure acknowledgments carry `ok` and the matching `requestId`, with optional `data` or `error` (`code`, `message`, optional `retryable`). Server events carry `type`, `eventId`, ISO `occurredAt`, and `data`. The generic event schema declares `data` unknown; the shapes below come from actual producers. The server wraps publications lacking an event ID; DM message publications already carry an ID and timestamp. References: `packages/contracts/src/realtime.ts:11-39`, `apps/api/src/modules/realtime.ts:25-32,49-50,72-77`, `apps/api/src/lib/dm-events.ts:10-14`.

For example, a channel join is `{"type":"channel:join","requestId":"request-1","data":{"channelId":"11111111-1111-4111-8111-111111111111"}}`; the corresponding DM join is `conversation:join` with `conversationId`. Both schemas optionally accept `lastSeenMessageId`, but the handlers only authorize, subscribe and acknowledge; they do not use it for replay. Leave uses `channel:leave` or `conversation:leave` and the respective ID. A channel join requires a non-archived channel and sufficient view role; DM join requires eligible membership, a peer and no block in either direction. A successful join is not evidence of replay or a permanent authorization grant. `apps/api/src/modules/realtime.ts:47-57`; `packages/contracts/src/realtime.ts:12-16`.

Every event example below represents `data` inside the common envelope, e.g. `{"type":"presence:changed","eventId":"event-1","occurredAt":"2026-01-01T00:00:00.000Z","data":{"userId":"33333333-3333-4333-8333-333333333333","status":"ONLINE"}}`. IDs and content throughout are invented fixture values.

## Message events

| Type | `data` | Routing and actor |
| --- | --- | --- |
| `message:created`, `message:updated` | Full `MessageDto` | Non-null `channelId`; author in `authorId` and `author.id`. |
| `dm:message-created`, `dm:message-updated` | Full `MessageDto` | Non-null `conversationId`; author in `authorId` and `author.id`. |
| `message:deleted`, `dm:message-deleted` | `{messageId, channelId, conversationId}`; both topic keys exist and are nullable | Route on the non-null topic ID. No deleting actor is carried. |
| `reaction:changed` (both channel and DM) | `{messageId, channelId, conversationId, reactions}`; nullable topic IDs; reactions are `{emoji, count, viewerReacted}[]` | Route on the non-null topic ID and message ID. No reacting actor is carried. This is the resulting reaction list, not an add/remove delta. |

The message DTO contains `id`, nullable `channelId` and `conversationId`, `authorId`, `clientMessageId`, nullable `replyToMessageId` and `replyTo`, `mentions`, `attentionUserIds`, `content`, nullable `editedAt` and `deletedAt`, `createdAt`, `author`, `reactions`, `attachments`, nullable `gif`, and optional nullable `poll`. `author` has `id`, `username`, `displayName`, nullable `avatarUrl`, and optional nullable `style`; reply, asset, GIF and poll nested schemas are defined in the source contracts. `mentions` contain `id`, `token`, `username`, `displayName`; reaction entries have the three fields above. Source: `packages/contracts/src/social.ts:128-154`, `apps/api/src/lib/chat-message.ts:13-28`, `apps/api/src/lib/channel-send.ts:53-56`, `apps/api/src/lib/dm-send.ts:72-74`, `apps/api/src/modules/channels.ts:146-150`.

Synthetic minimal message data (empty collections and null optional structures):

```json
{"id":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","channelId":"11111111-1111-4111-8111-111111111111","conversationId":null,"authorId":"33333333-3333-4333-8333-333333333333","clientMessageId":"fixture-1","replyToMessageId":null,"replyTo":null,"mentions":[],"attentionUserIds":[],"content":"Synthetic message","editedAt":null,"deletedAt":null,"createdAt":"2026-01-01T00:00:00.000Z","author":{"id":"33333333-3333-4333-8333-333333333333","username":"fixture","displayName":"Fixture","avatarUrl":null},"reactions":[],"attachments":[],"gif":null,"poll":null}
```

For a DM, the same DTO has `channelId: null` and a non-null `conversationId`. Synthetic deletion and reaction data respectively:

```json
{"messageId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","channelId":"11111111-1111-4111-8111-111111111111","conversationId":null}
{"messageId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","channelId":null,"conversationId":"22222222-2222-4222-8222-222222222222","reactions":[{"emoji":"👍","count":1,"viewerReacted":true}]}
```

The DTO is built using the initiating user as viewer, including `viewerReacted` and poll viewer state; those values cannot be treated as the receiving account's state. Preserve independently known viewer state or reconcile via an authorized HTTP read. DM publishers send the same event ID to the conversation and each member's notification topic, so a socket can receive duplicates; deduplicate by event ID. Channel created is published only for a newly created message, not a duplicate client-message replay. References: `apps/api/src/lib/chat-message.ts:13-28`, `apps/api/src/modules/channels.ts:146-150`, `apps/api/src/lib/dm-events.ts:6-14`, `apps/api/src/lib/channel-send.ts:53-56`.

## Typing, reads and presence

| Type | `data` and delivery | Missing identifiers / interpretation |
| --- | --- | --- |
| `typing:changed`, `dm:typing-changed` | `{userId, isTyping}` on the respective channel or conversation topic. | Both omit the topic ID; actor `userId` is present. Input `message:typing` has `channelId`, while `dm:typing` has `conversationId`. Channel typing requires post permission; DM typing requires conversation access. |
| `dm:read-updated` | `{userId, lastReadMessageId}` on the conversation topic, after an advancing WebSocket `dm:read`. | Conversation ID is absent; `userId` is the reader. The input carries `conversationId`. |
| `dm:peer-read` | `{conversationId, lastReadMessageId}` to other members' personal notification topics after an advancing HTTP read. | Reader ID is absent; topic ID is present. This producer differs from the WebSocket read producer. |
| `read:synced` | Personal notification to the reader: `{conversationId?, channelId?, lastReadMessageId?, origin?}`. `lastReadMessageId`, when supplied, may be null; `origin` is omitted if missing or invalid. | No reader ID; personal delivery identifies the recipient. Channel attention clearing can send only `channelId`. A WebSocket read does not pass an origin. |
| `presence:changed` | `{userId, status}` where status is `ONLINE` or `OFFLINE`, broadcast to sockets. | No channel or conversation ID. Match the user to an already authorized peer/member; presence is global, not proof of topic membership. |

Synthetic examples:

```json
{"userId":"33333333-3333-4333-8333-333333333333","isTyping":true}
{"userId":"33333333-3333-4333-8333-333333333333","lastReadMessageId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"}
{"conversationId":"22222222-2222-4222-8222-222222222222","lastReadMessageId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"}
{"channelId":"11111111-1111-4111-8111-111111111111","lastReadMessageId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","origin":"fixture-client"}
{"userId":"33333333-3333-4333-8333-333333333333","status":"OFFLINE"}
```

Read advancement compares message `(createdAt, id)` and emits only on change; do not compare opaque IDs as chronological values. The HTTP path sends peer-read and reader sync; the WebSocket path sends topic read-updated and reader sync. Presence uses per-socket leases, not a single tab's state. References: `apps/api/src/modules/realtime.ts:60-63`, `apps/api/src/modules/dm.ts:50-77`, `apps/api/src/modules/channels.ts:63-79,96`, `apps/api/src/lib/read-sync.ts:6-9`, `apps/api/src/lib/presence.ts:3-27`.

## Revocation

`conversation:access-revoked` carries `{userId, peerId}` for the block producer; it has no conversation ID or explicit reason. The server sends it to sockets belonging to either user and removes all their socket topic subscriptions, not just the affected conversation. Invalidate affected access and restore only independently authorized subscriptions. `session:revoked` carries `{}` and precedes close code `4401` when revalidation finds an invalid or inactive session; a role change closes with `4001`. The web client rechecks session on `4401` rather than automatically reconnecting. Channel catalog changes broadcast `channel:permission-changed` with `{}` and no channel or actor ID, requiring permission/catalog refresh. References: `apps/api/src/modules/users.ts:66`, `apps/api/src/modules/realtime.ts:31-43`, `apps/api/src/modules/channels.ts:154-156`, `apps/web/components/social/realtime-context.tsx:112-122`.

Synthetic revocation data: `{"userId":"33333333-3333-4333-8333-333333333333","peerId":"44444444-4444-4444-8444-444444444444"}` and `{}` for session revocation. The contract schema also names `moderation:session-revoked`; its producer and data shape are not established by this audit and must not be inferred from `session:revoked`.

## Safe application and reconciliation

Apply message and reaction frames only when the non-null topic ID matches the active account and target view/cache, and the message identity matches where applicable. Personal DM delivery means a frame can concern a non-active conversation. Reject malformed or ambiguous routing rather than attaching it to the visible conversation. Typing and `dm:read-updated` lack topic IDs; the wire frame does not reveal which subscription delivered it. If more than one relevant topic can be subscribed, or a leave/join transition is in flight, do not attribute these frames to the active view from timing or actor alone. A dedicated connection with exactly one relevant subscription and a stable acknowledged lifecycle may provide local context, but cross-topic assumptions and late delivery remain unverified; omit the indicator when uncertain.

Treat `eventId` as a deduplication key, not an ordering cursor; timestamps do not establish a complete order or delivery guarantee. Reconcile with existing authorized HTTP reads after reconnect and restored joins, on returning from a suspended/background state, after ambiguous or missed events, access changes, and when an event races an initial in-flight load. The web client performs catch-up after rejoining and on resume, deduplicates IDs, and refetches an affected first load that is still in flight. A fresh read must not overwrite a newer event or cross an account/view generation. `apps/web/components/social/realtime-context.tsx:43-50,57-98,117-143`. The source does not establish live replay, gap detection, delivery ordering, or production deployment parity; those remain unknown.
