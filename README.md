# VNLF Social

Native cross-platform Flutter client for [Vietnam Linux Family](https://vietnamlinuxfamily.net), in Vietnamese like the website. Official builds are published for Linux (`x64`, `arm64`), Android (`arm64-v8a`, `armeabi-v7a`, `x86_64`), Windows (`x64`, `arm64`), and macOS (`x64`, `arm64`) as documented in [the build and release guide](docs/BUILD_AND_RELEASE.md).

The app opens the community feed and provides native article/media rendering, threaded comments, a rich post/article composer with polls, community channels and direct messages with realtime WebSocket updates, LiveKit voice rooms, global search, weekly leaderboards, daily attendance check-in, member profiles, open-source project showcases, and in-app release update checks. Implementation and runtime verification details are tracked in [the parity audit](docs/source-parity-audit.md) and [`PLAN.md`](PLAN.md).

## Quickstart (Linux)

Use the Flutter version pinned in [`.github/workflows/ci.yml`](.github/workflows/ci.yml) (`3.47.9`). All local SDK commands run through `tool/with_build_slot.sh`, which serializes builds across worktrees and bounds CPU/memory usage:

```sh
tool/with_build_slot.sh flutter pub get
tool/with_build_slot.sh flutter run -d linux
```

For full verification before submitting changes:

```sh
tool/with_build_slot.sh dart format --output=none --set-exit-if-changed lib test tool
tool/with_build_slot.sh flutter analyze
tool/with_build_slot.sh dart run test/core/io_transport_headless_smoke.dart
tool/with_build_slot.sh flutter test --concurrency=1
python3 -m unittest discover -s test/tool -p '*_test.py'
```

## Runtime Requirements & Security

- **Linux desktop dependencies**: Linux release archives require system `GTK 3`, `libmpv` (ABI 2), `libepoxy`, and `libsecret-1` runtimes (`python3 tool/install_linux_dependencies.py`).
- **Secure session storage**: Persistent account sessions and encrypted draft recovery on Linux require an unlocked Secret Service provider (e.g., GNOME Keyring or KWallet). Credentials, cookies, tokens, and signing keys must never be stored in source files, fixtures, or logs.
- **Android in-place upgrades**: Official `.apk` releases are signed with the permanent VNLF release keystore and monotonic ABI-split `versionCode` values so updates install directly over previous releases without uninstalling.
- **macOS first launch**: macOS archives are signed ad hoc and not notarized. After unzipping, move the app to Applications and open it; if macOS blocks the first launch, choose System Settings > Privacy & Security > Open Anyway.

## Releases & Documentation

Official release binaries and `release.json` / `SHA256SUMS` manifests are published in [VN-Linux-Family/vnlf-social-desktop releases](https://github.com/VN-Linux-Family/vnlf-social-desktop/releases), which powers the in-app updater.

- **[Development Guide](docs/DEVELOPMENT.md)** — Setup, Clean Architecture layers, feature workflow, testing, and troubleshooting
- **[Contributing Guide](CONTRIBUTING.md)** — Contribution rules, layer contracts, and PR checklist
- **[Agent Operating Rules](AGENTS.md)** — Mandatory guidelines for coding agents and contributors
- **[Build & Release Guide](docs/BUILD_AND_RELEASE.md)** — CI matrix, signing, and release distribution
- **[API Contracts](API_NOTES.md)** & **[Design Reference](DESIGN_REFERENCE.md)** — Confirmed server endpoints and UI token specifications
- **[Documentation Index](docs/README.md)** — Full catalog of contracts, ADRs, plans, and audit reports

`assets/fonts/` bundles **Be Vietnam Pro**, distributed under the included SIL Open Font License 1.1 (`assets/fonts/OFL.txt`; see [`docs/ASSETS.md`](docs/ASSETS.md)).
