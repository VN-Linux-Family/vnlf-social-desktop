import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'src/app/app_router.dart';
import 'src/app/providers.dart';
import 'src/design_system/design_system.dart';
import 'src/domain/models.dart';
import 'src/features/activity/automatic/automatic_checkin_binding.dart';
import 'src/features/activity/presentation/activity_page.dart';
import 'src/features/updates/presentation/update_notifier.dart';
import 'src/features/realtime/presentation/community_realtime_binding.dart';
import 'src/features/settings/preferences/preferences_controller.dart';
import 'src/features/settings/preferences/motion_preference_scope.dart';
import 'src/features/settings/text_size/text_size.dart';
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
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _modalTracker = AutomaticModalTracker(
    blockedPageNames: {composeRouteName, editComposeRouteName},
  );
  late final _router = createMainRouter(
    navigatorKey: _navigatorKey,
    rootObservers: [_modalTracker.observer()],
    shellObservers: [_modalTracker.observer()],
  );

  @override
  void dispose() {
    _router.dispose();
    _modalTracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Session?>>(sessionProvider, (previous, next) {
      final prevUser = previous?.valueOrNull?.userId;
      final nextUser = next.valueOrNull?.userId;
      if (prevUser != nextUser) {
        _scaffoldMessengerKey.currentState?.clearSnackBars();
      }
    });

    final auth = ref.watch(sessionProvider);
    final session = auth is AsyncData<Session?> ? auth.value : null;
    final hasConfirmedSession = session != null && session.userId.isNotEmpty;
    final client = ref.watch(apiClientProvider);
    final storage = ref.watch(sessionStorageProvider);
    final live = !offlineFeatures && ref.watch(ioTransportProvider) != null;
    final hasSession = ref.watch(sessionStateProvider) != null;
    final reduceMotion = hasSession && !offlineFeatures
        ? ref.watch(
            preferencesControllerProvider.select(
              (state) => state.confirmed?.reduceMotion ?? false,
            ),
          )
        : false;
    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      builder: (context, child) => MotionPreferenceScope(
        reduceMotion: reduceMotion,
        child: TextSizeScope(
          child: AutomaticCheckInBinding(
            client: client,
            storage: storage,
            tracker: _modalTracker,
            navigatorKey: _navigatorKey,
            ownerId: hasConfirmedSession ? session.userId : null,
            confirmation: hasConfirmedSession ? auth : null,
            live: live,
            onViewActivity: () => _router.go('/activity'),
            onAcknowledged: (owner) =>
                ref.invalidate(activityServiceProvider(owner)),
            onProblem: (owner) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !identical(ref.read(sessionProvider), auth)) {
                  return;
                }
                final messenger = _scaffoldMessengerKey.currentState;
                if (messenger == null) return;
                final context = _navigatorKey.currentContext;
                final english =
                    context != null &&
                    Localizations.localeOf(context).languageCode == 'en';
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      english
                          ? 'Could not complete or confirm daily check-in.'
                          : 'Không thể hoàn tất hoặc xác nhận điểm danh hôm nay.',
                    ),
                    action: SnackBarAction(
                      label: english ? 'Activity' : 'Hoạt động',
                      onPressed: () {
                        final current = ref.read(sessionProvider);
                        if (identical(current, auth) &&
                            current.valueOrNull?.userId == owner) {
                          _router.go('/activity');
                        }
                      },
                    ),
                  ),
                );
              });
              WidgetsBinding.instance.ensureVisualUpdate();
            },
            child: CommunityAppBinding(
              child: AppUpdateNotifier(child: child ?? const SizedBox.shrink()),
            ),
          ),
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
