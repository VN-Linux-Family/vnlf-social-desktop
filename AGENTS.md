# AGENTS.md: VLF Flutter client

Read before every task: PLAN.md, API_NOTES.md, DESIGN_REFERENCE.md (once they exist).

## Project
Native Flutter client for vietnamlinuxfamily.net, a closed-source community site with
no public API docs. Cross-platform (Linux and Android first-class; iOS, Windows, macOS,
web as feasible), lightweight, smooth, same look as the website.

## Working with a server we don't own
- Use only endpoints the site's own web client calls, with the owner's test account.
  Never bypass auth, rate limits or access controls. Never touch other users' private data.
- Be gentle: cache, debounce, back off, clear User-Agent, low request rates. Non-idempotent requests (POST, PUT, PATCH, DELETE) are never retried automatically.
- Read-only by default. Writes (post, comment, react) only when your card says so, on
  the named test account or thread.
- No credentials, cookies, tokens, emails or HAR files in the repo, logs or reports.
- Unknown API behavior: mark it unknown in API_NOTES.md and ask. Never invent endpoints.

## Architecture
- Feature-first clean architecture (presentation / domain / data), Riverpod, go_router,
  immutable models, sealed classes for state and errors.
- Anti-corruption layer: typed ApiClient with interceptors (auth/CSRF, retry, backoff),
  secure session storage, DTOs separate from domain models with mappers.
- Tolerant parsing: ignore unknown fields, null-safe defaults, failures become typed
  errors, never silent. HTML parsing only as a last resort, isolated in one adapter.
- Domain depends on repository interfaces only. A recorded-fixture fake server (port
  from env) powers dev, tests and CI.
- Minimal dependencies. Verify each on pub.dev. Add only through the pubspec owner.

## Performance
60fps (120 where supported), cold start under 2s on a mid-range Android, lean release
size. const widgets, slivers, resized and cached images, no rebuild storms (check in
DevTools).

## UX/UI
- Match the website. DESIGN_REFERENCE.md is the source of truth; compare screenshots
  side by side and fix differences.
- Adapt only what native requires: touch targets, bottom nav on phones, rail/sidebar on
  tablet and desktop, keyboard and hover, platform scrolling.
- Vietnamese diacritics must render correctly (test "Tiếng Việt: ặ ữ ờ ẫ ệ").
  Vietnamese default, English secondary.
- Motion 150-300ms, respects reduce-motion. AA contrast, semantic labels, text scaling.
- Rebuild in native widgets: no WebView wrapper, no verbatim copying of the site's
  source. Flag logos, fonts and icons that need a license check.

## Code quality (anti-slop)
- No lorem ipsum, TODO stubs, dead or commented-out code, unused dependencies.
- No generic AI aesthetics. Don't redesign what the site already defines.
- Small files, meaningful names, no god widgets.
- Unsure about an API, package or endpoint? Check the docs or ask. Don't guess.

## Git and worktrees
- Work only in your own worktree and branch. Touch only the paths your card owns.
  Never touch other worktrees or force-push shared branches.
- Small commits. Before reporting done: `flutter pub get`, `dart format`,
  `flutter analyze`, `flutter test`. For UI, run the app on Linux and attach a
  screenshot next to the reference.
- Report: what changed, commands run with results, what is unverified, open questions.
  Never claim something works without running it.
- Blocked or card unclear: ask the coordinator with the orchestration `ask` command.
  Don't guess or widen your scope.
