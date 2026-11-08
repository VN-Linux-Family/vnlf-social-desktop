// Run with VNLF_LIVE=false. Captures real native route widgets using only
// in-memory fixtures; no keyring, notification service or production connection.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';

import 'ux_audit_fixtures.dart';
import 'ux_audit_surfaces.dart';

import 'package:vnlfsocialapp/src/features/voice/presentation/voice_providers.dart';

const auditRoutes = {
  'login': '/login',
  'feed': '/',
  'thread': '/thread/post-synth-1',
  'profile': '/profile/hoangnam',
  'discover': '/discover',
  'search': '/search',
  'leaderboard': '/leaderboard',
  'projects': '/projects',
  'project-detail': '/projects/vnlf-cli',
  'project-submit': '/projects/submit',
  'channels': '/channels/linux',
  'messages': '/messages/audit-dm',
  'voice': '/voice',
  'activity': '/activity',
  'feedback-history': '/feedback',
  'feedback-thread': '/feedback/$auditFeedbackId',
  'settings': '/settings',
  'composer': '/compose',
};

void main() async {
  if (const bool.fromEnvironment('VNLF_LIVE', defaultValue: true)) {
    throw StateError('UX capture requires --dart-define=VNLF_LIVE=false');
  }
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _NoNetwork();
  final window = WindowManager.instance.getCurrent()!;
  window.titleBarStyle = TitleBarStyle.hidden;
  window.show();
  runApp(
    ProviderScope(
      overrides: auditOverrides(populatedComposer: true),
      child: const _CaptureApp(),
    ),
  );
}

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('Networking is disabled during synthetic UX capture');
}

class _CaptureApp extends StatefulWidget {
  const _CaptureApp();
  @override
  State<_CaptureApp> createState() => _CaptureAppState();
}

class _CaptureAppState extends State<_CaptureApp> {
  final _boundary = GlobalKey();
  final _router = createMainRouter();
  ThemeMode _mode = ThemeMode.light;
  Widget? _preview;
  final _errors = <String>[];

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      _errors.add(details.exceptionAsString());
      FlutterError.presentError(details);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    final output = Directory(
      Platform.environment['VNLF_UX_OUTPUT'] ?? '/tmp/vnlf-ux-captures',
    )..createSync(recursive: true);
    final manifest = StringBuffer('Synthetic native Linux captures\n');
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      setState(() => _mode = mode);
      for (final width in [390.0, 900.0, 1440.0]) {
        WindowManager.instance.getCurrent()!.setSize(
          Size(width, 1000).toNative(),
          false,
        );
        for (final route in auditRoutes.entries) {
          if (_preview != null) setState(() => _preview = null);
          _router.go(route.value);
          await Future<void>.delayed(const Duration(milliseconds: 650));
          await WidgetsBinding.instance.endOfFrame;
          final boundary =
              _boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final name = '${route.key}-${width.toInt()}-${mode.name}.png';
          await File('${output.path}/$name')
              .writeAsBytes(bytes!.buffer.asUint8List());
          manifest.writeln('$name ${image.width}x${image.height}');
          image.dispose();
        }
        for (final surface in auditAuxiliarySurfaces().entries) {
          setState(() => _preview = surface.value);
          await Future<void>.delayed(const Duration(milliseconds: 100));
          if (surface.key == 'voice-live') {
            await ProviderScope.containerOf(
              _boundary.currentContext!,
              listen: false,
            ).read(voiceSessionProvider.notifier).join(auditVoiceRoom);
          }
          await Future<void>.delayed(const Duration(milliseconds: 650));
          await WidgetsBinding.instance.endOfFrame;
          final boundary =
              _boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final name = '${surface.key}-${width.toInt()}-${mode.name}.png';
          await File('${output.path}/$name')
              .writeAsBytes(bytes!.buffer.asUint8List());
          manifest.writeln('$name ${image.width}x${image.height}');
          image.dispose();
        }
      }
    }
    await File('${output.path}/manifest.txt').writeAsString(
      '$manifest\nFlutter errors: ${_errors.length}\n${_errors.join('\n')}',
    );
    if (_errors.isNotEmpty) exit(1);
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: _boundary,
    child: MaterialApp.router(
      theme: VnlfTheme.light(),
      darkTheme: VnlfTheme.dark(),
      themeMode: _mode,
      themeAnimationDuration: Duration.zero,
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
      builder: (context, child) =>
          _preview == null ? child! : Scaffold(body: _preview),
    ),
  );
}
