import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/android_background_service.dart';
import 'community_realtime_providers.dart';

/// Starts the Android foreground service while it is wanted and stops it
/// otherwise.
///
/// Android 15 stops a dataSync service after six hours in a day. The app may
/// start it again from the foreground, so a resumed app restarts it when it is
/// still wanted.
class AndroidBackgroundServiceBinding extends ConsumerStatefulWidget {
  const AndroidBackgroundServiceBinding({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AndroidBackgroundServiceBinding> createState() =>
      _AndroidBackgroundServiceBindingState();
}

class _AndroidBackgroundServiceBindingState
    extends ConsumerState<AndroidBackgroundServiceBinding> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(
      androidBackgroundServiceWantedProvider,
      (_, wanted) => _apply(wanted),
      fireImmediately: true,
    );
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (ref.read(androidBackgroundServiceWantedProvider)) _apply(true);
      },
    );
  }

  void _apply(bool wanted) {
    final control = ref.read(backgroundServiceControlProvider);
    unawaited(
      (wanted ? control.start() : control.stop()).then<void>(
        (_) {},
        onError: (Object error) => debugPrint(
          'Background service ${wanted ? 'start' : 'stop'} failed: '
          '${error.runtimeType}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
