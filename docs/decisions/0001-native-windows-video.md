# ADR-0001: Windows video through Media Foundation

**Status:** Accepted for implementation; native build/runtime checks remain release gates
**Date:** 2026-11-05
**Deciders:** VNLF native-client maintainer, implemented within the authorized production audit

## Context

The app must produce actual Windows x64 and ARM64 binaries with working media.
The published media_kit Windows libraries bundle x64 runtimes. An attempted
ARM64 packaging override failed CI because its libmpv release URL had been
removed. Shipping an emulated/mislabeled DLL or disabling integrity checks would
not meet the requested native architecture support. Linux, Android and Apple
builds already use their published platform-specific media_kit libraries.

## Decision

Use the published `video_player_win` 3.3.1 standalone controller/widget on Windows.
It delegates playback to Windows Media Foundation and adds a native plugin built
by the selected Windows toolchain. Select the existing media_kit platform
libraries directly for Linux, Android, iOS and macOS; remove the Windows runtime
bundle and unmerged Git override. Preserve lazy playback, seek, pause, mute,
expanded viewing, visible errors, lifecycle pausing and late-initialization cleanup.

## Options considered

| Option | Complexity | Main benefit | Main cost |
| --- | --- | --- | --- |
| Windows Media Foundation | Small native adapter and controls | OS media stack, native compilation, no libmpv/ANGLE runtime archive | Windows codec support differs from FFmpeg; requires Windows playback validation |
| Maintain ARM64 libmpv/ANGLE fork | Binary build and archive maintenance | Same renderer as other platforms | Unreleased patches and runtime archive availability/integrity risk |
| Emulated x64 Windows app | Low | Existing libraries work | Does not satisfy the explicitly requested native ARM64 build |

## Consequences

Windows package architecture is checked for every EXE/DLL before packaging.
Controller tests exercise failure, disposal and late completion; those tests do
not prove a real Windows decoder or GPU works. CI must compile both architectures,
and release validation must play the site's transcoded media on Windows. No
codec installer is downloaded or executed by the app. Linux runtime dependency
packaging and actual playback on each platform remain separate release checks.
The reviewed server transcodes post videos to 720p H.264 MP4; arbitrary video
formats and HLS are outside this backend's supported contract.

## References

- [Published package, API and standalone mode](https://pub.dev/packages/video_player_win)
- [Package repository](https://github.com/jakky1/video_player_win)
- [Media Kit platform library packages](https://pub.dev/packages/media_kit_libs_video)
