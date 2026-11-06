# CI timings and quota review — 2026-11-06

Policy: push source to both private repositories, execute Actions only in
`luank3/vnlfsocialapp`. Both registered organization workflows were confirmed
`disabled_manually`; build 42171842693 is completed/cancelled. The new workflow
definitions additionally guard every job by the exact personal repository name.

## Measured successful checkpoint

[Run 42163419636](https://github.com/VN-Linux-Family/vnlf-social-desktop/actions/runs/42163419636)
produced all nine binaries at be5e59e. Wall time: **25m56s**. Sum of allocated
job durations: **52m42s**, across ten jobs. These are different quantities.
The six desktop targets run at most two at a time; Android runs independently.

| Job | Execution | Rounded minutes | Estimated compute value |
| --- | ---: | ---: | ---: |
| Metadata | 0m06s | 1 | $0.006 |
| Quality | 4m08s | 5 | $0.030 |
| Android, three ABIs | 12m30s | 13 | $0.078 |
| Linux arm64 | 3m41s | 4 | $0.020 |
| Linux x64 | 3m38s | 4 | $0.024 |
| Windows arm64 | 7m02s | 8 | $0.080 |
| Windows x64 | 7m21s | 8 | $0.080 |
| macOS Intel | 10m07s | 11 | $0.682 |
| macOS arm64 | 3m34s | 4 | $0.248 |
| Private publication | 0m35s | 1 | $0.006 |
| Total | 52m42s | 59 | **$1.254** |

Estimates use per-job rounding and current
[GitHub standard runner rates](https://docs.github.com/en/billing/reference/actions-runner-pricing).
They are not an invoice: the legacy run timing API returned zero billable
milliseconds and cannot establish actual charges. The repository owner's
[included compute allowance](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
applies. macOS accounts for about 74% of this estimate. Queue time is excluded:
Intel macOS waited 10m52s after its job was created before a runner started.
Raising parallelism would reduce that wait, but would not reduce compute usage.

The Android build step itself used 11m36s. macOS Intel spent 1m46s preparing
Flutter and 7m38s compiling. Native ARM Linux/Windows bootstrap is necessary
because the pinned Flutter release has no matching packaged SDK archive for
these targets; replacing it with emulation would mislabel binary architecture.

## Confirmed failures and duplicated work

- Run 42166288373 lost 20m06s in Linux x64 dependency installation and exited
  124 before app compilation. Its other eight binaries were preserved in a
  private draft. This was a package download failure, not a Flutter compile error.
- Run 42171842693 exhausted three bounded download attempts in 15m21s. Its logs
  continued fetching `http://azure.archive.ubuntu.com` even after announcing
  other mirrors: the runner's `mirror+file:` mirror list had not been rewritten.
  A regression test reproduces the omission and now passes with the fix. This
  corrected x64 installer still needs a hosted verification.
- Both macOS jobs in that run had runner ID zero, no executed steps, and a
  billing annotation saying the job could not start because of account payments
  or a spending limit. Their displayed 15-minute intervals are not build time.
  The annotation does not establish which billing setting was responsible.
- Each of four recent feature updates started both push and PR checks; their
  push runs were then cancelled. PR-only feature checks remove this duplication.
- Multiple full matrices were explicitly dispatched during this audit. That
  repetition was excessive. Full packaging now requires an explicit `all`
  selection or a release tag; routine updates run only quality checks.

## Changes and remaining gates

All nine release targets and architecture verification remain required. Smaller
manual build sets avoid allocating unused Windows/macOS/Android runners. Three
day binary artifacts avoid retaining duplicate large downloads for fourteen
days; tiny recovery context is retained for 35 days and existing release assets
are preserved. No broad local CLI token is copied
to Actions, no paid runner is selected, and no full matrix is started to verify
this policy change. Default-branch recovery and organization asset mirroring
still need the documented repository setup. Neither CI success nor binary
compilation establishes feature parity, signing readiness or device behavior.

Validation: 425 Flutter tests, 37 release-tool checks, plain Dart HTTP/auth
fixture smoke, analysis, formatting and actionlint pass. The normal Linux ARM64
release builds and all eleven native binaries pass architecture verification.
Read-only review found and prompted fixes for separate source/destination token
scope, manual tag target selection, and retained metadata on failed-job reruns.
