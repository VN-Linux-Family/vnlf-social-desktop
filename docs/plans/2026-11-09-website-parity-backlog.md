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

## Screens and features, in port order

### 1. Article detail and comments
- ⬜ Article/thread detail page like the website's `ArticleDetailView`. The app's `thread_screen` still uses the framed card.
- ⬜ Comments panel like `comments-panel.tsx`, including the drawer on phones.
- ⬜ Edit, delete and hide your own post from the "…" menu. Today the menu has only Save, Copy link and Report.
- ⬜ Share dialog: send in a message, Facebook, Telegram, Email. Today the app only copies the link.
- ⬜ GIF (KLIPY) and sticker pickers in comments.
- ⬜ Profile hover card on desktop (`profile-card.tsx`).

### 2. Sign-in pages
- ⬜ Login and register pages like the website's.
- ⬜ Forgot password and reset password.
- ⏸ Google and Discord sign-in. Native apps need a redirect the server accepts. Check what the server's OAuth flow allows before building it.
- ⬜ Linked accounts (`linked-accounts.tsx`).

### 3. Composer
- ⬜ Article editor parity (`article-editor.tsx`).
- ⬜ Stickers, GIFs, link previews and YouTube embeds.

### 4. Notifications
- ⬜ Full notifications page (`/notifications`). The app only has a sheet.
- ⬜ Notification sounds (`community-sounds.tsx`).

### 5. Profile
- ⬜ Profile page parity (`account-views.tsx`, `profile-cover.tsx`, `profile-house.tsx`).
- ⬜ Avatar and cover upload with cropping.
- ⬜ Followers and following lists. The app only shows the counts.
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
- ⬜ Explore page: intro, topics, featured projects, writer cards.
- ⬜ Tag pages (`/t/[tag]`) and "My articles" (`/my/articles`).
- ⬜ Stats and points history (`/stats`, `/stats/history`). The app has an Activity screen to compare.
- ⬜ Daily check-in card in the right rail.
- ⬜ Sticker packs (`/stickers`) and pixel icons (`/icons`).
- ⬜ Edit a submitted project (`/projects/[slug]/edit`).
- ⬜ CaramOS support tickets, Help, Community guidelines and Privacy. The app opens these on the website today.
- ⬜ Keyboard shortcuts (`keyboard-shortcuts.tsx`).

### 9. Push notifications when the app is closed
- ⏸ The server sends Web Push only to browser push services, so a closed app cannot be woken. Today the app gets notices while it runs, or in the background on Android when the user turns that on.
- ⬜ Prepare the client so that a server change can be plugged in: one place that turns a push payload into a local notification and a route, and a registration interface tied to the session. Do not call or invent an endpoint until the server has one.

## Not planned

- Admin pages (`/admin/**`): moderators keep using the website.
- The website's app-install page and its local demo pages (`/app`, `/a/local/*`, `/u/local/*`).

## Rules that apply to every item

- Call only endpoints the website's own client calls (`AGENTS.md` §2).
- Never retry a write automatically. Test writes on a test account only, and delete the test content afterwards.
- Phone touch targets stay 48dp even where the website's controls are smaller.
