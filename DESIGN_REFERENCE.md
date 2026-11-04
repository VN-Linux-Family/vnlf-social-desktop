# VNLF Design Reference: Native Client Visual Specification

Source of truth for all UI design tokens, components, adaptive breakpoints, and states. Captured directly from `vietnamlinuxfamily.net` production assets and runtime DOM inspection.

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

Reference screenshot captured from production session:
- Path: `assets/reference/reference_feed_desktop.png`
