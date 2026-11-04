# UI Field Map: Design-System Components to API Contracts

This ledger maps each Flutter design-system component to the network data contracts documented in `API_NOTES.md`.

Confidence levels:
- **[CONFIRMED]**: Field name and data type observed directly in live unauthenticated HTTP responses.
- **[INFERRED]**: Field name or shape inferred from web bundle static analysis, not yet observed unauthenticated.
- **[UNKNOWN]**: No observed API source exists; field is either a local UI placeholder or the endpoint/payload schema remains unobserved.

Per architectural policy, **components rendering fields with no observed API source are listed first.** No feature code may depend on [UNKNOWN] fields.

---

## 1. Components Rendering Unconfirmed / Unknown Fields (No API Source)

### `VnlfChatBubble` ([vnlf_comment_tree.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_comment_tree.dart#L126))
Renders community and DM chat message entries.
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `text` | `content` / `body` | `/api/v1/channels/{id}/messages` | **[UNKNOWN]** | Message payload unobserved unauthenticated |
| `timestamp` | `createdAt` | `/api/v1/channels/{id}/messages` | **[UNKNOWN]** | Exact timestamp format unobserved |
| `reactions` | `reactions` (`Map<String, int>`) | `/api/v1/messages/{id}/reactions` | **[UNKNOWN]** | Reaction aggregation structure has NO API source |
| `stickerLabel` | `sticker` | `/api/v1/channels/{id}/messages` | **[UNKNOWN]** | Custom sticker attachments have NO API source |
| `author` | `author` | `/api/v1/channels/{id}/messages` | **[UNKNOWN]** | Chat sender schema unobserved |

### `VnlfProjectPreviewCard` ([vnlf_media_preview.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_media_preview.dart#L53))
Renders community project showcase cards in discover and post attachments.
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `name` | `name` / `title` | `GET /api/v1/projects` | **[UNKNOWN]** | Top-level `items` [CONFIRMED], item shape [UNKNOWN] |
| `description` | `description` / `summary` | `GET /api/v1/projects` | **[UNKNOWN]** | Project item field unobserved |
| `primaryLanguage` | `language` | `GET /api/v1/projects` | **[UNKNOWN]** | Programming language tag has NO API source |
| `tag` | `tags[0]` | `GET /api/v1/projects` | **[UNKNOWN]** | Project categorization has NO API source |
| `stars` | `starCount` / `stars` | `GET /api/v1/projects` | **[UNKNOWN]** | Star metric has NO API source |
| `forks` | `forkCount` / `forks` | `GET /api/v1/projects` | **[UNKNOWN]** | Fork metric has NO API source |
| `rating` | `rating` | `GET /api/v1/projects` | **[UNKNOWN]** | Rating float has NO API source |

### `VnlfLeaderboardCard` ([vnlf_leaderboard_card.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_leaderboard_card.dart#L12))
Renders the weekly ranking sidebar ("Xếp hạng tuần").
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `rank` | `rank` | `GET /api/v1/leaderboards` | **[UNKNOWN]** | Top-level `period`/`items` [CONFIRMED]; item schema [UNKNOWN] |
| `points` | `score` / `points` | `GET /api/v1/leaderboards` | **[UNKNOWN]** | Score metric field name unobserved |
| `author.displayName`| `user.displayName` | `GET /api/v1/leaderboards` | **[UNKNOWN]** | User reference shape inside leaderboard [UNKNOWN] |
| `author.username` | `user.username` | `GET /api/v1/leaderboards` | **[UNKNOWN]** | User reference shape inside leaderboard [UNKNOWN] |

### `VnlfCommentTree` ([vnlf_comment_tree.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_comment_tree.dart#L12))
Renders threaded comment hierarchy for article/thread detail screens.
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `body` | `content` / `contentHtml`| `GET /api/v1/articles/{id}/comments` | **[UNKNOWN]** | Comment endpoint and entity unobserved |
| `inlineCode` | `contentJson` AST block | `GET /api/v1/articles/{id}/comments` | **[UNKNOWN]** | Inline snippet attribute has NO API source |
| `relativeTime` | `createdAt` / `publishedAt`| `GET /api/v1/articles/{id}/comments` | **[UNKNOWN]** | Comment timestamp schema unobserved |
| `voteScore` | `voteScore` | `GET /api/v1/articles/{id}/comments` | **[UNKNOWN]** | Comment karma score unobserved |
| `viewerVote` | `viewerVote` | `GET /api/v1/articles/{id}/comments` | **[UNKNOWN]** | Viewer interaction state unobserved |
| `replies` | `replies` / `children` | `GET /api/v1/articles/{id}/comments` | **[UNKNOWN]** | Nesting structure (flat vs tree) unobserved |

