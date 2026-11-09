import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/components/vnlf_video.dart';
import 'package:vnlfsocialapp/src/design_system/components/vnlf_video_playback.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';

void main() {
  testWidgets(
    'startup keeps its surface mounted until a decoded frame confirms playback',
    (tester) async {
      final playback = _Playback();
      await _pump(tester, playback);
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump();
      expect(find.byKey(const Key('native-video-surface')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(playback.plays, 0);
      playback.frame.complete();
      await tester.pumpAndSettle();
      expect(playback.plays, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('unavailable'), findsNothing);
    },
  );
  testWidgets(
    'a URL change releases the old player and ignores its late decoded frame',
    (tester) async {
      final old = _Playback();
      final next = _Playback();
      await _pump(tester, old);
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump();
      await _pump(tester, next, url: 'https://media.example.test/second.mp4');
      old.frame.complete();
      await tester.pumpAndSettle();
      expect(old.disposals, 1);
      expect(old.plays, 0);
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump();
      next.frame.complete();
      await tester.pumpAndSettle();
      expect(next.plays, 1);
    },
  );
  testWidgets(
    'a video opened in the foreground cannot start after the app becomes inactive',
    (tester) async {
      final playback = _Playback();
      await _pump(tester, playback);
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      playback.frame.complete();
      await tester.pumpAndSettle();
      expect(playback.plays, 0);
      expect(playback.pauses, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );
  testWidgets('a server processing failure releases an already playing video', (
    tester,
  ) async {
    final playback = _Playback();
    await _pump(tester, playback);
    await tester.tap(find.byTooltip('Play video'));
    await tester.pump();
    playback.frame.complete();
    await tester.pumpAndSettle();
    expect(playback.plays, 1);
    await _pump(tester, playback, state: 'FAILED');
    await tester.pumpAndSettle();
    expect(playback.disposals, 1);
    expect(find.text('Video unavailable'), findsOneWidget);
  });
  testWidgets(
    'missing decoded frames time out with retry and release the failed player',
    (tester) async {
      final playback = _Playback();
      await _pump(tester, playback);
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(playback.disposals, 1);
      expect(find.text('Video unavailable. Tap to retry.'), findsOneWidget);
      expect(find.byTooltip('Play video'), findsOneWidget);
      expect(playback.plays, 0);
    },
  );
  testWidgets(
    'removing a video during a pending native open cancels startup without a late play',
    (tester) async {
      final playback = _Playback()..opening = Completer<void>();
      await _pump(tester, playback);
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      playback.opening!.complete();
      playback.frame.complete();
      await tester.pumpAndSettle();
      expect(playback.disposals, 1);
      expect(playback.plays, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  _Playback playback, {
  String url = 'https://media.example.test/first.mp4',
  String? state,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: VnlfVideo(
        media: PostMediaData(url: url, mime: 'video/mp4', state: state),
        createPlayback: () => playback,
      ),
    ),
  ),
);

class _Playback implements VnlfVideoPlayback {
  Completer<void>? opening;
  final frame = Completer<void>();
  int plays = 0, pauses = 0, disposals = 0;
  @override
  Future<void> open(Uri uri) async {
    await opening?.future;
  }

  @override
  Future<void> get firstFrame => frame.future;
  @override
  Future<void> play() async {
    plays++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }

  @override
  Widget buildSurface() =>
      const ColoredBox(key: Key('native-video-surface'), color: Colors.blue);
}
