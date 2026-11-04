# VNLF API Notes: Network Protocol & Data Contracts

All endpoints, payload schemas, and realtime events documented here are derived directly from `vietnamlinuxfamily.net` production client bundles and live network inspection. Never invent endpoints.

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

### Standard Error Response Shape [CONFIRMED]
Observed live response from unauthenticated endpoints:
- Top-level field names: `code`, `message`, `requestId`.
All errors must be mapped into a typed Dart sealed class `ApiFailure` with status code, typed error code, localized message, and trace `requestId`.

### CORS & Web Platform Restriction [CONFIRMED]
- The production server returns `HTTP 500` on `OPTIONS` preflight requests and does NOT emit `Access-Control-Allow-Origin` headers.
- **Impact**: Flutter Web running in a browser from `localhost` or a separate domain will be blocked by browser CORS policy.
- **Native Targets**: Linux, Android, iOS, Windows, macOS do not enforce browser CORS and communicate directly without issue.
- **Web Workaround**: For Flutter Web builds, requests must be routed through a reverse proxy (e.g. Caddy/Nginx) or served from the same domain.

---

## 2. Authentication & Session

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/auth/session` | [CONFIRMED] | No | Current session status. Unauthenticated response returned only field names: `code`, `message`, `requestId`. Contained NO email, NO user ID, NO token. |
| `POST` | `/api/v1/auth/login` | [INFERRED] | No | Inferred from bundle: `{"login": "<email|username>", "password": "<pwd>"}` |
| `POST` | `/api/v1/auth/register` | [INFERRED] | No | Inferred from bundle: `{"email": "<email>", "username": "<user>", "password": "<pwd>"}` |
| `POST` | `/api/v1/auth/refresh` | [INFERRED] | Cookie | Rotates session cookies. |
| `POST` | `/api/v1/auth/logout` | [INFERRED] | Cookie | Invalidates current server session and clears cookies. |

> [!NOTE]
> `/api/v1/auth/session` field audit: The unauthenticated response observed contained solely the keys `code`, `message`, and `requestId`. It contained NO email, NO user id, and NO token. Zero real credentials or user session tokens were received, printed to terminal, written to file, or recorded in logs.

---

## 3. Feed, Articles & Posts

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/feed` | [CONFIRMED] | Optional | Live response observed: `items`, `nextCursor`. Query: `type=latest\|trending\|article\|following`, `limit=20`. |
| `GET` | `/api/v1/articles/{id}` | [INFERRED] | Optional | Fetch full post detail with body, poll, and asset attachments. |
| `POST` | `/api/v1/articles` | [INFERRED] | Yes | Create post/article: `{"title": "...", "contentJson": {...}, "contentText": "..."}` |
| `POST` | `/api/v1/articles/{id}/publish` | [INFERRED] | Yes | Publish a drafted post. |
| `PUT` | `/api/v1/articles/{id}/vote` | [INFERRED] | Yes | Body: `{"value": 1 \| 0 \| -1}`. Returns `{"viewerVote": int, "voteScore": int, "viewerLiked": bool}` |
| `POST` | `/api/v1/articles/{id}/like` | [INFERRED] | Yes | Toggle like on post. |
| `POST` | `/api/v1/articles/{id}/bookmark` | [INFERRED] | Yes | Toggle bookmark on post. |
| `DELETE`| `/api/v1/articles/{id}` | [INFERRED] | Yes | Delete authored post. |
| `GET` | `/api/v1/articles/{id}/comments`| [INFERRED] | Optional | Fetch comment hierarchy for article. |
| `POST` | `/api/v1/articles/{id}/comments`| [INFERRED] | Yes | Create comment: `{"content": "...", "parentId": "<optional-comment-id>"}` |

### Post Entity Schema [CONFIRMED shape, INVENTED Vietnamese sample]
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
| `PUT` | `/api/v1/comments/{id}/vote` | [INFERRED] | Yes | Body: `{"value": 1 \| 0 \| -1}` |
| `POST` | `/api/v1/comments/{id}/like` | [INFERRED] | Yes | Toggle comment like. |
| `PATCH`| `/api/v1/comments/{id}` | [INFERRED] | Yes | Edit comment body: `{"content": "..."}` |
| `DELETE`| `/api/v1/comments/{id}` | [INFERRED] | Yes | Remove comment. |

---

## 5. Leaderboards & Gamification

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/leaderboards` | [CONFIRMED] | Optional | Observed live response: `period`, `periodStart`, `periodEnd`, `computedAt`, `items`. |
| `GET` | `/api/v1/point-rules` | [CONFIRMED] | Optional | Observed live response: `items` array with karma activity rules. |
| `GET` | `/api/v1/me/points` | [INFERRED] | Yes | Current user point balance and activity breakdown. |
| `GET` | `/api/v1/me/point-stats`| [INFERRED] | Yes | Query: `period=week`. Historical points earned. |
| `POST` | `/api/v1/me/check-in` | [INFERRED] | Yes | Daily check-in reward claim. |

---

## 6. Community Channels, Chat & DMs

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/channels` | [CONFIRMED] | Optional | Observed live response with public channel list. |
| `GET` | `/api/v1/channels/{id}/messages` | [INFERRED] | Optional | Fetch channel message history. |
| `POST` | `/api/v1/channels/{id}/messages` | [INFERRED] | Yes | Send chat message: `{"content": "...", "replyToId": "..."}` |
| `GET` | `/api/v1/channels/{id}/mention-candidates` | [INFERRED] | Yes | Query: `q=<prefix>`. Mention autocompletion. |
| `POST` | `/api/v1/messages/{id}/reactions` | [INFERRED] | Yes | Add emoji reaction. |
| `GET` | `/api/v1/dm/conversations` | [INFERRED] | Yes | List user direct message conversations. |
| `GET` | `/api/v1/dm/conversations/{id}/messages` | [INFERRED] | Yes | List messages in DM thread. |
| `POST` | `/api/v1/dm/conversations/{id}/messages` | [INFERRED] | Yes | Send DM message. |
| `POST` | `/api/v1/dm/conversations/{id}/read` | [INFERRED] | Yes | Mark DM conversation as read. |

---

## 7. Projects & Showcases

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/projects` | [CONFIRMED] | Optional | Observed live response: `items`, `nextCursor`, `facets`. |
| `POST` | `/api/v1/project-images/presign` | [INFERRED] | Yes | Presign upload URL for project screenshots. |
| `POST` | `/api/v1/project-images/{assetId}/complete` | [INFERRED] | Yes | Confirm upload completion. |
| `GET` | `/api/v1/users/{username}/projects` | [INFERRED] | Optional | Projects authored by user. |

---

## 8. Realtime WebSocket Architecture

### Connection Endpoint [INFERRED]
```
wss://vietnamlinuxfamily.net/ws/community
```
Connection uses HTTP upgrade with existing session cookies.

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

## 9. Voice Infrastructure [INFERRED]
- Control API: `GET /api/v1/voice/rooms`, `POST /api/v1/voice/rooms/{id}/join-token`.
- RTC Engine: LiveKit SFU running at `wss://voice.vietnamlinuxfamily.net`.
- Dart integration: `livekit_client` official Flutter SDK for room connection and microphone streams.
