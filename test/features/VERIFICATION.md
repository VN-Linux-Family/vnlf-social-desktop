# Feed, leaderboard, and projects verification

Implemented on `luank3/vnlf-design-argon` for task `task_0eea5de7c278`.

- `/` uses a Riverpod `FeedNotifier` consuming `feedRepositoryProvider`.
- Feed tabs send `latest`, `trending` (Được chú ý), and `article` through the repository.
- Pull-to-refresh bypasses cached responses; cursor pagination appends posts, removes duplicate IDs, stops on a missing/repeated cursor, and preserves posts after pagination failures.
- Loading, empty, and error states use the existing post card variants. A shared shimmer animation respects reduced motion.
- `/leaderboard` and the desktop feed sidebar share `leaderboardRepositoryProvider` data and `VnlfLeaderboardCard`; “Xem tất cả” opens the full route.
- `/projects` uses `projectsRepositoryProvider` and `VnlfProjectPreviewCard` with repository language, stars, and forks.
- Author mapping carries avatar URLs, distro badges, frame colors, and nameplate identity/colors. Fixture mode uses initials and makes no image requests; live image loading requires the existing explicit `VNLF_LIVE` opt-in.
- Fixture clients use zero throttling and independent request queues to avoid timers or queues surviving widget-test clocks.
- The coordinator approved changes to `lib/src/domain/repositories.dart` and `lib/src/data/fixture_repositories.dart`: optional feed `type`, explicit `refresh`, and populated synthetic offline leaderboard/project data.

| Command | Result |
| --- | --- |
| `flutter pub get` | Passed; no dependency changes |
| `dart format lib/src/features lib/src/app lib/src/design_system lib/src/data/fixture_repositories.dart lib/src/domain/repositories.dart test` | Passed |
| `flutter analyze` | No issues found |
| `flutter test --reporter expanded` | All 122 tests passed |
| `git diff --check` | Passed |
| `flutter run -d linux` with temporary native development headers | Built and launched; native rendered screenshot captured |

Fourteen feature tests cover fixture rendering at 390/900/1440 pixels, sidebar navigation, project statistics, loading/empty/error/retry states, feed types, pull-to-refresh before cache expiry, infinite scrolling, pagination failures, and stale results after tab changes or refresh.

## Linux screenshot beside the reference

| Production reference (read-only, outside Git) | Running Linux app (1280 × 720, synthetic fixtures) |
| --- | --- |
| ![Production feed reference](/home/dat/vlf-reference/reference_feed_desktop.png) | ![Native Linux feed](artifacts/feed-linux.png) |

Native screenshot: `/home/dat/orca/workspaces/vnlfsocialapp/vnlf-design-argon/test/features/artifacts/feed-linux.png`.
The PNG remains local under the repository's existing image exclusion policy.
Orca's desktop capture provider did not expose the Wayland app window; the screenshot was captured from the running Linux app through Flutter's inspector screenshot extension.

The app preserves the existing three-column layout, Vietnamese font, cards, and adaptive navigation. The comparison uses synthetic text and initials; production media, exact custom frame artwork, and nameplate textures remain unverified. The current desktop header/brand treatment also retains the existing design-system differences from the website reference.

Linux initially lacked `libsecret-1` development metadata. The Ubuntu development packages `libsecret-1-dev`, `libgcrypt20-dev`, and `libgpg-error-dev` were unpacked under `/tmp/vnlf-argon-native-deps`, with temporary pkg-config prefixes and links to the already installed runtime libraries; no system packages or project dependencies were changed. The interrupted initial CMake configuration also required resetting the generated `CMAKE_INSTALL_PREFIX` to the worktree's `build/linux/arm64/debug/bundle`. The successful run used `PKG_CONFIG_PATH=/tmp/vnlf-argon-native-deps/root/usr/lib/aarch64-linux-gnu/pkgconfig flutter run -d linux`.

The Linux environment emitted Mesa/ATK diagnostics but produced the rendered app screenshot without Flutter runtime exceptions. Live server behavior, Android/device performance, and production media were not exercised. No live server requests or write operations were made; no API-contract questions remain for this card.
