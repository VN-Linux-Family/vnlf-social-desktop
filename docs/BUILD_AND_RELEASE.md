# Build and release

The source repository is private: `VN-Linux-Family/vnlf-social-desktop`.
Every build workflow stores its available binaries in a private GitHub release.
Incomplete builds remain drafts with an explicit missing-target inventory.
Only complete stable tags can be promoted to the separate public, release-only
`VN-Linux-Family/vnlf-social-app` repository. No source checkout is uploaded there.

## Local resource budget

This workstation has 8 GB RAM. Run one build or test command at a time:

```sh
tool/with_build_slot.sh flutter analyze
tool/with_build_slot.sh flutter test --concurrency=1
tool/with_build_slot.sh flutter build linux --release
```

The Linux/WSL guard holds a shared lock across worktrees, restricts the process
and its children to two CPUs, and lowers CPU/I/O priority. A second job fails
with exit 75 instead of running concurrently. Gradle is limited to a 1536 MB
heap, two workers, and no persistent daemon. Do not launch autonomous agents
that independently run full builds or tests. Gemini 4 Argon currently performs
read-only source review; Codex owns the single build/test slot.

## CI matrix

- Linux x64: `ubuntu-24.04`; Linux arm64: `ubuntu-24.04-arm`.
- Windows x64: `windows-2025`; Windows arm64: `windows-11-arm`.
- macOS x64: `macos-15-intel`; macOS arm64: `macos-15`.
- Android armv7, arm64, and x64: split APKs from one Linux build.

Desktop SDK ABI and macOS executable architecture are checked, so an emulated
x64 binary cannot silently be labelled arm64. Ubuntu is pinned because the prior
`ubuntu-latest` job migrated to Ubuntu 26 and rejected deprecated literal-operator
syntax in an older dependency's JSON header. Do not disable all compiler warnings
to mask that failure. Desktop matrix concurrency is capped at two hosted runners.

Quality checks run before packaging. Each build uses a numeric platform build
number and a separate semantic application version. Stable tags must match
`pubspec.yaml`; development builds include run/attempt and commit information.
`release.json` inventories target, size, and SHA-256 for each binary; `SHA256SUMS`
can be checked independently. Stable promotion requires all nine binaries.

## Required owner setup

The current GitHub identity has push access to the private source repository,
but GitHub rejected organization repository creation with HTTP 403. An organization
owner must create `VN-Linux-Family/vnlf-social-app` as public, initialized with only
a README. The application source remains private.

Configure the private source repository's Actions secrets:

- `PUBLIC_RELEASE_TOKEN`: a fine-grained token or equivalent app token with
  Contents write permission **only** for the public release repository. The
  private repository's normal `GITHUB_TOKEN` cannot publish to a different repo.
- `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`,
  `ANDROID_KEY_ALIAS`: the intended stable Android signing identity. Keep key
  material out of commits, command output, issue text, and release notes.

No account-wide CLI token is copied into Actions secrets. Stable Android builds
fail clearly without configured signing. Development CI can generate an explicit
short-lived development signature; those APKs are for internal testing and are
never promoted as stable releases. See `release-signing.md` for the previously
tracked key material and owner migration decision.

macOS archives are architecture-specific builds with code signing disabled.
They are not notarized distribution packages; Apple signing/notarization and
physical-device validation remain separate release requirements. Windows code
signing and all real-device platform checks are also unverified until performed.

## Updater

The app checks the public stable release API at launch at most once per day.
Settings provides an explicit check that bypasses the timing cache. Missing/private
repositories or no releases produce a visible unavailable state; network and parse
failures produce a retryable error. It compares semantic versions and selects only
the exact native platform/architecture asset. Downloads open externally; no
application binary is silently executed or installed.

## Validation state

The workflow is statically checked with actionlint. Version, artifact completeness,
checksum generation, build exclusivity, and CPU affinity have executable Python
tests. Updater comparisons, architecture selection, errors, caching, duplicate
checks, and manual unavailable-state UI have Flutter tests. These checks are not
proof that all hosted platform builds or real-device behavior pass; record those
actual results after the workflow runs. Do not call the app production-ready while
the remaining feature-parity matrix and signing/distribution requirements are open.