### `VnlfAuthorNameRow` Badges ([vnlf_author_identity.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_author_identity.dart#L11))
Renders custom badges and styling next to user names.
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `hasTerminalBadge` | *(None)* | *(None)* | **[UNKNOWN]** | Synthetic local design flag; NO API source |
| `hasPartnerStar` | *(None)* | *(None)* | **[UNKNOWN]** | Synthetic local design flag; NO API source |
| `hasPixelBadge` | *(None)* | *(None)* | **[UNKNOWN]** | Synthetic local design flag; NO API source |
| `frame` | `author.style.frame.id` | `GET /api/v1/feed` | **[INFERRED]** | Bundle strings show `matrix`, `neon`; unverified live |
| `nameEffect` | `author.style.nameEffect` | `GET /api/v1/feed` | **[INFERRED]** | Bundle string literal `rainbow`, etc. |
| `distroBadge` | `author.style.distroBadge`| `GET /api/v1/feed` | **[INFERRED]** | Bundle string literals `arch`, `debian`, etc. |
| `nameColor` | `author.style.nameColor` | `GET /api/v1/feed` | **[INFERRED]** | Bundle schema field; unverified live |
| `nameGradient` | `author.style.nameGradient`| `GET /api/v1/feed` | **[INFERRED]** | Complex angle/stops object; unverified live |

---

## 2. Components Rendering Confirmed / Partially Confirmed Fields

### `VnlfPostCard` ([vnlf_post_card.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_post_card.dart#L64))
Renders primary feed article/post preview cards.
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `id` | `GET /api/v1/feed` | **[CONFIRMED]** | String UUID |
| `author.displayName`| `author.displayName` | `GET /api/v1/feed` | **[CONFIRMED]** | Unicode display name |
| `author.username` | `author.username` | `GET /api/v1/feed` | **[CONFIRMED]** | Unique handle |
| `paragraphs` | `excerpt` / `contentText`| `GET /api/v1/feed` | **[CONFIRMED]** | Feed excerpt [CONFIRMED]; full text in post detail |
| `voteScore` | `voteScore` | `GET /api/v1/feed` | **[CONFIRMED]** | Integer score |
| `commentCount` | `commentCount` | `GET /api/v1/feed` | **[CONFIRMED]** | Integer comment count |
| `title` | `title` | `GET /api/v1/feed` | **[CONFIRMED shape]** | Nullable string in post entity |
| `relativeTime` | `publishedAt` | `GET /api/v1/feed` | **[CONFIRMED shape]** | ISO 8601 string in post entity |
| `viewerVote` | `viewerVote` | `GET /api/v1/feed` | **[CONFIRMED shape]** | Integer vote status (1, 0, -1) |
| `isBookmarked` | `bookmarkCount` / viewer | `GET /api/v1/feed` | **[INFERRED]** | Bookmark status requires authenticated state |
| `tags` | `tags` | `GET /api/v1/feed` | **[CONFIRMED shape]** | Array of string tags |

### `VnlfVoteCapsule` & `VnlfPostInteractionBar` ([vnlf_vote_capsule.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_vote_capsule.dart#L13))
Renders karma voting pills and interaction buttons (share, comment count, bookmark).
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `voteScore` | `voteScore` | `GET /api/v1/feed` | **[CONFIRMED]** | Integer score |
| `viewerVote` | `viewerVote` | `GET /api/v1/feed` | **[CONFIRMED shape]** | Integer (-1, 0, 1) |
| `commentCount` | `commentCount` | `GET /api/v1/feed` | **[CONFIRMED]** | Integer count |
| `isBookmarked` | *(Authenticated state)* | `GET /api/v1/feed` | **[INFERRED]** | Inferred from bundle |

### `VnlfAvatar` ([vnlf_avatar.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_avatar.dart#L10))
Renders user avatar circle with vector fallback and ring frame.
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `displayName` (initial)| `author.displayName` | `GET /api/v1/feed` | **[CONFIRMED]** | Fallback monogram character |
| `avatarUrl` (runtime) | `author.avatarUrl` | `GET /api/v1/feed` | **[CONFIRMED shape]** | Network image URL |
| `avatarPreset` | *(None)* | *(None)* | **[UNKNOWN]** | Offline vector preset for demo/gallery only |
| `frame` | `author.style.frame` | `GET /api/v1/feed` | **[UNKNOWN]** | Single generic ring enabled; others quarantined |

### `VnlfCodeBlock` ([vnlf_code_block.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_code_block.dart#L10))
Renders syntax-highlighted code attachments.
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `code` | `contentJson` AST text | `GET /api/v1/feed` | **[CONFIRMED shape]** | ProseMirror/TipTap codeBlock node |
| `language` | `contentJson` AST lang | `GET /api/v1/feed` | **[CONFIRMED shape]** | Attribute `language` in AST codeBlock |

### `VnlfImagePlaceholder` ([vnlf_media_preview.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_media_preview.dart#L13))
Renders neutral offline placeholder for post media attachments.
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `aspectRatio` | `assets[].dimensions` | `GET /api/v1/feed` | **[INFERRED]** | Media metadata shape |
| `label` | *(None)* | *(None)* | **[UNKNOWN]** | UI-only offline placeholder text |

### Navigation Shells ([vnlf_shell.dart](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/vnlf_shell.dart), [shell/](file:///home/dat/orca/projects/vnlfsocialapp/lib/src/design_system/components/shell/))
Renders sidebar, rail, bottom nav bar, feed tabs, and theme selector.
| Rendered UI Field | Target API Field | API Endpoint | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| Feed filter tabs | `?type=latest\|trending\|article\|following` | `GET /api/v1/feed` | **[CONFIRMED]** | Query parameters confirmed |
| Nav destinations | Application routes | *(Client-side)* | **[CONFIRMED]** | Matches site web client routing |
| Theme options | `ThemeMode` | *(Client-side)* | **[CONFIRMED]** | Dark / Light / System |
