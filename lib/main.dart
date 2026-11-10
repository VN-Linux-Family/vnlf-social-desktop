import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'src/app/app_router.dart';
import 'src/app/providers.dart';
import 'src/core/desktop_tray_service.dart';
import 'src/design_system/design_system.dart';
import 'src/domain/models.dart';
import 'src/features/activity/automatic/automatic_checkin_binding.dart';
import 'src/features/activity/presentation/activity_page.dart';
import 'src/features/notifications/data/local_notification_service.dart';
import 'src/features/notifications/presentation/legacy_push_cleanup_provider.dart';
import 'src/features/notifications/presentation/notification_tap.dart';
import 'src/features/notifications/presentation/push_providers.dart';
import 'src/features/profile/presentation/profile_card.dart';
import 'src/features/updates/presentation/update_notifier.dart';
import 'src/i18n/vi.dart';
import 'src/features/realtime/presentation/android_background_service_binding.dart';
import 'src/features/realtime/presentation/community_realtime_binding.dart';
import 'src/features/settings/preferences/preferences_controller.dart';
import 'src/features/settings/preferences/motion_preference_scope.dart';
import 'src/features/settings/text_size/text_size.dart';
import 'src/features/shared/presentation/feature_samples.dart'
    show offlineFeatures;

Future<void> main(List<String> args) async {
  // A push message arrived while the app was closed: the UnifiedPush
  // connector runs this entrypoint headless to show it.
  if (args.contains(unifiedPushBackgroundArg)) {
    await runUnifiedPushInBackground();
    return;
  }
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
  late final _pushService = PushServiceBinding(ref);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isTesting = () {
        try {
          return Platform.environment.containsKey('FLUTTER_TEST');
        } catch (_) {
          return false;
        }
      }();
      if (isTesting) return;

      if (DesktopTrayService.isDesktop) {
        ref.read(desktopTrayServiceProvider).initialize();
      }
      ref
          .read(localNotificationServiceProvider)
          .initialize(
            onSelectNotification: (payload) => openNotificationTarget(
              payload,
              go: _router.go,
              openWebsite: (page) =>
                  launchUrl(page, mode: LaunchMode.externalApplication),
            ),
          );
      unawaited(_pushService.start());
    });
  }

  /// One attempt per sign-in; a failure leaves the stored endpoint for the
  /// next sign-in or launch instead of retrying the delete.
  void _removeLegacyPushSubscription() {
    if (offlineFeatures || ref.read(ioTransportProvider) == null) return;
    unawaited(
      ref
          .read(legacyPushCleanupProvider)
          .run()
          .then<void>(
            (_) {},
            onError: (Object error) => debugPrint(
              'Legacy push subscription cleanup failed: ${error.runtimeType}',
            ),
          ),
    );
  }

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
        if (nextUser != null && nextUser.isNotEmpty) {
          _removeLegacyPushSubscription();
          unawaited(_pushService.syncReplacedEndpoint());
        }
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
      builder: (context, child) => ProfileCardScope(
        child: MotionPreferenceScope(
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
                child: AndroidBackgroundServiceBinding(
                  child: AppUpdateNotifier(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      title: vi.app.tieuDeUngDung,
      theme: VnlfTheme.light(),
      darkTheme: VnlfTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: Duration.zero,
      // VNLF Social chỉ có tiếng Việt, như website.
      locale: const Locale('vi'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi')],
      routerConfig: _router,
    );
  }
}
