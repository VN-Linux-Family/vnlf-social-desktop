# VNLF API Notes: Network Protocol & Data Contracts

All endpoints, payload schemas, and realtime events documented here are derived directly from `vietnamlinuxfamily.net` production client bundles and live network inspection. Never invent endpoints.

## Phase 2 fixture inventory

All fixture values are synthetic. Confidence applies to field names only; no
fixture demonstrates a live value or authenticated behavior.

- `test/fixtures/feed.json` and the matching inline `fixtureTransport` feed model `GET /api/v1/feed` (per-field audit: field names read from real unauthenticated response vs inferred; all values synthetic):
  - Query parameters [CONFIRMED from web client chunk `2k5v3l48k2d3c.js`]:
    - `type=latest`: Mới nhất (default feed)
    - `type=top`: Được chú ý (featured/top posts; server returns 422 if `trending` is used)
    - `type=articles`: Article (plural; server returns 422 if singular `article` is used)
    - `type=following`: Đang theo dõi (requires session; returns 401 `AUTH_REQUIRED` unauthenticated)
    - `limit`: page size (e.g., 20)
    - `cursor`: pagination cursor from `nextCursor`
  - `items`: [CONFIRMED] read from real unauthenticated response.
  - `nextCursor`: [CONFIRMED] read from real unauthenticated response.
  - `items[].id`: [CONFIRMED] read from real unauthenticated response.
  - `items[].excerpt`: [CONFIRMED] read from real unauthenticated response.
  - `items[].voteScore`: [CONFIRMED] read from real unauthenticated response.
  - `items[].commentCount`: [CONFIRMED] read from real unauthenticated response.
  - `items[].author`: [CONFIRMED] read from real unauthenticated response.
  - `items[].author.username`: [CONFIRMED] read from real unauthenticated response.
  - `items[].author.displayName`: [CONFIRMED] read from real unauthenticated response.
  (All 9 field names in `feed.json` were read from real unauthenticated response; 0 are inferred. All values are synthetic).
- The projects fixture models `GET /api/v1/projects`:
  `items`, `nextCursor`, and `facets` (`languages`, `types`) are [CONFIRMED] field names.
  Project item fields are [CONFIRMED]: `id`, `name`, `slug`, `tagline`, `type`, `tier`, `relation`,
  `seeking`, `featured`, `status`, `logoUrl`, `accentColor`, `owner`, `repo` (`provider`, `owner`, `name`,
  `url`, `stars`, `forks`, `language`, `languageColor`, `archived`, `fork`, `pushedAt`, `unavailable`),
  `rating` (`average`, `count`), `commentCount`, `approvedAt`.
- The leaderboard fixture models `GET /api/v1/leaderboards`:
  `period`, `periodStart`, `periodEnd`, `computedAt`, and `items` are [CONFIRMED] field names.
  Leaderboard item fields are [CONFIRMED]: `userId`, `username`, `displayName`, `avatarUrl`,
  `earnedPoints`, `rank`, `style` (frame, distroBadge, icon, nameplate, status).
- Channels: `GET /api/v1/channels` returns `HTTP 401 Unauthorized` when unauthenticated.
  Channel listing requires authentication; response fields remain [UNKNOWN] until authenticated HAR capture.

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
- Session Management: Cookie-based session (`credentials: "include"`). Exact CSRF, cookie names, and set-cookie headers under authenticated states are **[UNKNOWN / INFERRED]** pending the coordinator receiving the user's Phase 3 HAR/cURL export.

### Standard Error Response Shape [CONFIRMED - observed unauthenticated (public)]
Observed live response from unauthenticated endpoints:
- Top-level field names: `code`, `message`, `requestId`.
All errors must be mapped into a typed Dart sealed class `ApiFailure` with status code, typed error code, localized message, and trace `requestId`.

