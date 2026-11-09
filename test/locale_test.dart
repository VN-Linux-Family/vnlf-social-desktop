import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/main.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/domain/repositories.dart';

void main() {
  for (final system in const [Locale('en'), Locale('fr'), Locale('vi')]) {
    testWidgets(
      'the app speaks Vietnamese on a ${system.languageCode} system',
      (tester) async {
        await _pumpApp(tester, system);

        final context = tester.element(find.byType(Scaffold).first);
        expect(Localizations.localeOf(context), const Locale('vi'));
      },
    );
  }

  testWidgets('Vietnamese is the only language offered', (tester) async {
    await _pumpApp(tester, const Locale('en'));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales, const [Locale('vi')]);

    (app.routerConfig! as GoRouter).go('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Ngôn ngữ'), findsNothing);
    expect(find.text('English'), findsNothing);
  });
}

Future<void> _pumpApp(WidgetTester tester, Locale system) async {
  tester.platformDispatcher.localesTestValue = [system];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final container = ProviderContainer(
    overrides: [
      preferencesStorageProvider.overrideWithValue(_MemoryStorage()),
      authRepositoryProvider.overrideWithValue(_GuestAuthRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MainApp()),
  );
  await tester.pumpAndSettle();
}

class _GuestAuthRepository implements AuthRepository {
  @override
  Future<Session?> currentSession() async => null;

  @override
  Future<Session> login(String login, String password) =>
      throw const HttpFailure(401);

  @override
  Future<Session> register(String email, String username, String password) =>
      throw const HttpFailure(409);

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
