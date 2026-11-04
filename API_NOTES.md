# VNLF API Notes: Network Protocol & Data Contracts

All endpoints, payload schemas, and realtime events documented here are captured directly from `vietnamlinuxfamily.net` production client bundles and live network inspection. Never invent endpoints.

---

## 1. Client Protocol & Anti-Corruption Layer

### Base URL
- Production API: `https://vietnamlinuxfamily.net`
- Realtime WebSocket: `wss://vietnamlinuxfamily.net/ws/community`
- Voice SFU Server: `https://voice.vietnamlinuxfamily.net` / `wss://voice.vietnamlinuxfamily.net`
- Media CDN: `https://media.vietnamlinuxfamily.net`

### Request Headers
Every request made by the native client MUST replicate the web client's exact envelope:
```http
x-vnlf-client: <persistent-client-uuid-v4>
Content-Type: application/json
Accept: application/json
User-Agent: VNLF-Mobile/<version> (Linux; Android)
```
- `x-vnlf-client`: Persistent UUID generated once on installation and stored securely in local device storage.
- Session Management: Cookie-based session (`credentials: "include"`). The server sets session cookies upon login/register. The native `ApiClient` must use a persistent cookie jar (`CookieJar` / `flutter_secure_storage`).

### Standard Error Response Shape
```json
{
  "code": "AUTH_REQUIRED",
  "message": "Bạn cần đăng nhập.",
  "requestId": "c819f89a-b193-48f9-a7bf-34f451a93e19"
}
```
All errors must be mapped into a typed Dart sealed class `ApiFailure` with status code, typed error code, localized message, and trace `requestId`.

### CORS & Web Platform Restriction
- **Status**: [CONFIRMED]
- The production server returns `HTTP 500` on `OPTIONS` preflight requests and does NOT emit `Access-Control-Allow-Origin` headers.
- **Impact**: Flutter Web running in a browser from `localhost` or a separate domain will be blocked by browser CORS policy.
- **Native Targets**: Linux, Android, iOS, Windows, macOS do not enforce browser CORS and communicate directly without issue.
- **Web Workaround**: For Flutter Web builds, requests must be routed through a reverse proxy (e.g. Caddy/Nginx) or served from the same domain.

---

## 2. Authentication & Session

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/auth/session` | [CONFIRMED] | No | Current session status. Returns user profile or `401 AUTH_REQUIRED`. |
| `POST` | `/api/v1/auth/login` | [CONFIRMED] | No | Body: `{"login": "<email|username>", "password": "<pwd>"}` |
| `POST` | `/api/v1/auth/register` | [CONFIRMED] | No | Body: `{"email": "<email>", "username": "<user>", "password": "<pwd>"}` |
| `POST` | `/api/v1/auth/refresh` | [CONFIRMED] | Cookie | Rotates session cookies. |
| `POST` | `/api/v1/auth/logout` | [CONFIRMED] | Cookie | Invalidates current server session and clears cookies. |

---

## 3. Feed, Articles & Posts

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/feed` | [CONFIRMED] | Optional | Query: `type=latest\|trending\|article\|following`, `limit=20`, `cursor=<id>`. Returns `{ "items": [...], "nextCursor": ... }` |
| `GET` | `/api/v1/articles/{id}` | [CONFIRMED] | Optional | Fetch full post detail with body, poll, and asset attachments. |
| `POST` | `/api/v1/articles` | [CONFIRMED] | Yes | Create post/article. Body: `{ "title": "...", "contentJson": {...}, "contentText": "..." }` |
| `POST` | `/api/v1/articles/{id}/publish` | [CONFIRMED] | Yes | Publish a drafted post. |
| `PUT` | `/api/v1/articles/{id}/vote` | [CONFIRMED] | Yes | Body: `{"value": 1 \| 0 \| -1}`. Returns `{"viewerVote": 1, "voteScore": 12, "viewerLiked": true}` |
| `POST` | `/api/v1/articles/{id}/like` | [CONFIRMED] | Yes | Toggle like on post. |
| `POST` | `/api/v1/articles/{id}/bookmark` | [CONFIRMED] | Yes | Toggle bookmark on post. |
| `DELETE`| `/api/v1/articles/{id}` | [CONFIRMED] | Yes | Delete authored post. |
| `GET` | `/api/v1/articles/{id}/comments`| [CONFIRMED] | Optional | Fetch comment hierarchy for article. |
| `POST` | `/api/v1/articles/{id}/comments`| [CONFIRMED] | Yes | Create comment. Body: `{"content": "...", "parentId": "<optional-comment-id>"}` |

### Post Entity Data Contract
```json
{
  "id": "01a1a586-7efd-7e55-9d8f-93a9b922c431",
  "authorId": "01a13041-2e90-7cf9-87a4-08a82d6e2a54",
  "format": "POST",
  "slug": "luc-moi-biet-linux-khong-co-nhieu-kinh-nghiem",
  "title": null,
  "excerpt": "Lúc mới biết Linux không có nhiều kinh nghiệm...",
  "contentJson": { "type": "doc", "content": [...] },
  "contentText": "...",
  "contentHtml": "<p>...</p>",
  "coverAssetId": null,
  "coverUrl": null,
  "assets": [],
  "tags": [],
  "status": "PUBLISHED",
  "voteScore": 3,
  "viewerVote": 0,
  "commentCount": 4,
  "bookmarkCount": 0,
  "publishedAt": "2026-11-04T08:30:00.000Z",
  "author": {
    "id": "01a13041-2e90-7cf9-87a4-08a82d6e2a54",
    "username": "iamnanoka",
    "displayName": "iamnanoka",
    "avatarUrl": "https://media.vietnamlinuxfamily.net/.../avatar.webp",
    "role": "MEMBER",
    "style": {
      "nameColor": null,
      "nameGradient": { "from": { "light": "#...", "dark": "#..." }, "to": { "light": "#...", "dark": "#..." }, "angle": 90 },
      "icon": { "url": "https://...", "name": "CachyOS", "pixelArt": true },
      "frame": { "id": "matrix", "color": null, "color2": null },
      "nameEffect": "cursor",
      "nameplate": { "id": "waves", "color": null },
      "distroBadge": "cachyos"
    }
  }
}
```

