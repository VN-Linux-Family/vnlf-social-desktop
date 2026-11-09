# Native routes verification

Verified on 2026-11-04 in the `luank3/vnlf-design-argon` worktree.

## Changes

- `/thread/:id` loads the post repository, renders full text, author, date, tags,
  local offline votes/bookmarks, a sample comment tree and local comment composer.
  Missing offline posts use the labeled sample article; missing live posts show
  an unavailable state. Desktop includes the author card and weekly leaderboard.
- `/profile/:id` resolves a public username or user ID from loaded feed/rankings,
  displays identity, avatar styling and available stats, and switches between
  posts, projects, and wardrobe. Unknown members show an unavailable state.
- `/settings` changes the app-wide Riverpod theme and locale and displays the
  app version and actual transport mode. Feed and feature headers link to it.
- `/discover` searches and filters articles locally, displays projects through
  the discover repository, and opens contributor profiles.
- Feed bodies and comment buttons push the matching thread; author names and
  avatars push their username profile. Back buttons preserve the pushed stack,
  with a feed fallback for direct entry.
- A flexible sidebar utility label fixes overflow with enlarged text.

## Commands and results

| Command | Result |
| --- | --- |
| `flutter pub get` | Passed; no dependency changes |
| `dart format --output=none --set-exit-if-changed` on changed Dart paths | Passed; 25 files unchanged |
| `flutter analyze --no-pub` | Passed; zero issues |
| `flutter test --no-pub --reporter expanded` | Passed; all 132 tests |
| `git diff --check` | Passed |
| `GDK_BACKEND=x11 LANG=vi_VN.UTF-8 flutter run -d linux --no-pub` | Built and launched successfully |

The ten new widget tests cover full-text rendering, offline comments, feed body /
comment / author navigation, profile tabs, profile retry recovery, theme and
locale changes in the real app, discovery search / tags / contributor navigation,
and all four routes at 390, 900 and 1440px with 1.6× text. Existing shell tests now
expect native screens on implemented routes and retain placeholder assertions for
the remaining routes.

The thread timestamp overflow was reproduced on phones with enlarged text and
fixed by separating the date from the compact card time. The desktop utility
label overflow and cached profile-error retry were also reproduced by tests
before their fixes.

## Linux screenshots and reference

All captures contain synthetic offline data and remain local in the ignored
`artifacts/native-screens/` directory. The website reference
remains outside the repository at
`/home/dat/vlf-reference/reference_feed_desktop.png`, as required by project policy.
Only a website feed reference exists; exact visual matching for these four
individual screens cannot be established from that reference alone.

| Website reference | Native screenshots |
| --- | --- |
| [Original feed reference](/home/dat/vlf-reference/reference_feed_desktop.png) | [Thread](artifacts/native-screens/thread-linux.png), [Profile](artifacts/native-screens/profile-linux.png), [Settings](artifacts/native-screens/settings-linux.png), [Discover](artifacts/native-screens/discover-linux.png) |

![Native thread on Linux](artifacts/native-screens/thread-linux.png)

![Native profile on Linux](artifacts/native-screens/profile-linux.png)

![Native settings on Linux](artifacts/native-screens/settings-linux.png)

![Native discover on Linux](artifacts/native-screens/discover-linux.png)

The shared green palette, typeface, sidebar geometry and card components follow
the existing design system. Vietnamese diacritics render in the actual Linux
window. The Linux environment emitted graphics-driver / ATK warnings but rendered
the application; these captures were obtained from its X11 window because Orca's
accessibility provider did not enumerate it.

## Limits and open integration work

- No live service requests or writes were made. No endpoints or packages were
  added. Live detail/profile/comments contracts remain unverified.
- The existing post repository resolves only the first feed page; it does not
  implement a verified detail endpoint. Offline fallback content is labeled.
- Profile biography and follower count are synthetic only for the labeled sample
  profile. Other profiles show available public projections and `—` for unknown
  counts. Karma is the available weekly leaderboard score, not an asserted
  lifetime total.
- Comments, votes and bookmarks are local offline demonstrations; comments reset
  when the thread is left. Live comments and write controls remain unavailable.
- Theme and locale last for the application session; persistence was not added.
- Android/device profiling and 60/120fps measurements were not performed.
- A nested review worker was refused by Orca's depth limit with no side effects;
  the implementation diff was reviewed locally before committing.
