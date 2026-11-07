import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/main.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/domain/repositories.dart';

const _member = Session(
  userId: 'synthetic-member',
  username: 'thanhvienthu',
  displayName: 'Thành viên thử nghiệm',
);

void main() {
  test('failed logout leaves all session readers signed out', () async {
    final repository = _AuthRepository()
      ..logoutFailure = const TransportFailure();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);
    container.read(sessionProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sessionProvider).valueOrNull, _member);

    await expectLater(controller.logout(), throwsA(isA<TransportFailure>()));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authControllerProvider).valueOrNull, isNull);
    expect(container.read(sessionStateProvider), isNull);
    expect(container.read(sessionProvider).valueOrNull, isNull);
    expect(repository.sessionReads, 1);
  });

  test(
    'session restore finishing after logout cannot restore the member',
    () async {
      final restore = Completer<Session?>();
      final repository = _AuthRepository()..restore = restore.future;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);

      await controller.logout();
      restore.complete(_member);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider).valueOrNull, isNull);
      expect(container.read(sessionStateProvider), isNull);
      expect(container.read(sessionProvider).valueOrNull, isNull);
    },
  );

  testWidgets('all appearance choices survive a new app container', (
    tester,
  ) async {
    final storage = _MemoryStorage();
    for (final choice in const {
      'Tối': ThemeMode.dark,
      'Sáng': ThemeMode.light,
      'Tự động': ThemeMode.system,
    }.entries) {
      final container = _container(storage: storage);
      final router = await _pumpApp(tester, container);
      router.go('/settings');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, choice.key));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      container.dispose();

      final restarted = _container(storage: storage);
      await _pumpApp(tester, restarted);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        choice.value,
        reason: '${choice.key} must survive an app restart',
      );
      await tester.pumpWidget(const SizedBox());
      restarted.dispose();
    }
  });

  test('choosing a theme while storage loads keeps the new choice', () async {
    final restore = Completer<String?>();
    final storage = _MemoryStorage()..pendingRead = restore.future;
    final container = _container(storage: storage);
    addTearDown(container.dispose);
    final controller = container.read(themeModeProvider.notifier);

    await controller.setThemeMode(ThemeMode.light);
    restore.complete('dark');
    await controller.restored;

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('settings reports a theme save failure and lets the user retry', (
    tester,
  ) async {
    final storage = _MemoryStorage()..writeFailure = true;
    final container = _container(storage: storage);
    addTearDown(container.dispose);
    final router = await _pumpApp(tester, container);
    router.go('/settings');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không thể lưu giao diện'), findsOneWidget);
    expect(container.read(themeStorageFailureProvider), isA<StorageFailure>());
    expect(container.read(themeModeProvider), ThemeMode.dark);

    storage.writeFailure = false;
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không thể lưu giao diện'), findsNothing);
    expect(container.read(themeStorageFailureProvider), isNull);
  });

  testWidgets(
    'settings reports a language save failure and lets the user retry',
    (tester) async {
      final storage = _MemoryStorage()..writeFailure = true;
      final container = _container(storage: storage);
      addTearDown(container.dispose);
      final router = await _pumpApp(tester, container);
      router.go('/settings');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'English'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save language'), findsOneWidget);
      expect(
        container.read(localeStorageFailureProvider),
        isA<StorageFailure>(),
      );
      expect(container.read(localeProvider), const Locale('en'));

      storage.writeFailure = false;
      await tester.tap(find.widgetWithText(ChoiceChip, 'English'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save language'), findsNothing);
      expect(container.read(localeStorageFailureProvider), isNull);
    },
  );

  testWidgets(
    'settings logout handles server failure and shows guest account',
    (tester) async {
      final repository = _AuthRepository()
        ..logoutFailure = const TransportFailure();
      final container = _container(repository: repository);
      addTearDown(container.dispose);
      final router = await _pumpApp(tester, container);
      router.go('/settings');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();

      expect(find.text('Khách'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsNothing);
      expect(container.read(sessionProvider).valueOrNull, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('navigation offers logout for a member at width $width', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);
      await _pumpApp(tester, container, width: width);
      if (width == 390) {
        await tester.tap(find.byTooltip('Mở menu điều hướng'));
        await tester.pumpAndSettle();
      }
      final logout = width == 900
          ? find.byTooltip('Đăng xuất')
          : find.text('Đăng xuất');
      expect(logout, findsOneWidget);
      await tester.tap(logout);
      await tester.pumpAndSettle();

      expect(container.read(sessionStateProvider), isNull);
      expect(container.read(sessionProvider).valueOrNull, isNull);
      expect(find.text('Đăng xuất'), findsNothing);
      expect(find.byTooltip('Đăng xuất'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

ProviderContainer _container({
  PreferencesStorage? storage,
  _AuthRepository? repository,
}) => ProviderContainer(
  overrides: [
    preferencesStorageProvider.overrideWithValue(storage ?? _MemoryStorage()),
    authRepositoryProvider.overrideWithValue(repository ?? _AuthRepository()),
  ],
);

Future<GoRouter> _pumpApp(
  WidgetTester tester,
  ProviderContainer container, {
  double width = 390,
}) async {
  tester.platformDispatcher.localesTestValue = const [Locale('vi')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MainApp()),
  );
  await tester.pumpAndSettle();
  return tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
      as GoRouter;
}

class _AuthRepository implements AuthRepository {
  AppFailure? logoutFailure;
  Future<Session?>? restore;
  int sessionReads = 0;

  @override
  Future<Session?> currentSession() async {
    sessionReads++;
    return restore ?? Future.value(_member);
  }

  @override
  Future<Session> login(String login, String password) async => _member;

  @override
  Future<Session> register(
    String email,
    String username,
    String password,
  ) async => _member;

  @override
  Future<void> logout() async {
    if (logoutFailure case final failure?) throw failure;
  }
}

class _MemoryStorage implements PreferencesStorage {
  final values = <String, String>{};
  Future<String?>? pendingRead;
  bool writeFailure = false;

  @override
  Future<String?> read(String key) async =>
      pendingRead ?? Future.value(values[key]);

  @override
  Future<void> write(String key, String value) async {
    if (writeFailure) throw const StorageFailure();
    values[key] = value;
  }
}
