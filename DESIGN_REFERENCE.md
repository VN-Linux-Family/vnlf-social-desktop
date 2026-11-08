# VNLF Design Reference: Native Client Visual Specification

Source of truth for all UI design tokens, components, adaptive breakpoints, and states. Captured directly from `vietnamlinuxfamily.net` production assets and runtime DOM inspection.

Native audit amendment — 2026-11-08: the requested native navigation tiers are
mobile **<840**, tablet **840 ≤ width <1181**, desktop **≥1181** logical pixels.
This supersedes the native breakpoint descriptions below; historical website
measurements remain evidence of the website at capture time. All native layout
decisions now use `VnlfViewportSize.fromWidth`, including fractional widths.
Material text slots use the explicit VNLF hierarchy, standard buttons use the
10px radius and a 48px minimum target, and dark accent backgrounds use dark
foregrounds with AA contrast. Native touch targets may exceed website controls.
The detailed findings, limitations and current captures are recorded in
`docs/ux-ui-audit-2026-11-08.md`.

Website parity amendment — 2026-11-08 (branch `fix/web-parity`): the
authoritative visual rules are the website's own `design-system/MASTER.md`,
docs 31 (unified 13px type) and docs 41 (lean phone shell) in the
`realfox99/vnlf-social` source at `ab23799`. Where this file disagrees, they win:

- **Type:** every visible text is 13px (body, controls, metadata, captions,
  headings, code). Hierarchy uses weight 700 for headings and weight 800 for
  page titles and numbers (tabular figures). The only larger text is the page
  title in the top bar: 13 + 5 = 18px, weight 800, line height 1.25. The 18/16/14/12/11px
  scale in §2 below is historical. `VnlfTypography.pageTitle` and
  `VnlfTypography.number` implement the two special roles.
- **Phone shell (<840):** one 54px top bar with padding `0 6px 0 16px`, the
  page title on the left and bare create / search / notification icons on the
  right. No logo, hamburger or avatar in the bar. The bottom bar is a floating
  56px pill (12px side inset, 6px above the safe area) with four icon-only
  destinations (Bảng tin, Khám phá, Tin nhắn, Voice) and the account avatar,
  which opens the sidebar as the menu. Projects and the other links live in
  that menu. Labels stay as semantic labels. Content gutter is 6px up to 520px
  wide and 8px up to 840px.
- **Tablet (840–1180):** the full sidebar at 220px, not a compact rail.
- Native keeps 48px minimum targets where the website uses 44px, and a back
  control in the phone top bar on detail routes.

---

## 1. Visual Contract & Philosophy

- **Zero Slop**: Replicate the exact typography, spacing, color contrast, and component semantics of `vietnamlinuxfamily.net`. Do not invent generic AI layouts or rounded-purple card aesthetics.
- **Vietnamese Language First**: All typography must cleanly render Vietnamese tone marks and diacritics without clipping or font fallbacks (`Tiếng Việt: ặ ữ ờ ẫ ệ`).
- **Platform Authenticity**: Match web layout while adapting navigation patterns natively (Bottom Navigation on mobile, Sidebar/Navigation Rail on desktop & tablet, platform-specific overscroll, keyboard navigation, and AA contrast).

---

## 2. Typography

Primary typeface family extracted from web production CSS: **Be Vietnam Pro**.

| Token | Size | Line Height | Weight | Usage |
| :--- | :--- | :--- | :--- | :--- |
| `text-h1` | 18px | 24px | 700 (Bold) | Main screen headings (e.g., "Bảng tin", "Khám phá") |
| `text-h2` | 16px | 22px | 700 (Bold) | Section headings (e.g., "Xếp hạng tuần", Project title) |
| `text-h3` | 14px | 20px | 600 (Semi-bold) | Sub-sections, card titles |
| `text-body` | 13px | 20.8px (1.6) | 400 (Regular) | Primary post content, comments, descriptions |
| `text-control` | 13px | 18px | 500 (Medium) | Button labels, tabs, form inputs, navigation items |
| `text-meta` | 12px | 16px | 400 (Regular) | Timestamps, usernames (`@handle`), counters, badges |
| `text-caption`| 11px | 14px | 500 (Medium) | Category tags, small indicator pills, footer text |

