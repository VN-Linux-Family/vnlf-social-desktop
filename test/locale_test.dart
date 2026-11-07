import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/l10n/app_localizations_en.dart';
import 'package:vnlfsocialapp/l10n/app_localizations_vi.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';

void main() {
  testWidgets('system Vietnamese locale resolves to Vietnamese', (
    tester,
  ) async {
    await _pumpWithSystemLocale(tester, const Locale('vi'));

    expect(_localizations(tester), isA<AppLocalizationsVi>());
  });

  testWidgets('system English locale resolves to English', (tester) async {
    await _pumpWithSystemLocale(tester, const Locale('en'));

    expect(_localizations(tester), isA<AppLocalizationsEn>());
  });

  testWidgets('unsupported system locale falls back to Vietnamese', (
    tester,
  ) async {
    await _pumpWithSystemLocale(tester, const Locale('fr'));

    expect(_localizations(tester), isA<AppLocalizationsVi>());
  });

  testWidgets('manual override beats system locale and survives a rebuild', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _LocaleTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(_localizations(tester), isA<AppLocalizationsVi>());

    container.read(localeProvider.notifier).state = const Locale('en');
    await tester.pumpAndSettle();

    expect(_localizations(tester), isA<AppLocalizationsEn>());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _LocaleTestApp(key: ValueKey('rebuilt-app')),
      ),
    );
    await tester.pumpAndSettle();

    expect(_localizations(tester), isA<AppLocalizationsEn>());
  });

  testWidgets('language selection persists across app relaunches via storage', (
    tester,
  ) async {
    final storage = _TestPreferencesStorage();
    final firstContainer = ProviderContainer(
      overrides: [preferencesStorageProvider.overrideWithValue(storage)],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: firstContainer,
        child: const _LocaleTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Select English
    firstContainer.read(localeProvider.notifier).state = const Locale('en');
    await tester.pumpAndSettle();
    expect(_localizations(tester), isA<AppLocalizationsEn>());
    expect(storage.values['vnlf_locale'], 'en');

    // Dispose old container (simulating app quit)
    await tester.pumpWidget(const SizedBox());
    firstContainer.dispose();

    // Relaunch app with fresh container sharing the same storage
    final secondContainer = ProviderContainer(
      overrides: [preferencesStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(secondContainer.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: secondContainer,
        child: const _LocaleTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _localizations(tester),
      isA<AppLocalizationsEn>(),
      reason: 'English locale must survive relaunch from persisted storage',
    );
  });

  test('Vietnamese is the first supported locale', () {
    expect(AppLocalizations.supportedLocales.first, const Locale('vi'));
  });
}

class _TestPreferencesStorage implements PreferencesStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

Future<void> _pumpWithSystemLocale(WidgetTester tester, Locale locale) async {
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(const ProviderScope(child: _LocaleTestApp()));
  await tester.pumpAndSettle();
}

AppLocalizations? _localizations(WidgetTester tester) {
  final context = tester.element(
    find.byKey(const ValueKey('localized-context')),
  );
  return AppLocalizations.of(context);
}

class _LocaleTestApp extends ConsumerWidget {
  const _LocaleTestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        key: const ValueKey('localized-context'),
        builder: (context) {
          final localizations = AppLocalizations.of(context)!;
          return Text(localizations.runtimeType.toString());
        },
      ),
    );
  }
}
