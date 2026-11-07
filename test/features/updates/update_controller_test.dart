import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/features/updates/domain/app_update.dart';
import 'package:vnlfsocialapp/src/features/updates/presentation/update_panel.dart';
import 'package:vnlfsocialapp/src/features/updates/presentation/update_providers.dart';

void main() {
  test(
    'automatic update check cache never prevents an explicit manual check',
    () async {
      final repository = FakeUpdates();
      final storage = UpdatePreferences()
        ..values['vnlf_last_update_check'] = DateTime.now()
            .toUtc()
            .toIso8601String();
      final controller = UpdateController(
        repository,
        const UpdatePlatform('linux', 'arm64', 'tar.gz'),
        storage,
      );
      addTearDown(controller.dispose);
      await controller.check(automatic: true);
      expect(repository.calls, 0);
      await controller.check();
      expect(repository.calls, 1);
    },
  );
  test('overlapping manual checks send one request', () async {
    final pending = Completer<AppUpdate>();
    final repository = FakeUpdates(pending: pending);
    final controller = UpdateController(
      repository,
      const UpdatePlatform('linux', 'arm64', 'tar.gz'),
      UpdatePreferences(),
    );
    AsyncValue<AppUpdate?>? observed;
    controller.addListener((value) => observed = value);
    addTearDown(controller.dispose);
    final first = controller.check();
    final second = controller.check();
    expect(repository.calls, 1);
    pending.complete(const UpdateUnavailable());
    await Future.wait([first, second]);
    expect(observed?.valueOrNull, isA<UpdateUnavailable>());
  });
  test(
    'a preferences read failure does not disable release checking',
    () async {
      final repository = FakeUpdates();
      final controller = UpdateController(
        repository,
        const UpdatePlatform('linux', 'arm64', 'tar.gz'),
        UpdatePreferences(failRead: true),
      );
      AsyncValue<AppUpdate?>? observed;
      controller.addListener((value) => observed = value);
      addTearDown(controller.dispose);
      await controller.check(automatic: true);
      expect(repository.calls, 1);
      expect(observed?.valueOrNull, isA<UpdateUnavailable>());
    },
  );
  testWidgets('missing public release is visible after the user checks', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateRepositoryProvider.overrideWithValue(FakeUpdates()),
          preferencesStorageProvider.overrideWithValue(UpdatePreferences()),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          supportedLocales: [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(body: AppUpdatePanel()),
        ),
      ),
    );
    await tester.tap(find.text('Kiểm tra cập nhật'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chưa có bản phát hành công khai để kiểm tra.'),
      findsOneWidget,
    );
  });
}

class FakeUpdates implements UpdateRepository {
  FakeUpdates({this.pending});
  final Completer<AppUpdate>? pending;
  int calls = 0;
  @override
  Future<AppUpdate> check(String currentVersion, UpdatePlatform platform) {
    calls++;
    return pending?.future ?? Future.value(const UpdateUnavailable());
  }
}

class UpdatePreferences implements PreferencesStorage {
  UpdatePreferences({this.failRead = false});
  final bool failRead;
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('Preference storage unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