```dart
// Flutter TextTheme Definition
final vnlfTextTheme = TextTheme(
  headlineLarge: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.w700),
  headlineMedium: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700),
  titleMedium: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600),
  bodyMedium: GoogleFonts.beVietnamPro(fontSize: 13, height: 1.6, fontWeight: FontWeight.w400),
  labelLarge: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w500),
  labelSmall: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w400),
);
```

---

## 3. Color Tokens

Extracted directly from `:root` and `html.vnlf-dark`.

| Token Name | Light Theme Value | Dark Theme Value (`vnlf-dark`) | Semantic Role |
| :--- | :--- | :--- | :--- |
| `--bg` | `#f5f6f4` | `#0c0e0d` | Screen canvas background |
| `--paper` | `#ffffff` | `#141715` | Elevated surface / card canvas |
| `--surface` | `#ffffff` | `#151816` | Main content card & component surface |
| `--surface-soft` | `#f1f3f1` | `#1b1f1c` | Secondary / muted surface (tabs, chips, pill toggles) |
| `--ink` | `#141916` | `#eceeec` | Primary typography & high-contrast glyphs |
| `--muted` | `#5b655e` | `#9ba49d` | Secondary text, inactive tab labels, metadata |
| `--text-subtle` | `#656f68` | `#7d867f` | Timestamps, subtle hints, vote score neutral |
| `--line` | `#e2e6e2` | `#262b28` | Borders, dividers, subtle outlines |
| `--brand` | `#1d6b43` (Emerald) | `#7fcf9a` (Mint) | Primary brand accent, active tabs, upvote active |
| `--brand-strong` | `#10412a` | `#0e3a24` | Deep brand background, active container |
| `--brand-soft` | `#e5f1e9` | `#15291d` | Subtle brand tint for chips and badges |
| `--orange` | `#9a5b0c` | `#e0a458` | Warnings, voice status, attention pills |
| `--red` | `#c0392b` | `#f08a7e` | Downvote, destructive actions, errors |
| `--blue` | `#2f6e9e` | `#86bade` | Links, informational badges, Discord links |
| `--tier-partner`| `#8f5408` | `#e8b45c` | Partner / sponsor badge accent |
| `--rating-star` | `#d99a06` | `#f2c14e` | Rating stars, reputation indicators |

---

## 4. Radii, Shadows & Elevation

### Border Radii
- `--radius-sm`: `6.0` (Tags, small pills, code blocks, badge frames)
- `--radius-md`: `10.0` (Standard buttons, inputs, post action bars)
- `--radius-lg`: `14.0` (Cards, dialogue modals, sheet containers)
- `--radius-full`: `999.0` (Avatars, pill filters, voting capsules)

### Shadows
- Light Mode Subtle (`--shadow`): `0px 1px 2px rgba(16, 24, 20, 0.05)`
- Light Mode Elevated (`--shadow-hard`): `0px 12px 32px rgba(16, 24, 20, 0.12), 0px 2px 6px rgba(16, 24, 20, 0.06)`
- Dark Mode Subtle (`--shadow`): `0px 1px 2px rgba(0, 0, 0, 0.35)`
- Dark Mode Elevated (`--shadow-hard`): `0px 16px 40px rgba(0, 0, 0, 0.55), 0px 2px 8px rgba(0, 0, 0, 0.35)`

---

## 5. Responsive Layout & Breakpoints

Production media queries establish 3 core viewports:

```
  +---------------------------------------------------------------------------------+
  | Desktop (>= 1181px): 3 Columns (1280px container)                               |
  |  [ Left Sidebar 252px ]  |  [ Center Feed 717px ]  |  [ Right Sidebar 304px ]   |
  +---------------------------------------------------------------------------------+
  | Tablet (841px - 1180px): 2 Columns / Rail                                       |
  |  [ Nav Rail / Compact Sidebar ]  |  [ Feed & Main Surface ]                     |
  +---------------------------------------------------------------------------------+
  | Mobile (<= 840px): 1 Column                                                     |
  |  [ Top Header (64px) sticky ]                                                   |
  |  [ Full-Width Feed / List Content ]                                             |
  |  [ Bottom Navigation Bar (56px) sticky ]                                        |
  +---------------------------------------------------------------------------------+
```

