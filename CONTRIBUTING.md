# Contributing to VNLF Social

Thank you for contributing to **VNLF Social**, the native cross-platform Flutter client for [Vietnam Linux Family (`vietnamlinuxfamily.net`)](https://vietnamlinuxfamily.net).

Every human contributor and automated coding agent must follow the rules in this document alongside [`AGENTS.md`](AGENTS.md), [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md), [`API_NOTES.md`](API_NOTES.md), and [`DESIGN_REFERENCE.md`](DESIGN_REFERENCE.md).

---

## 1. Core Principles

1. **Respect the Community Server**:
   - Use only endpoints confirmed in [`API_NOTES.md`](API_NOTES.md) that the official web client calls.
   - Never bypass authentication, rate limits, or access controls.
   - Never automatically retry non-idempotent requests (`POST`, `PUT`, `PATCH`, `DELETE`).
   - Develop and run automated tests against local synthetic fixtures (`test/fixtures/`) and the local fake server (`test/fixtures/fake_server.dart`).
2. **Zero Credentials or Private Data in Git**:
   - Never commit credentials, session cookies, tokens, real user emails, private messages, `.har` captures, `.env` files, or Android signing material (`*.keystore`, `*.jks`, `key.properties`).
3. **Strict Clean Architecture**:
   - Maintain strict separation between `domain` (pure Dart models and repository contracts), `data` (tolerant DTOs, `FieldReader`, and transport adapters), `presentation` (Riverpod controllers and Flutter widgets), and `design_system` (tokens, shells, and reusable components).
   - Architectural layer boundaries and directory layout are enforced automatically by `test/core/project_layout_contract_test.dart`.
4. **Website Visual Parity & Native Polish**:
   - Match the visual language documented in [`DESIGN_REFERENCE.md`](DESIGN_REFERENCE.md).
   - Ship Vietnamese only (like the website), dark and light themes, responsive layout tiers (`< 840px`, `840–1180px`, `>= 1181px`), WCAG AA contrast (`>= 4.5:1`), `200%` text scaling, and reduced motion.
5. **Anti-Slop Policy**:
   - No `TODO` stubs (treated as compile errors by `analysis_options.yaml`), no placeholder text, no dead or commented-out code, and no unverified claims.

---

## 2. Project Layout & File Placement Rules

Keep the repository clean and predictable:

| Path | Allowed Contents | Forbidden Contents |
| :--- | :--- | :--- |
| Root (`/`) | `README.md`, `CONTRIBUTING.md`, `AGENTS.md`, `PLAN.md`, `API_NOTES.md`, `DESIGN_REFERENCE.md`, `pubspec.*`, `analysis_options.yaml`, `flutter_launcher_icons.yaml` | Scratch files, ad-hoc audit reports, screenshots, `.env`, `.har`, signing keys |
| `lib/src/domain/` & `lib/src/features/<slice>/domain/` | Pure Dart immutable models, sealed states/errors, repository interfaces, domain logic | Flutter UI imports (`material.dart`, `widgets.dart`), DTOs, `ApiClient` transport, Riverpod widgets |
| `lib/src/data/` & `lib/src/features/<slice>/data/` | Repository implementations, DTOs, tolerant JSON parsers (`FieldReader`), local storage stores | Flutter widget imports, presentation controllers, `design_system` imports |
| `lib/src/features/<slice>/presentation/` | Screens, sub-widgets, Riverpod `Notifier`/`AsyncNotifier` controllers, UI state models | Direct raw socket/HTTP calls bypassing repositories |
| `lib/src/design_system/` | Design tokens (`tokens/`), shared models (`models/`), shell & atomic widgets (`components/`) | Imports from `features/`, `data/`, `app/`, or `gallery/` |
| `lib/src/core/` | `ApiClient`, `IoApiTransport`, `SessionStorage`, `PreferencesStorage`, platform services | Imports from `features/`, `app/`, or `gallery/` |
| `test/features/<slice>/` | Feature unit and widget tests (`*_test.dart`) grouped by feature slice directory | Loose files in `test/features/`, markdown reports, unignored screenshots |
| `test/core/`, `test/design_system/`, `test/tool/` | Core transport/contract tests, design system tests, Python tooling unit tests (`*_test.py`) | Production credentials or live network dependencies in unit tests |
| `docs/` | Developer guides (`DEVELOPMENT.md`, `BUILD_AND_RELEASE.md`), `contracts/`, `decisions/`, `plans/`, `reports/`, `visual-audit/` | Unsanitized user data or credentials |

---

## 3. Coding Standards

### Static Analysis & Formatting
- `analysis_options.yaml` enables `strict-casts`, `strict-inference`, `strict-raw-types`, and promotes `missing_return`, `missing_required_param`, `dead_code`, `unused_import`, `unused_local_variable`, `unused_element`, `unused_field`, `invalid_use_of_protected_member`, and `todo` to **hard errors**.
- Use `package:vnlfsocialapp/...` imports when importing across top-level modules (`avoid_relative_lib_imports` is enforced).
- Never use `print()`; surface errors through typed domain states or structured diagnostics that never leak sensitive payloads.
- Format all Dart files with `dart format` before committing.

### Tolerant Parsing & Error Handling
- Server responses can evolve without notice. Parse JSON defensively through `FieldReader` (`lib/src/data/field_reader.dart`), ignore unknown fields, and convert missing required structures into typed `ApiException` or sealed failure states.
- Never swallow exceptions silently (`catch (_) {}`) or display optimistic write success before receiving a confirmed server acknowledgment (`200`/`201`/`204` or `{ "ok": true }`).

### Session & Account Isolation
- Bind authenticated requests and WebSocket streams to the current `ApiSessionScope` / `RequestIdentity`.
- When a user logs out or switches accounts, cancel or ignore stale in-flight responses and clear user-scoped caches and draft stores.

### Copy (`lib/src/i18n/vi.dart`)
- The app is Vietnamese only, like the website. Every user-facing string lives in `lib/src/i18n/vi.dart`, which mirrors the website's `packages/i18n/src/vi.ts` key for key (`vi.pageLogin.dangNhapVnlfSocial` in both). Fill `{name}` placeholders with `format()`.
- Do not hand-edit the generated website regions; regenerate them from a website checkout:
  ```sh
  python3 tool/sync_vi_strings.py --web ../vnlf-social
  ```
  Copy that exists only in the native app goes in `ViApp` at the end of the file.
- Test Vietnamese diacritics (`Tiếng Việt: ặ ữ ờ ẫ ệ`) and ensure UTF-16 length formatters (`Utf16LengthFormatter`) never split surrogate pairs or emoji clusters.

---

## 4. Dependency Policy

- Keep dependencies minimal. Every direct dependency in `pubspec.yaml` must be:
  1. Verified on [pub.dev](https://pub.dev) for maintenance status, platform support, and open-source license compatibility.
  2. Checked against native build requirements on Linux (`x64`/`arm64`), Android (`armv7`/`arm64`/`x64`), Windows (`x64`/`arm64`), and macOS (`x64`/`arm64`).
  3. Recorded in [`PLAN.md`](PLAN.md) and, if it bundles fonts/icons/media, in [`docs/ASSETS.md`](docs/ASSETS.md).

---

## 5. Git & Pull Request Workflow

1. **Branching & Commits**:
   - Create focused topic branches from `main` (e.g., `feat/<slice>-...`, `fix/<slice>-...`, `docs/...`).
   - Use clear conventional commit messages:
     - `feat(<scope>): ...`
     - `fix(<scope>): ...`
     - `refactor(<scope>): ...`
     - `test(<scope>): ...`
     - `docs(<scope>): ...`
     - `chore(<scope>): ...`
   - Never force-push `main` or rewrite published release tags.

2. **Resource-Guarded Verification (Mandatory Before Every PR)**:
   Run all verification commands sequentially through `tool/with_build_slot.sh`:
   ```sh
   tool/with_build_slot.sh flutter pub get
   tool/with_build_slot.sh dart format --output=none --set-exit-if-changed lib test tool
   tool/with_build_slot.sh flutter analyze
   tool/with_build_slot.sh dart run test/core/io_transport_headless_smoke.dart
   tool/with_build_slot.sh flutter test --concurrency=1
   python3 -m unittest discover -s test/tool -p '*_test.py'
   ```

3. **UI Changes & Visual Verification**:
   - Any change to `lib/src/design_system/` or `lib/src/features/**/presentation/` must include widget tests covering:
     - Loading, empty, error, and populated states.
     - Responsive widths (`390px` phone, `900px` tablet, `1440px` desktop).
     - Enlarged text scaling (`1.6x`–`2.0x`) without layout overflow.
     - Dark and light theme contrast (`>= 4.5:1`).
   - Run the UX regression suite (`tool/with_build_slot.sh flutter test --concurrency=1 test/ux_audit_test.dart test/ux_accent_contrast_test.dart test/ux_detail_content_test.dart`) before submitting UI changes.
