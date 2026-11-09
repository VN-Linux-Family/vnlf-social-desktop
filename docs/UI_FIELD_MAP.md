# UI Field Map: Design-System Components to API Contracts

Components rendering fields with NO confirmed API source come FIRST.

| Component | Fields rendered | API field | Status |
| :--- | :--- | :--- | :--- |
| `VnlfChatBubble` | `text`, `timestamp`, `reactions`, `stickerLabel`, `author` | `/api/v1/channels/{id}/messages` | **[UNKNOWN]** (requires auth, `/api/v1/channels` returns 401) |
| `VnlfCommentTree` | `content`, `author`, `score`, `timestamp`, `replyCount`, `replies` | `/api/v1/posts/{id}/comments` / `/api/v1/articles/{id}/comments` | **[UNKNOWN]** |
| `VnlfDistroBadgePill` | `distro` badge (`arch`, `debian`, `cachyos`, `nixos`, `fedora`) | `items[].author.style.distroBadge` (string or null) | **[CONFIRMED]** |
| `VnlfPixelBadge` | avatar accessory frame / icon | `items[].author.style.icon.url` / `items[].author.style.frame` | **[CONFIRMED]** |
| `VnlfProjectPreviewCard` | `name`, `description`, `primaryLanguage`, `tag`, `stars`, `forks`, `rating` | `GET /api/v1/projects`: `items[].name`, `items[].tagline`, `items[].repo.language`, `items[].type`, `items[].repo.stars`, `items[].repo.forks`, `items[].rating.average` | **[CONFIRMED]** |
| `VnlfLeaderboardCard` | `rank`, `earnedPoints`, `author.displayName`, `author.username`, `author.avatarUrl`, `author.style` | `GET /api/v1/leaderboards`: `items[].rank`, `items[].earnedPoints`, `items[].displayName`, `items[].username`, `items[].avatarUrl`, `items[].style` | **[CONFIRMED]** |
| `VnlfPostCard` | `id` | `items[].id` | **[CONFIRMED]** |
| `VnlfPostCard` | `title` | `items[].title` (string or null) | **[CONFIRMED]** |
| `VnlfPostCard` | `excerpt` | `items[].excerpt` | **[CONFIRMED]** |
| `VnlfPostCard` | `contentText` | `items[].contentText` (string) | **[CONFIRMED]** |
| `VnlfPostCard` | `contentHtml` | `items[].contentHtml` (string) | **[CONFIRMED]** |
| `VnlfPostCard` | `contentJson` | `items[].contentJson` (TipTap rich text object) | **[CONFIRMED]** |
| `VnlfPostCard` | `voteScore` | `items[].voteScore` (number) | **[CONFIRMED]** |
| `VnlfPostCard` | `commentCount` | `items[].commentCount` (number) | **[CONFIRMED]** |
| `VnlfPostCard` | `bookmarkCount` | `items[].bookmarkCount` (number) | **[CONFIRMED]** |
| `VnlfPostCard` | `likeCount` | `items[].likeCount` (number) | **[CONFIRMED]** |
| `VnlfPostCard` | `tags` | `items[].tags` (array of string) | **[CONFIRMED]** |
| `VnlfPostCard` | `tagSlugs` | `items[].tagSlugs` (array of string) | **[CONFIRMED]** |
| `VnlfPostCard` | `publishedAt` | `items[].publishedAt` (ISO-8601 string) | **[CONFIRMED]** |
| `VnlfPostCard` | `updatedAt` | `items[].updatedAt` (ISO-8601 string) | **[CONFIRMED]** |
| `VnlfPostCard` | `coverUrl` | `items[].coverUrl` (string or null) | **[CONFIRMED]** |
| `VnlfPostCard` | `format` | `items[].format` (string, e.g. "post") | **[CONFIRMED]** |
| `VnlfPostCard` | `status` | `items[].status` (string, e.g. "published") | **[CONFIRMED]** |
| `VnlfPostCard` | `viewerVote` | `items[].viewerVote` (number: -1, 0, 1) | **[CONFIRMED]** |
| `VnlfPostCard` | `viewerBookmarked` | `items[].viewerBookmarked` (boolean) | **[CONFIRMED]** |
| `VnlfPostCard` | `viewerLiked` | `items[].viewerLiked` (boolean) | **[CONFIRMED]** |
| `VnlfPostCard` | `canEdit` | `items[].canEdit` (boolean) | **[CONFIRMED]** |
| `VnlfPostCard` | `attachments` | `items[].attachments` (array of `{id, url, mime, size, width, height, alt}`) | **[CONFIRMED]** |
| `VnlfPostCard` | `assets` | `items[].assets` (array of `{id, url, mime, size, width, height}`) | **[CONFIRMED]** |
| `VnlfAuthorNameRow` | `displayName` | `items[].author.displayName` | **[CONFIRMED]** |
| `VnlfAuthorNameRow` | `username` | `items[].author.username` | **[CONFIRMED]** |
| `VnlfAuthorNameRow` | `role` | `items[].author.role` (string) | **[CONFIRMED]** |
| `VnlfAuthorNameRow` | `avatarUrl` | `items[].author.avatarUrl` (string) | **[CONFIRMED]** |
| `VnlfAuthorNameRow` | `style` | `items[].author.style` (frame, icon, distroBadge, nameplate, status) | **[CONFIRMED]** |