- **Desktop (>= 1181px)**:
  - Left navigation sidebar width: `252px` fixed.
  - Center feed container width: `717px` max.
  - Right complementary column (Weekly leaderboard, legal links): `304px`.
- **Tablet (841px - 1180px)**:
  - Collapses right sidebar. Left sidebar switches to compact navigation rail.
- **Mobile (<= 840px)**:
  - Full-width feed.
  - Sticky Top Header: Height `64px`, horizontal padding `17px`, containing logo brand, search trigger, and notifications/profile.
  - Bottom Navigation Bar: Height `56px` + safe area, 5 destinations (`Bảng tin`, `Khám phá`, `Tin nhắn`, `Voice`, `Dự án`).
  - Drawer Navigation for secondary settings and links (`width: min(320px, 86vw)`).

---

## 6. Core Component Gallery & State Specs

### 1. App Shell & Navigation
- **Sidebar**:
  - Logo: "VNLF Social" with Penguin emblem.
  - Profile pill / Login trigger.
  - Main Navigation Links (`Bảng tin`, `Khám phá`, `Tin nhắn`, `Voice`, `Dự án`, `Hỗ trợ CaramOS`).
  - Badges: Count pill for pending items.
  - Community links: Facebook, Telegram, Discord.
  - Theme picker: 3-state segment toggle (`Sáng`, `Tối`, `Tự động`).
- **Feed Tab List**:
  - Tabs: `Mới nhất` (Latest), `Được chú ý` (Highlighted), `Article`, `Đang theo dõi` (Following).
  - Selected state: Brand green underline / pill background with `--ink` contrast.

### 2. Post & Article Card
- **Header**:
  - Author Avatar: 40x40 circle, optional custom animated frame (`matrix`, `neon`, `stars`).
  - Author Display Name with custom style (`nameColor` or `nameGradient`, `nameEffect` like rainbow/glitch/cursor).
  - Distro Badge pill (e.g. `caramos`, `cachyos`, `arch`, `debian`).
  - Handle (`@username`) and relative timestamp (e.g. `1 giờ`, `21 giờ`).
  - Overflow menu icon (`...`).
- **Body**:
  - Excerpt or markdown body with clean typography.
  - Code blocks with syntax highlighting and rounded border.
  - Media: Grid or single image preview with lightbox tap.
  - Embedded Link Card / Project Preview pill.
- **Interaction Bar (Footer)**:
  - **Vote Widget**: Capsule containing Upvote Arrow, Score Counter, Downvote Arrow.
    - Upvoted state: Upvote arrow colored `--brand`, score colored `--brand`.
    - Downvoted state: Downvote arrow colored `--red`, score colored `--red`.
  - **Comment Button**: Comment glyph with comment count.
  - **Share Button**: Share sheet trigger.
  - **Bookmark Button**: Bookmark glyph with filled state toggle.

### 3. Weekly Leaderboard (Xếp hạng tuần)
- Ranked list (Top 10): Rank number (1, 2, 3 highlighted), avatar with frame, stylized name, distro badge, points pill.

### 4. Direct Messages & Channel Chat
- Chat message bubble with author identity, timestamp, reaction pills, sticker rendering.

---

## 7. Captured Visual Reference

Reference screenshot captured from production session (stored outside repo per policy):
- Path: `/home/dat/vlf-reference/reference_feed_desktop.png` (Local host reference, read-only)


## Native/source parity capture — 2026-11-05

Guest captures used the native Linux ARM64 release build and an isolated website
browser profile at 1440×1000. They are kept outside Git under
`/tmp/vnlf-ui-review/` (`native-feed.png`, `web-feed.png`) because the public feed
contains real community content rather than synthetic fixtures. The website
capture has an Orca compositor artifact over its far-right edge; DOM measurements
were used to check geometry instead of treating that artifact as website UI.

Measured web social icons are the official `/social/facebook.webp`,
`telegram.webp`, and `discord.webp`, 22 px, grayscale with opacity 0.6 at rest.
The native sidebar now uses those assets and restores color on hover/focus.
These official brand assets remain flagged for an owner/license check before
redistribution, alongside the previously identified logo and Discord asset.

