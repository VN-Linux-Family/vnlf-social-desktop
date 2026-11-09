import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:vnlfsocialapp/src/design_system/components/vnlf_windows_video.dart';
import 'package:vnlfsocialapp/src/design_system/models/vnlf_models.dart';

const media = PostMediaData(
  url: 'https://example.invalid/synthetic.mp4',
  mime: 'video/mp4',
);
void main() {
  testWidgets(
    'Windows playback initializes on demand and supports pause and mute',
    (tester) async {
      final controller = _Controller();
      var created = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: VnlfWindowsVideo(
                media: media,
                createController: (_) {
                  created++;
                  return controller;
                },
              ),
            ),
          ),
        ),
      );
      expect(created, 0);
      await tester.tap(find.byTooltip('Phát video'));
      await tester.pumpAndSettle();
      expect(created, 1);
      expect(controller.playCalls, 1);
      await tester.tap(find.byTooltip('Tắt âm thanh'));
      await tester.pumpAndSettle();
      expect(controller.value.volume, 0);
      await tester.tap(find.byTooltip('Tạm dừng'));
      await tester.pumpAndSettle();
      expect(controller.value.isPlaying, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(controller.disposals, 1);
    },
  );
  testWidgets(
    'expanded video keeps one controller and releases it with its owner',
    (tester) async {
      final controller = _Controller();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VnlfWindowsVideo(
              media: media,
              createController: (_) => controller,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Phát video'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Phóng to video'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(controller.disposals, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(controller.value.isPlaying, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(controller.disposals, 1);
    },
  );

  testWidgets(
    'leaving during initialization prevents late playback and releases the controller',
    (tester) async {
      final gate = Completer<void>();
      final controller = _Controller()..gate = gate.future;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VnlfWindowsVideo(
              media: media,
              createController: (_) => controller,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Phát video'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      gate.complete();
      await tester.pumpAndSettle();
      expect(controller.playCalls, 0);
      expect(controller.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('background initialization never starts audio', (tester) async {
    final gate = Completer<void>();
    final controller = _Controller()..gate = gate.future;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VnlfWindowsVideo(
            media: media,
            createController: (_) => controller,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Phát video'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    gate.complete();
    await tester.pumpAndSettle();
    expect(controller.value.isInitialized, isTrue);
    expect(controller.playCalls, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(controller.disposals, 1);
  });
  testWidgets('initialization failure offers retry and never reports playing', (
    tester,
  ) async {
    final controller = _Controller()..reject = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VnlfWindowsVideo(
            media: media,
            createController: (_) => controller,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Phát video'));
    await tester.pumpAndSettle();
    expect(controller.playCalls, 0);
    expect(find.textContaining('Không phát được video'), findsOneWidget);
    expect(find.byTooltip('Thử lại video'), findsOneWidget);
  });
}

class _Controller extends ValueNotifier<WinVideoPlayerValue>
    implements WinVideoPlayerController {
  _Controller() : super(const WinVideoPlayerValue());
  @override
  int textureId_ = 11;
  Future<void>? gate;
  bool reject = false;
  int playCalls = 0;
  int disposals = 0;
  @override
  Future<void> initialize() async {
    await gate;
    if (reject) throw StateError('Synthetic media failure');
    value = const WinVideoPlayerValue(
      isInitialized: true,
      textureId: 11,
      duration: Duration(seconds: 30),
      size: Size(160, 90),
    );
  }

  @override
  Future<void> play() async {
    playCalls++;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> setVolume(double volume) async {
    value = value.copyWith(volume: volume);
  }

  @override
  Future<void> seekTo(Duration position) async {
    value = value.copyWith(position: position);
  }

  @override
  Future<void> dispose() async {
    disposals++;
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