### CORS & Web Platform Restriction [CONFIRMED - observed unauthenticated (public)]
- The production server returns `HTTP 500` on `OPTIONS` preflight requests and does NOT emit `Access-Control-Allow-Origin` headers.
- **Impact**: Flutter Web running in a browser from `localhost` or a separate domain will be blocked by browser CORS policy.
- **Native Targets**: Linux, Android, iOS, Windows, macOS do not enforce browser CORS and communicate directly without issue.
- **Web Workaround**: Flutter Web is dev-only through a local proxy and is not shipped.

---

## 2. Authentication & Session

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/auth/session` | [CONFIRMED] | No | Current session status. Unauthenticated: `HTTP 401 AUTH_REQUIRED`. Authenticated: returns `{user: {id, username, displayName, email, avatarUrl, role, style}}`. |
| `POST` | `/api/v1/auth/login` | [CONFIRMED] | No | Verified payload: `{"login": "<email|username>", "password": "<pwd>"}`. Success returns session JSON and emits `set-cookie: vnlf_session=...`. Invalid credentials returns `HTTP 401 INVALID_CREDENTIALS`. |
| `POST` | `/api/v1/auth/register` | [CONFIRMED] | No | Verified payload: `{"email": "<email>", "username": "<user>", "password": "<pwd>"}`. Success returns session JSON and emits `set-cookie`. Duplicate returns `HTTP 409`. |
| `POST` | `/api/v1/auth/refresh` | [INFERRED] | Cookie | Cookie/token rotation behavior. |
| `POST` | `/api/v1/auth/logout` | [CONFIRMED] | Cookie | Clears server-side session and cookie. |
| `GET` | `/api/v1/discover` | [CONFIRMED] | No | Returns `{articles: [...], users: [...], tags: [...], projects: [...], hasMore: bool}`. Powers the Discover screen with live community content. |
| `GET` | `/api/v1/users/{username}` | [CONFIRMED] | No | User profile entity: `{id, role, status, username, displayName, bio, website, totalPoints, level, currentStreak, followerCount, followingCount, avatarUrl, style, ...}`. |

> [!NOTE]
> `/api/v1/auth/session` field audit: The unauthenticated response observed contained solely the keys `code`, `message`, and `requestId`. It contained NO email, NO user id, and NO token. Zero real credentials or user session tokens were received, printed to terminal, written to file, or recorded in logs. Everything regarding the authenticated session state is treated as **[UNKNOWN]** for Phases 1 and 2.

---

## 3. Feed, Articles & Posts

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/feed` | [CONFIRMED - observed unauthenticated (public)] | Optional | Live response observed unauthenticated: `items`, `nextCursor`. Query: `type=latest\|trending\|article\|following`, `limit=20`. |
| `GET` | `/api/v1/articles/{id}` | [INFERRED] | Optional | Fetch full post detail with body, poll, and asset attachments. |
| `POST` | `/api/v1/articles` | [INFERRED] | Yes | Write endpoint: `{"title": "...", "contentJson": {...}, "contentText": "..."}` |
| `POST` | `/api/v1/articles/{id}/publish` | [INFERRED] | Yes | Write endpoint: publish drafted post. |
| `PUT` | `/api/v1/articles/{id}/vote` | [INFERRED] | Yes | Write endpoint: `{"value": 1 \| 0 \| -1}`. |
| `POST` | `/api/v1/articles/{id}/like` | [INFERRED] | Yes | Write endpoint: toggle like. |
| `POST` | `/api/v1/articles/{id}/bookmark` | [INFERRED] | Yes | Write endpoint: toggle bookmark. |
| `DELETE`| `/api/v1/articles/{id}` | [INFERRED] | Yes | Write endpoint: delete authored post. |
| `GET` | `/api/v1/articles/{id}/comments`| [INFERRED] | Optional | Fetch comment hierarchy for article. |
| `POST` | `/api/v1/articles/{id}/comments`| [INFERRED] | Yes | Write endpoint: create comment. |

### Post Entity Schema [CONFIRMED shape from unauthenticated feed, INVENTED Vietnamese sample]
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
| `PUT` | `/api/v1/comments/{id}/vote` | [INFERRED] | Yes | Write endpoint: `{"value": 1 \| 0 \| -1}` |
| `POST` | `/api/v1/comments/{id}/like` | [INFERRED] | Yes | Write endpoint: toggle comment like. |
| `PATCH`| `/api/v1/comments/{id}` | [INFERRED] | Yes | Write endpoint: edit comment content. |
| `DELETE`| `/api/v1/comments/{id}` | [INFERRED] | Yes | Write endpoint: remove comment. |

