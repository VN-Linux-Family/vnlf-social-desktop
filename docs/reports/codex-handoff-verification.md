# Codex handoff verification — 2026-11-05

Worktree: `/home/dat/orca/workspaces/vnlfsocialapp/vnlf-codex-handoff`.
Branch: `luank3/vnlf-codex-handoff`, based on `0af7910`.

The project sheet now uses the project accent, neutral paper/soft-surface tokens,
contrast-safe button text, and scrolling/wrapping at narrow widths and enlarged
text. Theme choices persist through a separate non-secret preferences adapter.
The dependency owner added [shared_preferences 2.5.6](https://pub.dev/packages/shared_preferences),
verified on pub.dev; theme persistence works without the Linux keyring.

Settings, desktop sidebar, mobile drawer and tablet rail expose logout through
the shared auth controller. Cookie deletion is awaited, delayed responses cannot
restore a logged-out session or refill an invalidated cache, and failures retain
guest UI with actionable feedback. Public browsing continues when secure storage
is unavailable; session storage failures remain typed and visible in Settings.
Unchanged cookies are no longer written after every response.

Share copies the confirmed public `/a/{slug}` link from feed, thread, Discover
and profile cards, with success/failure feedback. Detail and Discover parsing now
preserve slugs. Missing slugs do not produce invented links. Thread padding no
longer applies the status-bar inset twice.

Author nameplates use smooth capsules and theme gradients; flair renders once
at 16×16 with the correct pixel filtering. Public profiles now use confirmed
profile/posts/comments/projects/guestbook reads, real available XP/level/streak/
follow stats, and matching public tabs. Unavailable stats display a dash. Only
the selected content section loads. Native screenshot review caught and fixed
overlap between the profile avatar and display name.

| Verification | Result |
| --- | --- |
| `flutter pub get` | Passed; one intentional direct dependency added |
| `dart format --output=none --set-exit-if-changed lib test` | Passed; 124 files, zero changes |
| `flutter analyze --no-pub` | Passed; no issues |
| `flutter test --no-pub --reporter expanded` | Passed; 202 tests, zero failures |
| `git diff --check` | Passed |
| `flutter run -d linux --no-pub --dart-define=VNLF_LIVE=false` | Built and launched the integrated Linux app under isolated Xvfb |
| Linux interaction | Opened projects/sheet, thread, profile and Settings; switched theme; logged out of a synthetic fixture session and confirmed guest UI |
| Preference relaunch | Dark, light and system restored across separate Linux processes; integration launch also used isolated XDG directories |

Regression coverage includes 48px status-bar insets, clipboard failures and
canonical URLs, sheet contrast and 320px/200% layouts, profile avatar clearance
at 1×/1.6× text, selected-tab loading, guestbook pagination/retry, auth/cache/cookie
races, missing keyring access, and persistence failure/recovery.

Screenshots stay outside Git. Open the [side-by-side comparison](/home/dat/vlf-reference/codex-handoff/comparison.html).

| Existing reference | Integrated native Linux screenshot |
| --- | --- |
| [Supplied project issue](/tmp/orca-paste-1793866162554-ff01077e-30a2-4e07-bee0-e6529a5abdca.png) | [Light sheet](/home/dat/vlf-reference/codex-handoff/project-sheet-light.png), [dark sheet](/home/dat/vlf-reference/codex-handoff/project-sheet-dark.png) |
| [Website feed reference](/home/dat/vlf-reference/reference_feed_desktop.png) | [Profile desktop](/home/dat/vlf-reference/codex-handoff/profile-desktop.png), [profile mobile](/home/dat/vlf-reference/codex-handoff/profile-mobile.png) |
| [Website feed reference](/home/dat/vlf-reference/reference_feed_desktop.png) | [Settings desktop](/home/dat/vlf-reference/codex-handoff/settings-desktop.png), [mobile dark](/home/dat/vlf-reference/codex-handoff/settings-mobile-dark.png), [after logout](/home/dat/vlf-reference/codex-handoff/settings-after-logout.png) |
| [Website feed reference](/home/dat/vlf-reference/reference_feed_desktop.png) | [Thread desktop](/home/dat/vlf-reference/codex-handoff/thread-desktop.png), [thread mobile](/home/dat/vlf-reference/codex-handoff/thread-mobile.png) |

[Dark theme after a fresh integrated app launch](/home/dat/vlf-reference/codex-handoff/dark-after-relaunch.png)
also confirms that the selected appearance survives process exit.

All native captures use synthetic offline data. Public website inspection used
anonymous reads only, as documented in `API_NOTES.md`. No production writes,
test-account login, real credentials, session cookies or response bodies were
stored in this work. The existing screenshot is the shared-shell reference;
exact page-wide profile/sheet parity cannot be established from it alone.

Physical Android/notch behavior, performance targets and secure session
persistence remain unverified. This host lacks Secret Service; local HTTP and
storage fakes verify cleanup and failure handling. Xvfb emitted EGL/ATK warnings,
but the native app rendered and completed the exercised flows. Profile content
beyond the first 50 posts/comments, owner-only controls/bookmarks, rich decor,
animated effects and exact distro/frame artwork remain outside this change;
the detailed audit boundaries are in `API_NOTES.md`. No coordinator decision is
required for the completed local scope.
