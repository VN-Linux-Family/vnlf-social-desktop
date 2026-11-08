# VNLF Social

Native Flutter client for [Vietnam Linux Family](https://vietnamlinuxfamily.net),
with Vietnamese and English interfaces. Linux, Android, macOS and Windows builds
are produced for the architectures listed in [the build guide](docs/BUILD_AND_RELEASE.md).

The app opens the community feed. It includes native article/media rendering,
threaded comments, a rich post/article editor, channels and direct messages,
voice rooms, search, rankings, profiles, projects and update checks. Implementation
and runtime coverage vary by feature; [the parity audit](docs/source-parity-audit.md)
records the remaining work. Stable production readiness has not been established.

Use the Flutter revision pinned in the CI workflow. From a Linux checkout:

```sh
tool/with_build_slot.sh flutter pub get
tool/with_build_slot.sh flutter run -d linux
```

The shared build slot limits local SDK work to two CPUs and prevents concurrent
build/test jobs across project worktrees. Stop the development app when finished.
For verification:

```sh
tool/with_build_slot.sh flutter analyze
tool/with_build_slot.sh flutter test --concurrency=1
```

Linux archives require the system GTK 3, libmpv (ABI 2), epoxy and libsecret
runtimes; they are not self-contained installers. Secure sessions also require an available, unlocked Secret Service
keyring in the user's desktop session, such as GNOME Keyring or a compatible
KWallet service. A headless session without that service cannot verify account
sign-in or secure draft recovery. The app reports storage failures; credentials
must never be saved in source, fixtures or logs.

macOS archives are signed ad hoc and not notarized. After unzipping, move the
app to Applications and open it; if macOS blocks the first launch, choose
System Settings > Privacy & Security > Open Anyway.

Release binaries and community updates are published directly in
[VN-Linux-Family/vnlf-social-desktop releases](https://github.com/VN-Linux-Family/vnlf-social-desktop/releases),
and the in-app updater fetches stable updates from that public repository. See
[distribution instructions](docs/BUILD_AND_RELEASE.md).

`assets/fonts/` contains Be Vietnam Pro, distributed under the included SIL Open
Font License. Source contracts and design comparisons are documented in
[API_NOTES.md](API_NOTES.md) and [DESIGN_REFERENCE.md](DESIGN_REFERENCE.md).