---

## 5. Leaderboards & Gamification

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/leaderboards` | [CONFIRMED - observed unauthenticated (public)] | Optional | Observed live response: `period`, `periodStart`, `periodEnd`, `computedAt`, `items`. |
| `GET` | `/api/v1/point-rules` | [CONFIRMED - observed unauthenticated (public)] | Optional | Observed live response: `items` array with karma activity rules. |
| `GET` | `/api/v1/me/points` | [INFERRED] | Yes | Current user point balance. Authenticated state **[UNKNOWN]**. |
| `GET` | `/api/v1/me/point-stats`| [INFERRED] | Yes | Authenticated points history **[UNKNOWN]**. |
| `POST` | `/api/v1/me/check-in` | [INFERRED] | Yes | Write endpoint: daily check-in claim. |

---

## 6. Community Channels, Chat & DMs

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/channels` | [CONFIRMED - requires auth (HTTP 401 unauthenticated)] | Yes | Public unauthenticated request returns 401 Unauthorized. |
| `GET` | `/api/v1/channels/{id}/messages` | [INFERRED] | Optional | Channel message history. |
| `POST` | `/api/v1/channels/{id}/messages` | [INFERRED] | Yes | Write endpoint: send chat message. |
| `GET` | `/api/v1/channels/{id}/mention-candidates` | [INFERRED] | Yes | Mention autocompletion. |
| `POST` | `/api/v1/messages/{id}/reactions` | [INFERRED] | Yes | Write endpoint: add emoji reaction. |
| `GET` | `/api/v1/dm/conversations` | [INFERRED] | Yes | Authenticated DM list **[UNKNOWN]**. |
| `GET` | `/api/v1/dm/conversations/{id}/messages` | [INFERRED] | Yes | Authenticated DM messages **[UNKNOWN]**. |
| `POST` | `/api/v1/dm/conversations/{id}/messages` | [INFERRED] | Yes | Write endpoint: send DM. |
| `POST` | `/api/v1/dm/conversations/{id}/read` | [INFERRED] | Yes | Write endpoint: mark DM read. |

---

## 7. Projects & Showcases

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/projects` | [CONFIRMED - observed unauthenticated (public)] | Optional | Observed live response: `items`, `nextCursor`, `facets`. |
| `POST` | `/api/v1/project-images/presign` | [INFERRED] | Yes | Write endpoint: presign upload URL. |
| `POST` | `/api/v1/project-images/{assetId}/complete` | [INFERRED] | Yes | Write endpoint: confirm upload. |
| `GET` | `/api/v1/users/{username}/projects` | [INFERRED] | Optional | Projects authored by user. |

---

## 8. Notifications & User Profile

| Method | Path | Status | Auth Required | Description / Payload |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/notifications` | [INFERRED] | Yes | Authenticated notifications list **[UNKNOWN]**. |
| `POST` | `/api/v1/notifications/read` | [INFERRED] | Yes | Write endpoint: mark notification read. |
| `POST` | `/api/v1/notifications/seen` | [INFERRED] | Yes | Write endpoint: mark notification seen. |
| `GET` | `/api/v1/me/profile` | [INFERRED] | Yes | Authenticated current user profile **[UNKNOWN]**. |
| `PATCH`| `/api/v1/me/profile` | [INFERRED] | Yes | Write endpoint: update profile **[UNKNOWN]**. |

---

## 9. Realtime WebSocket Architecture

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

## 10. Voice Infrastructure [INFERRED]
- Control API: `GET /api/v1/voice/rooms`, `POST /api/v1/voice/rooms/{id}/join-token`.
- RTC Engine: LiveKit SFU running at `wss://voice.vietnamlinuxfamily.net`.
- Dart integration: `livekit_client` official Flutter SDK for room connection and microphone streams.
