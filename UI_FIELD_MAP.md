# UI Field Map: Design-System Components to API Contracts

Components rendering fields with NO confirmed API source come FIRST.

| Component | Fields rendered | API field | Status |
| :--- | :--- | :--- | :--- |
| `VnlfChatBubble` | `text`, `timestamp`, `reactions`, `stickerLabel`, `author` | `/api/v1/channels/{id}/messages` (`content`, `createdAt`, `reactions`, `sticker`, `author`) | **[UNKNOWN]** |
| `VnlfProjectPreviewCard` | `name`, `description`, `primaryLanguage`, `tag`, `stars`, `forks`, `rating` | `GET /api/v1/projects` item schema | **[UNKNOWN]** |
| `VnlfLeaderboardCard` | `rank`, `points`, `author.displayName`, `author.username` | `GET /api/v1/leaderboards` item schema | **[UNKNOWN]** |
| `VnlfCommentTree` | `content`, `author`, `score`, `timestamp`, `replyCount`, `replies` | `GET /api/v1/articles/{id}/comments` | **[INFERRED]** / **[UNKNOWN]** |
| `VnlfDistroBadgePill` | `distro` badge (`arch`, `debian`, `cachyos`, `nixos`, `fedora`) | `author.style.distroBadge` | **[INFERRED]** |
| `VnlfPixelBadge` | pixel avatar accessory frame | `author.style.pixelBadge` | **[INFERRED]** |
| `VnlfPostCard` | `id` | `items[].id` | **[CONFIRMED]** |
| `VnlfPostCard` | `excerpt` | `items[].excerpt` | **[CONFIRMED]** |
| `VnlfPostCard` | `voteScore` | `items[].voteScore` | **[CONFIRMED]** |
| `VnlfPostCard` | `commentCount` | `items[].commentCount` | **[CONFIRMED]** |
| `VnlfAuthorNameRow` | `displayName` | `items[].author.displayName` | **[CONFIRMED]** |
| `VnlfAuthorNameRow` | `username` | `items[].author.username` | **[CONFIRMED]** |
| `VnlfPostCard` (metadata) | `slug`, `publishedAt`, `bookmarkCount`, `author.avatarUrl` | `items[].slug`, `items[].publishedAt`, `items[].bookmarkCount`, `items[].author.avatarUrl` | **[CONFIRMED]** |
| `VnlfPostCard` (unobserved) | `contentJson`, `coverUrl`, `assets`, `tags`, `authorId`, `format`, `status`, `viewerVote` | unauthenticated feed items (trimmed in client fixture) | **[CONFIRMED]** (live) / **[UNKNOWN]** (local fixture) |
