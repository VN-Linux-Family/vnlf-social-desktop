import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnlfsocialapp/main.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/android_background_service.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/domain/repositories.dart';

const _member = Session(
  userId: 'synthetic-member',
  username: 'thanhvienthu',
  displayName: 'Thành viên thử nghiệm',
);

const _viTitle = 'Thông báo khi chạy nền';
const _viSubtitle =
    'Giữ kết nối khi ứng dụng chạy nền để báo tin nhắn và hoạt động mới. '
    'Đóng hẳn ứng dụng thì sẽ không nhận được thông báo.';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Android settings describe background notifications honestly', (
    tester,
  ) async {
    final container = _container(android: true);
    addTearDown(container.dispose);
    await _openSettings(tester, container);

    await tester.ensureVisible(find.text(_viTitle));
    await tester.pumpAndSettle();
    expect(find.text(_viSubtitle), findsOneWidget);
    expect(find.text('Thông báo đẩy'), findsNothing);
    expect(container.read(androidBackgroundSyncProvider), isTrue);

    await tester.tap(find.text(_viTitle));
    await tester.pumpAndSettle();

    expect(container.read(androidBackgroundSyncProvider), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the switch uses the English catalog', (tester) async {
    final container = _container(android: true);
    addTearDown(container.dispose);
    await _openSettings(tester, container, locale: const Locale('en'));

    await tester.ensureVisible(find.text('Background notifications'));
    expect(
      find.textContaining('Nothing arrives after the app is fully closed.'),
      findsOneWidget,
    );
  });

  testWidgets('the switch fits a 390px phone at 200% text', (tester) async {
    final container = _container(android: true);
    addTearDown(container.dispose);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openSettings(tester, container);

    await tester.ensureVisible(find.text(_viSubtitle));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('other platforms show no notification switch', (tester) async {
    final container = _container(android: false);
    addTearDown(container.dispose);
    await _openSettings(tester, container);

    expect(find.text(_viTitle), findsNothing);
    expect(find.text('Thông báo đẩy'), findsNothing);
  });
}

ProviderContainer _container({required bool android}) => ProviderContainer(
  overrides: [
    androidPlatformProvider.overrideWithValue(android),
    preferencesStorageProvider.overrideWithValue(_MemoryStorage()),
    authRepositoryProvider.overrideWithValue(_AuthRepository()),
  ],
);

Future<void> _openSettings(
  WidgetTester tester,
  ProviderContainer container, {
  Locale locale = const Locale('vi'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(390, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MainApp()),
  );
  await tester.pumpAndSettle();
  (tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
          as GoRouter)
      .go('/settings');
  await tester.pumpAndSettle();
}

class _AuthRepository implements AuthRepository {
  @override
  Future<Session?> currentSession() async => _member;

  @override
  Future<Session> login(String login, String password) async => _member;

  @override
  Future<Session> register(
    String email,
    String username,
    String password,
  ) async => _member;

  @override
  Future<void> logout() async {}
}

class _MemoryStorage implements PreferencesStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
