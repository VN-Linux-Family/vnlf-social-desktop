import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'src/app/app_router.dart';
import 'src/app/providers.dart';
import 'src/design_system/design_system.dart';
import 'src/features/updates/presentation/update_notifier.dart';
import 'src/features/realtime/presentation/community_realtime_binding.dart';
import 'src/features/settings/preferences/preferences_controller.dart';
import 'src/features/settings/preferences/motion_preference_scope.dart';
import 'src/features/shared/presentation/feature_samples.dart'
    show offlineFeatures;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _App());
  }
}

class _App extends ConsumerStatefulWidget {
  const _App();

  @override
  ConsumerState<_App> createState() => _AppState();
}

class _AppState extends ConsumerState<_App> {
  final _router = createMainRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = ref.watch(sessionStateProvider) != null;
    final reduceMotion = hasSession && !offlineFeatures
        ? ref.watch(
            preferencesControllerProvider.select(
              (state) => state.confirmed?.reduceMotion ?? false,
            ),
          )
        : false;
    return MaterialApp.router(
      builder: (context, child) => MotionPreferenceScope(
        reduceMotion: reduceMotion,
        child: CommunityAppBinding(
          child: AppUpdateNotifier(child: child ?? const SizedBox.shrink()),
        ),
      ),
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: VnlfTheme.light(),
      darkTheme: VnlfTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: Duration.zero,
      locale: ref.watch(localeProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