The website displays Following to guests and prompts for sign-in when needed.
It also renders POST heading nodes at the inherited 13 px body size and retains
empty paragraphs as line breaks without article paragraph margins. Native
regression checks now cover those observed differences in live configuration.

Open visual/feature differences: the feed composer prompt awaits the complete
native editor; the desktop header frame/placement and grouping between feed
cards still differ; full wardrobe effects, article layouts/captions, responsive
references, and actual video playback require further side-by-side verification.
The current captures are review evidence, not a claim of 1:1 parity.

## Native composer checkpoint — 2026-11-05

Native Linux release captures are `/tmp/vnlf-ui-review/native-composer-desktop.png`
(1440×1000) and `native-composer-mobile.png` (430×1000). They use an isolated
synthetic account, secure-storage fake and transport that cannot contact the
server. No owner data or production writes are involved. The build ran under a
3 GiB / 1.5 CPU cap; capture ran under a 1 GiB / 1 CPU cap and stopped its app/Xvfb
processes afterward. All 11 native Linux ARM64 binaries passed architecture checks.
No Flutter overflow/exception appeared; headless GTK emitted an ATK embedding
warning, so this capture is not proof of native assistive-technology behavior.

The original source-only editor sizing was superseded by live CSS inspection.
The deployed global text-scale rule forces 13px on ordinary elements, including
article headings and editor text; heading weight is globally 700. Reading the
component stylesheet alone gives incorrect 17/29/23px sizes. Native typography
now follows the computed live result: article body 13px/1.7, POST editor
13px/1.6, editor H2 13px/1.14 and H3 13px/1.2.

## Live article comparison — 2026-11-05

Reference public route: `/a/luanti-co-le-cai-ten-hoi-la-voi-da-so-nguoi-dung-binh-thuong`.
An isolated guest browser captured 1440×1000 and 430×1000 views. Its temporary
profile and tab were removed afterward. Computed styles confirm article body
13px/1.7, detail H2 13px/1.08/700, paragraph bottom margins 18px desktop/12px
at ≤840px, and H2 margins 19px/10px desktop, 12px/7px compact. Adjacent vertical
margins collapse to the greater value. Native regression checks measure this
actual paragraph-to-heading gap, including the mobile breakpoint.

Article details have their own reading layout, without the right sidebar:
Article/read-time metadata, title, excerpt, author, divider, document, actions
and comments. Desktop card max width is 780px with a 702px content column;
compact mode is flat with 16px side padding, a 54px feature header and a back
to feed control. The native article view now follows this structure. Legacy
attachment media remains visible alongside asset-backed inline images.

Web screenshots: `/tmp/vnlf-ui-review/web-article-desktop.png` and
`web-article-mobile.png`. The Orca desktop compositor capture repeats the left
sidebar at the far right; DOM inspection confirms this is a capture artifact.
Native Linux comparisons use a guest session and transport that rejects every
non-GET request. These captures are review evidence; advanced editor behavior,
image/caption spacing, the shared desktop shell and phone navigation still need
further comparison and device verification.

The first native article captures revealed excess whitespace from empty TipTap
paragraphs. A geometry test reproduced 124px between paragraphs where the live
compact article leaves 12px. Empty article paragraphs now collapse without text
line boxes; explicit POST line breaks remain intact. Native article captures are
`/tmp/vnlf-ui-review/native-article-desktop.png` and `native-article-mobile.png`.
Remaining visible differences include avatar decoration/initials, global shell
placement, phone navigation and the website's fixed comment dock. These are
tracked gaps, not claimed parity. Public content was read without a signed-in
session and no live writes were made.

The public article retains U+1F427 in its document, but this Linux host resolves
`fc-match emoji` to DejaVu Sans and the native capture omits that glyph. Emoji
fallback is therefore an observed distribution/UI gate, not missing server text.

Committed comparison evidence is in
[the November 6 visual review](docs/visual-audit/2026-11-06/README.md), including
source/native article screenshots and synthetic native composer screenshots.
Explicit editor block themes prevent package defaults from restoring larger
list/quote text or enlarged inline code in headings.