---

## 4. Comments & Moderation

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `PUT` | `/api/v1/comments/{id}/vote` | [CONFIRMED] | Yes | Body: `{"value": 1 \| 0 \| -1}` |
| `POST` | `/api/v1/comments/{id}/like` | [CONFIRMED] | Yes | Toggle comment like. |
| `PATCH`| `/api/v1/comments/{id}` | [CONFIRMED] | Yes | Edit comment body: `{"content": "..."}` |
| `DELETE`| `/api/v1/comments/{id}` | [CONFIRMED] | Yes | Remove comment. |

---

## 5. Leaderboards & Gamification

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/leaderboards` | [CONFIRMED] | Optional | Query: `period=week\|month\|all`. Returns ranked user items and point totals. |
| `GET` | `/api/v1/point-rules` | [CONFIRMED] | Optional | Returns community karma and point rules for actions. |
| `GET` | `/api/v1/me/points` | [CONFIRMED] | Yes | Current user point balance and activity breakdown. |
| `GET` | `/api/v1/me/point-stats`| [CONFIRMED] | Yes | Query: `period=week`. Historical points earned. |
| `POST` | `/api/v1/me/check-in` | [CONFIRMED] | Yes | Daily check-in reward claim. |

---

## 6. Community Channels, Chat & DMs

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/channels` | [CONFIRMED] | Optional | List public community channels. |
| `GET` | `/api/v1/channels/{id}/messages` | [CONFIRMED] | Optional | Fetch channel message history. |
| `POST` | `/api/v1/channels/{id}/messages` | [CONFIRMED] | Yes | Send chat message: `{"content": "...", "replyToId": "..."}` |
| `GET` | `/api/v1/channels/{id}/mention-candidates` | [CONFIRMED] | Yes | Query: `q=<prefix>`. Mention autocompletion. |
| `POST` | `/api/v1/messages/{id}/reactions` | [CONFIRMED] | Yes | Add emoji reaction. |
| `GET` | `/api/v1/dm/conversations` | [CONFIRMED] | Yes | List user direct message conversations. |
| `GET` | `/api/v1/dm/conversations/{id}/messages` | [CONFIRMED] | Yes | List messages in DM thread. |
| `POST` | `/api/v1/dm/conversations/{id}/messages` | [CONFIRMED] | Yes | Send DM message. |
| `POST` | `/api/v1/dm/conversations/{id}/read` | [CONFIRMED] | Yes | Mark DM conversation as read. |

---

## 7. Projects & Showcases

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/projects` | [CONFIRMED] | Optional | Query: `sort=featured\|recent`, `type=<distro|app|etc>`. Returns project showcases. |
| `POST` | `/api/v1/project-images/presign` | [CONFIRMED] | Yes | Presign upload URL for project screenshots. |
| `POST` | `/api/v1/project-images/{assetId}/complete` | [CONFIRMED] | Yes | Confirm upload completion. |
| `GET` | `/api/v1/users/{username}/projects` | [CONFIRMED] | Optional | Projects authored by user. |

---

## 8. Realtime WebSocket Architecture

### Connection Endpoint
```
wss://vietnamlinuxfamily.net/ws/community
```
Connection uses HTTP upgrade with existing session cookies.

### Heartbeat Loop
- Client must send heartbeat frame every **20 seconds** (20000ms):
```json
{
  "type": "presence:heartbeat",
  "data": {}
}
```
If server does not receive heartbeat within 45s, connection is dropped.

### WebSocket Event Catalog [CONFIRMED]
| Event Category | Event Names |
| :--- | :--- |
| **Channels** | `channel:join`, `channel:leave`, `channel:permission-changed` |
| **Messages** | `message:created`, `message:updated`, `message:deleted`, `message:typing`, `typing:changed`, `reaction:changed` |
| **Direct Messages** | `conversation:join`, `conversation:leave`, `conversation:access-revoked`, `dm:send`, `dm:message-created`, `dm:message-updated`, `dm:message-deleted`, `dm:peer-read`, `dm:read`, `dm:read-updated`, `dm:request-created`, `dm:request-updated`, `dm:typing`, `dm:typing-changed` |
| **Voice Rooms** | `voice:access-revoked`, `voice:chat-join`, `voice:chat-leave`, `voice:message-created`, `voice:message-updated`, `voice:message-deleted`, `voice:participant-count-changed`, `voice:reaction-changed`, `voice:room-updated` |
| **Presence & User** | `presence:changed`, `presence:heartbeat`, `user:style-changed`, `session:revoked`, `moderation:session-revoked`, `read:synced` |
| **Notifications** | `notification:created`, `notification:updated` |

---

## 9. Voice Infrastructure
- Control API: `GET /api/v1/voice/rooms`, `POST /api/v1/voice/rooms/{id}/join-token`.
- RTC Engine: LiveKit SFU running at `wss://voice.vietnamlinuxfamily.net`.
- Dart integration: `livekit_client` official Flutter SDK for room connection and microphone streams.
