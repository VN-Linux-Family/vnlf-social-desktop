# Native community screens verification

Dispatch: `task_8925246707f1` / `ctx_194c0ddab186`.

Implemented native `/channels`, `/voice` and `/search` routes in `createMainRouter()` and removed their placeholder builders. Channels include the five requested directories, topics and counts, sender identities, reaction pills, per-channel message history and drafts, instant local sends, a mobile channel picker and the desktop active-member sidebar. Voice includes all three rooms, participant badges and speaking indicators, join/leave, mute, deafen and screen-share preview controls in a persistent control bar.

Search indexes loaded fixture posts, projects and member identities, with query clearing, scope filters, popular tags, empty results and navigation to matches. Feed and thread share Riverpod vote/bookmark state, including neutral toggles and the two-point change between opposite votes. Project language chips filter the repository results; leaderboard periods change both displayed scores and ordering while the feed sidebar continues to show weekly rankings.

## Verification

| Command/check | Result |
| --- | --- |
| `flutter pub get` | Passed; dependencies unchanged. |
| `dart format --output=none --set-exit-if-changed` on all 21 changed Dart files | Passed; zero formatting changes. |
| `flutter analyze --no-pub` | Passed; **No issues found**. |
| `flutter test --no-pub --reporter expanded` | Passed; **148 tests**, zero failures. |
| `git diff --check` | Passed. |
| `flutter run -d linux --route=/channels` under isolated Xvfb | Linux debug build and app startup passed; navigated through the shell to capture the screens. |

The new `test/features/community_channels_voice_search_test.dart` covers channel switching and retained local sends, voice join/mute/deafen/share/leave, search queries/scopes/tags/clearing, shared feed/thread reactions, project filtering and leaderboard order. It also checks the three new screens at 390, 900 and 1440 pixels with 1.3× text scaling. Existing shell tests now check the actual native screens and both Vietnamese and English titles; their previous placeholder expectations were obsolete.

## Screenshots and design comparison

Screenshots stay outside Git under `/home/dat/vlf-reference/community-native/`, in line with the repository's image ignore policy. The read-only production reference remains at `/home/dat/vlf-reference/reference_feed_desktop.png`.

Open the [local side-by-side comparison](/home/dat/vlf-reference/community-native/comparison.html) to inspect the reference beside the Linux screenshots. Only a feed reference exists; channel/voice/search-specific parity cannot be established from it. Shared shell widths, typography, green accents, borders and spacing were visually checked, and the filter chips were corrected to use the site's green tokens. Common chat reactions use native icons so they remain visible without a system emoji font.

| Existing website reference | Native channels, 1440 × 1000 |
| --- | --- |
| ![Website feed reference](/home/dat/vlf-reference/reference_feed_desktop.png) | ![Native channels](/home/dat/vlf-reference/community-native/channels-desktop.png) |

Additional captures: [voice room](/home/dat/vlf-reference/community-native/voice-desktop.png), [joined voice room](/home/dat/vlf-reference/community-native/voice-joined-desktop.png), [search](/home/dat/vlf-reference/community-native/search-desktop.png), [search results](/home/dat/vlf-reference/community-native/search-results-desktop.png), [mobile search](/home/dat/vlf-reference/community-native/search-mobile.png), [mobile chat](/home/dat/vlf-reference/community-native/channels-mobile.png).

## Boundaries and remaining verification

- Chat messages and post reactions are session-local. No live write endpoints, authenticated sessions, WebSocket contracts or production data were fabricated or exercised.
- Voice controls preview local room state; they do not capture a microphone, transmit audio, connect to LiveKit or share a screen. The screen explains this boundary before joining.
- Monthly/all-time rankings are explicitly synthetic offline examples. No unverified period query is sent to the live leaderboard endpoint.
- Search operates on loaded fixture content, rather than assuming an undocumented server-wide search endpoint.
- Android/device audio, production authentication/realtime behavior, performance targets and page-specific screenshot parity remain unverified. Xvfb logged EGL/ATK environment warnings; rendering and navigation completed without Flutter exceptions.
- A separate read-only review dispatch was refused by Orca with `nested_worker_depth_exceeded` and `effectsApplied: false`; final source and diff review ran in the implementation terminal instead.

No additional coordinator input is required for this local fixture scope. Production integration still needs the authenticated contracts and test-account authorization already identified in `API_NOTES.md`.
