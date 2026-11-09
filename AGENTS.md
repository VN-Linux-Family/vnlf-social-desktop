# AGENTS.md: VNLF Flutter Client Operating Rules

Read before every task: [`PLAN.md`](PLAN.md), [`API_NOTES.md`](API_NOTES.md), [`DESIGN_REFERENCE.md`](DESIGN_REFERENCE.md), [`CONTRIBUTING.md`](CONTRIBUTING.md), and [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

## 1. Project Overview
Native cross-platform Flutter client for [`vietnamlinuxfamily.net`](https://vietnamlinuxfamily.net), a closed-source community platform with no public API documentation.
- **First-class targets**: Linux (`x64`, `arm64`) and Android (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
- **Additional native release targets**: Windows (`x64`, `arm64`) and macOS (`x64`, `arm64`).
- **Design & UX mandate**: Lightweight, smooth (60/120fps), and visually faithful to the community website (`DESIGN_REFERENCE.md`).

---

## 2. Working With a Server We Do Not Own
- **Observed endpoints only**: Call only endpoints that the site's own web client calls and that are documented as `[CONFIRMED]` in [`API_NOTES.md`](API_NOTES.md). Never invent routes, query parameters, payload fields, or WebSocket event names.
- **Unknown contract handling**: If an API payload, status code, or edge case is unconfirmed, mark it `[UNKNOWN]` in [`API_NOTES.md`](API_NOTES.md) and ask. Never fabricate fallback success states.
- **Be gentle on transport**:
  - Cache GET responses where appropriate, debounce user-driven queries (e.g., search, typing indicators), back off with jitter on transient `429`/`503` responses, and send a clear User-Agent (`x-vnlf-client`).
  - **Non-idempotent requests (`POST`, `PUT`, `PATCH`, `DELETE`) are NEVER retried automatically.** Failed writes must surface an explicit error state and preserve the user's draft and idempotency key (`clientCommentId`, `clientSubmissionId`, draft version lock) for manual retry.
- **Read-only by default**: Live write operations (posting, commenting, voting, reacting, DM sending, profile editing) are permitted only when explicitly authorized on the designated test account or sandbox thread, and all temporary test content must be deleted and verified (`404` / `REMOVED`) before task completion.
- **Strict secret & data hygiene**:
  - Never commit or log credentials, session cookies, tokens, private messages, emails, `.har` captures, `.env` files, or signing keys (`*.keystore`, `*.jks`, `key.properties`).
  - All repository fixtures (`test/fixtures/`) must use synthetic Vietnamese content and invented identities while preserving exact production JSON schemas.
- **Environment separation**:
  - Production server (`https://vietnamlinuxfamily.net`) is the default endpoint.
  - Development server (`http://localhost:3001`) is restricted to non-release builds (`!kReleaseMode`). The server selector UI in Settings must never be exposed in release builds.

---

## 3. Canonical Repository Layout & Layer Boundaries
The project layout is enforced by automated contract tests (`test/core/project_layout_contract_test.dart`).

```text
.
├── AGENTS.md                 # Agent operating rules (this file)
├── CONTRIBUTING.md           # Contribution & PR governance rules
├── PLAN.md                   # Master architecture plan & verification state
├── API_NOTES.md              # Confirmed server REST/WebSocket contracts
├── DESIGN_REFERENCE.md       # Design tokens, breakpoints & UI parity spec
├── README.md                 # Project overview & quickstart
├── analysis_options.yaml     # Strict Dart/Flutter static analysis rules
├── lib/
│   ├── main.dart             # App entrypoint & runtime bootstrap
│   └── src/
│       ├── app/              # GoRouter configuration & root Riverpod providers
│       ├── core/             # Transport (ApiClient, IoApiTransport), storage, guards
│       ├── domain/           # Shared pure-Dart domain models & repository interfaces
│       ├── data/             # Shared DTOs, tolerant FieldReader, fixture & live adapters
│       ├── design_system/    # Tokens, theme, responsive shell & atomic UI components
│       ├── features/         # Feature-first slices (<slice>/{domain,data,presentation})
│       ├── i18n/             # vi.dart: every user-facing string, mirroring the website's vi.ts
│       └── gallery/          # Isolated design-system workbench & component catalog
├── test/
│   ├── core/                 # Transport, parser, session isolation & layout contract tests
│   ├── design_system/        # Design system component & platform surface tests
│   ├── features/<slice>/     # Feature unit & widget tests mirroring lib/src/features/<slice>
│   ├── fixtures/             # Synthetic JSON fixtures & standalone fake server
│   ├── tool/                 # Python unit tests (*_test.py) for build/release scripts
│   └── *_test.dart           # App shell, routing, locale & UX/UI audit regression suites
├── tool/                     # Build-slot lock, CI packaging, signing & UX capture scripts
└── docs/                     # Developer guides, ADRs, contracts, plans & audit reports
```

### Enforced Architectural Dependency Rules
1. **Domain Layer Purity (`lib/src/domain/**`, `lib/src/features/**/domain/**`)**:
   - Pure Dart value types, entities, repository interfaces, and domain services only.
   - Must **never** import `presentation/`, `data/`, `design_system/`, `gallery/`, `app/`, or Flutter widget libraries (`package:flutter/material.dart`, `package:flutter/widgets.dart`, `package:flutter/cupertino.dart`).
2. **Data & Anti-Corruption Layer (`lib/src/data/**`, `lib/src/features/**/data/**`)**:
   - Implements domain repository interfaces, DTOs, tolerant JSON parsing (`FieldReader`), and transport bindings.
   - Must **never** import `presentation/`, `design_system/`, `gallery/`, `app/`, or Flutter UI libraries.
   - Tolerant parsing is mandatory: ignore unknown server fields, provide null-safe defaults, convert malformed payloads into typed `ApiException` / domain errors, and never fail silently.
3. **Design System Isolation (`lib/src/design_system/**`)**:
   - Reusable tokens, shells, and UI primitives only.
   - Must **never** import `features/`, `data/`, `app/`, or `gallery/`.
4. **Core Infrastructure Isolation (`lib/src/core/**`)**:
   - Low-level HTTP/WebSocket transport, session storage, and platform services.
   - Must **never** import `features/`, `app/`, or `gallery/`.
5. **Account & Session Isolation (`ApiSessionScope` / `RequestIdentity`)**:
   - Every authenticated request, cache entry, draft recovery store, and realtime WebSocket subscription must be bound to the active account/session identity.
   - Logout or account change must immediately invalidate in-flight requests, close active realtime sockets, and clear account-scoped caches so stale responses never leak across sessions.
6. **File Placement Discipline**:
   - Never place `.md` reports or scratch notes inside `lib/` or `test/`. All documentation, plans, contracts, ADRs, and verification reports belong under [`docs/`](docs/README.md).
   - Every feature test under `test/features/` must reside in its corresponding `test/features/<slice>/` directory.

---

## 4. UX/UI, Accessibility & Performance Standards
- **Website visual parity**: [`DESIGN_REFERENCE.md`](DESIGN_REFERENCE.md) is the source of truth. Never introduce generic AI card styles, unrequested gradients, or decorative chrome that deviates from the website.
- **Responsive layout tiers**:
  - Compact (`< 840px`): Single-column mobile view with bottom navigation bar; detail routes hide global navigation chrome.
  - Medium (`840px – 1180px`): Tablet navigation rail + content pane.
  - Expanded (`>= 1181px`): Desktop three-column layout (`240px` left navigation sidebar, fluid center column, `304px` right complementary rail).
- **Typography & localization**:
  - `Be Vietnam Pro` bundled in `assets/fonts/` (SIL OFL-1.1).
  - The app is Vietnamese only, like the website. Every user-visible string lives in `lib/src/i18n/vi.dart`, which mirrors the website's `packages/i18n/src/vi.ts` key for key; regenerate the website part with `python3 tool/sync_vi_strings.py` and add native-only copy to `ViApp`.
  - Verify Vietnamese diacritics rendering (`Tiếng Việt: ặ ữ ờ ẫ ệ`) and up to `200%` text scaling (`1.6x–2.0x`) without layout overflow at `320px`, `390px`, `900px`, and `1440px` widths.
- **Accessibility & motion**:
  - Minimum WCAG AA contrast (`>= 4.5:1` for text and interactive controls in both dark and light modes).
  - Minimum `48×48dp` interactive touch targets on mobile.
  - Motion duration `150–300ms`, honoring system/user reduced-motion preferences (`MotionPreferenceScope`).
- **Performance**:
  - Target 60fps (120fps on capable displays), `< 2s` cold start on mid-range Android, `const` widget constructors where possible, lazy sliver lists, bounded image caches, and zero rebuild storms.
- **Native widgets & asset licensing**:
  - No `WebView` wrappers. At the project owner's request (2026-11-09) the website's components, UI and copy are ported into native Flutter code, screen by screen.
  - Record all third-party fonts, icons, and brand assets in [`docs/ASSETS.md`](docs/ASSETS.md).

---

## 5. Code Quality & Dependency Governance (Anti-Slop)
- **Zero slop**: No `TODO` stubs (`todo: error` is enforced by the analyzer), no placeholder lorem ipsum, no dead or commented-out code, and no silent catch blocks (`catch (_) {}`).
- **Focused files**: Keep widgets, controllers, and repositories small, cohesive, and well-named. Split complex screens into focused sub-widgets.
- **Minimal dependencies**: Do not add packages to `pubspec.yaml` without explicit approval, verification on `pub.dev`, license review, and native build validation across Linux, Android, Windows, and macOS.

---

## 6. Local Resource Budget, Git & Verification Workflow
- **Worktree & branch discipline**:
  - Work only in your assigned worktree and branch. Touch only the paths owned by your task.
  - Make small, atomic commits with clear conventional commit messages (`feat:`, `fix:`, `docs:`, `test:`, `chore:`, `refactor:`). Never force-push shared branches (`main`).
- **Single build slot (`tool/with_build_slot.sh`)**:
  - To protect workstation memory and CPU budgets, **all** local `flutter`, `dart`, `gradle`, and build/test commands must run one at a time through `tool/with_build_slot.sh` with `--concurrency=1` for tests.
- **Mandatory pre-completion verification**:
  Before reporting any task complete or opening/merging a PR, run and verify all of the following:
  ```sh
  tool/with_build_slot.sh flutter pub get
  tool/with_build_slot.sh dart format --output=none --set-exit-if-changed lib test tool
  tool/with_build_slot.sh flutter analyze
  tool/with_build_slot.sh dart run test/core/io_transport_headless_smoke.dart
  tool/with_build_slot.sh flutter test --concurrency=1
  python3 -m unittest discover -s test/tool -p '*_test.py'
  ```
- **Honest reporting**: Report exactly what changed, every command executed with its real output, what was verified on live/device vs synthetic fixtures, and any remaining open questions. Never claim a feature or build works without running it.
