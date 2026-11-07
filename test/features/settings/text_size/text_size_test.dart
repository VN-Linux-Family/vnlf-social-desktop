import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/features/settings/text_size/text_size.dart';

void main() {
  testWidgets(
    'the text scope applies the preference on top of device scaling',
    (tester) async {
      final storage = _ImmediateStorage();
      final container = ProviderContainer(
        overrides: [preferencesStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TextSizeScope(
                child: Builder(
                  builder: (context) => Text(
                    MediaQuery.textScalerOf(context).scale(13).toString(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('19.5'), findsOneWidget);
      container.read(textSizeProvider.notifier).preview(18);
      await tester.pump();
      expect(find.text('27.0'), findsOneWidget);
    },
  );

  testWidgets('keyboard adjustment updates and persists the selected size', (
    tester,
  ) async {
    final storage = _ImmediateStorage();
    final container = ProviderContainer(
      overrides: [preferencesStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: TextSizeScope(child: TextSizeSettings())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final before = container.read(textSizeProvider).size;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(container.read(textSizeProvider).size, before + 1);
    expect(storage.value, '${before + 1}');
  });

  test('an edit wins over a late restore and writes are ordered', () async {
    final storage = _Storage();
    final controller = TextSizeController(storage);
    controller.preview(17);
    final first = controller.commit();
    controller.preview(18);
    final second = controller.commit();
    storage.readResult.complete('12');
    await controller.restored;
    expect(controller.state.size, 18);
    await Future<void>.delayed(Duration.zero);
    expect(storage.writes, ['17']);
    storage.pendingWrites.removeAt(0).complete();
    await first;
    await Future<void>.delayed(Duration.zero);
    expect(storage.writes, ['17', '18']);
    storage.pendingWrites.removeAt(0).complete();
    await second;
    controller.dispose();
  });

  test('storage failures are visible and reset persists the default', () async {
    final storage = _Storage()..readResult.completeError(Exception());
    final controller = TextSizeController(storage);
    await controller.restored;
    expect(controller.state.storageFailure, isTrue);
    controller.preview(18);
    final reset = controller.reset();
    await Future<void>.delayed(Duration.zero);
    expect(storage.writes, ['13']);
    storage.pendingWrites.removeAt(0).complete();
    await reset;
    expect(controller.state.size, 13);
    expect(controller.state.storageFailure, isFalse);
    controller.dispose();
  });

  test('a failed write is reported and a later save clears it', () async {
    final storage = _Storage()..readResult.complete(null);
    final controller = TextSizeController(storage);
    await controller.restored;
    controller.preview(16);
    final failed = controller.commit();
    await Future<void>.delayed(Duration.zero);
    storage.pendingWrites.removeAt(0).completeError(Exception());
    await failed;
    expect(controller.state.storageFailure, isTrue);
    final retry = controller.commit();
    await Future<void>.delayed(Duration.zero);
    storage.pendingWrites.removeAt(0).complete();
    await retry;
    expect(controller.state.storageFailure, isFalse);
    controller.dispose();
  });

  test('composes preference with nonlinear device scaling', () {
    const scaler = PreferenceTextScaler(_NonlinearScaler(), 18);
    expect(scaler.scale(13), closeTo(36, 0.001));
    expect(scaler.scale(26), closeTo(54, 0.001));
  });
}

class _ImmediateStorage implements PreferencesStorage {
  String? value;
  @override
  Future<String?> read(String key) async => value;
  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();
  @override
  double scale(double fontSize) => fontSize + 18;
  @override
  double get textScaleFactor => 2;
}

class _Storage implements PreferencesStorage {
  final readResult = Completer<String?>();
  final writes = <String>[];
  final pendingWrites = <Completer<void>>[];
  @override
  Future<String?> read(String key) => readResult.future;
  @override
  Future<void> write(String key, String value) {
    writes.add(value);
    final pending = Completer<void>();
    pendingWrites.add(pending);
    return pending.future;
  }
}
