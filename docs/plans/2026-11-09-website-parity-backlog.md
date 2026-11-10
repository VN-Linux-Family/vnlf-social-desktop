# Website parity backlog

On 2026-11-09 the owner asked to port the whole website (`../vnlf-social/apps/web`) into the app: its pages, features, UI and copy. This file tracks what is left. Update it in the PR that changes an item.

Status: ✅ done · 🔄 in progress · ⬜ to do · ⏸ waits for the server.

## How each screen is ported

1. Extract a spec from the website source: CSS in `apps/web/app/*.css`, components in `apps/web/components/social/**`, copy in `vi.ts`.
2. Rebuild the screen natively. Take copy from `vi.dart` (the website's keys) and icons from `VnlfIcon`.
3. Before calling an endpoint, find it in the website's client code and record it in `API_NOTES.md`.
4. Capture the website and the app at 390, 900 and 1440px and compare them side by side.
5. Delete the `vi.app.<feature>` copy that the website's keys replace.

## Done

| Item | PR |
| --- | --- |
| Vietnamese only; copy generated from `vi.ts` | #5 |
| Shell (sidebar, rail, phone bar) and home feed | #6 |
| Every user-visible string in `vi.dart`; no language flags | #7 |
| Post and article detail pages, post menu, share dialog, link previews, author view counts | #8 |
| Comments panel and media gallery like the website's | #9 |
| Sticker and GIF picker in comments | #11 |
| Sign-in, registration and forgot-password pages | #11 |

## Screens and features, in port order

### 1. Article detail and comments
- ✅ Post and article detail pages like the website's `ArticleDetailView` (#8).
- ✅ Comments panel like `comments-panel.tsx`: count header, rows, depth-one replies, stickers and GIFs, a composer above the phone bar (#9). Still to do: the desktop composer staying in view while scrolling, and `?comment=` links.
- ✅ The website's "…" menu everywhere a post appears: save, copy link, edit and delete for the author, hide and report for everyone else (#8).
- ✅ Share dialog: message, Facebook, Telegram, Email and copy (#8).
- ✅ Sticker and GIF picker in comments: KLIPY search, saved stickers, installed packs, recent stickers (#11). The pack dialog and sticker pages still open the website.
- ✅ Profile card like `profile-card.tsx` (#16): with a mouse it opens 450 ms over a name or avatar and closes 250 ms after leaving both; on touch a 500 ms press opens it as a sheet. It shows the profile's theme, cover, level, status, bio, links, follow, "Nhắn tin" and "Xem trang cá nhân". Post cards, comments, post and article authors and guestbook entries have it; @mentions inside text do not yet.

### 2. Sign-in pages
- ✅ Login and register pages like the website's `AuthView` (#11).
- ✅ Forgot password: sends the reset email and counts down before resending (#11). The emailed reset link opens the website, which sets the new password; the app has no deep links yet.
- ⏸ Google and Discord sign-in. Native apps need a redirect the server accepts. Check what the server's OAuth flow allows before building it.
- ⬜ Linked accounts (`linked-accounts.tsx`).

### 3. Composer
- ⬜ Article editor parity (`article-editor.tsx`).
- ⬜ Stickers and GIFs in the article composer. Comments have them (#11); link previews and YouTube cards already show under posts (#8).

### 4. Notifications
- ✅ The website's notification center (#13): the `/notifications` page and the bell's popover at every width, with day groups, filters, the kind select, badges by kind, the unseen count on the bell and the website's copy.
- ✅ Message chimes like `community-sounds.tsx` (#14): the website's two notes for a direct message or a channel message from someone else while the app is in front, once per message and at most once every 750 ms, following "Âm báo tin nhắn" in Settings. A channel rings only while it is open, because the app joins a channel's realtime topic only then; the website joins every active channel.
- ⬜ The voice room chimes (someone joins, a message in the room's chat) come with the voice room port; `assets/sounds/voice-join.wav` is ready.

### 5. Profile
- ✅ Profile header like `ProfileView` (#15): the profile theme's colours and canvas, the cover, the avatar over its edge, links and the Discord account, the status, follow or edit, the "…" menu, the stats and the tabs with their counts.
- ⬜ Still on the profile page: the moving cover, wallpaper, music, the machine card, the visit counter, the "Đã lưu" tab, and the profile and decor reports.
- ⬜ Avatar and cover upload with cropping.
- ✅ Followers and following lists like `PeopleDialog` (#16): the two counts open them, with a follow button on each row.
- ⬜ Profile music, "my machine" card, personal links, visit counter.
- ⬜ Customize hub (`/settings/decor`) and wardrobe: frames, name effects, nameplates, pets, entrance. The app already draws frames and name effects but cannot pick them.

### 6. Settings
- ⬜ Split into the website's pages: display, notifications, privacy, profile, security.

### 7. Messages, channels and voice
- ⬜ Create a channel, manage its members, channel settings.
- ⬜ Search inside a channel. Direct messages already have search and a media sheet.
- ⬜ Link previews in chat.
- ⬜ Floating chat window on desktop (`floating-messages.tsx`).
- ⬜ Voice: text chat in the room, per-person volume, noise suppression.

### 8. Other pages
- ✅ Explore page: intro, topics, featured projects, writer cards (#17). The website's project card is ported (`ProjectCard`); topics open the tag page (#20).
- ✅ Tag pages (`/t/[tag]`) and "Bài viết của bạn" (`/my/articles`) (#20). Khám phá's topics, search topics, `/t/` links and the profile's "Quản lý bài viết" open them. ⬜ Hashtags in post text and comments still need to link to their topic.
- ⬜ Stats and points history (`/stats`, `/stats/history`). The app has an Activity screen to compare.
- ✅ The website's right rail (`RightRail`): "XP của bạn" with the level, the next goal and the streak (`GET /api/v1/me/point-stats?period=week`), the busiest open voice room, and the week's top three, each only when it has something to show (#19).
- ⬜ Sticker packs (`/stickers`) and pixel icons (`/icons`).
- ⬜ Edit a submitted project (`/projects/[slug]/edit`).
- ⬜ CaramOS support tickets, Help, Community guidelines and Privacy. The app opens these on the website today.
- ⬜ Keyboard shortcuts (`keyboard-shortcuts.tsx`).
- ⬜ The "Góp ý & báo lỗi" launcher (`feedback-widget.tsx`, `feedback-entry.tsx`): a tab on the right edge on desktop, and entries in the sidebar, on phones and on the sign-in page.

### 9. Push notifications when the app is closed
- ⏸ The server sends Web Push only to browser push services, so a closed app cannot be woken. Today the app gets notices while it runs, or in the background on Android when the user turns that on.
- ✅ The client is ready for a server change (#12): `PushMessage` and `PushMessagePresenter` read and show the worker's payload like `push-sw.js`, `PushRegistration` follows `push-settings.tsx` with a `PushDistributor` in place of the browser's `PushManager`, and `docs/contracts/native-push.md` lists what is left on each side.
- ✅ A `PushDistributor` on the `unifiedpush` package (6.1.0, Android), headless delivery while the app is closed, and endpoint replacement (#18). Settings has the "Thông báo đẩy" card (#18). ⬜ The permission prompt, once the server accepts distributor endpoints.

## Not planned

- Admin pages (`/admin/**`): moderators keep using the website.
- The website's app-install page and its local demo pages (`/app`, `/a/local/*`, `/u/local/*`).

## Rules that apply to every item

- Call only endpoints the website's own client calls (`AGENTS.md` §2).
- Never retry a write automatically. Test writes on a test account only, and delete the test content afterwards.
- Phone touch targets stay 48dp even where the website's controls are smaller.
