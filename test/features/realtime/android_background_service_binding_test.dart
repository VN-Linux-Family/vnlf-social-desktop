import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/android_background_service.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/realtime/presentation/android_background_service_binding.dart';
import 'package:vnlfsocialapp/src/features/realtime/presentation/community_realtime_providers.dart';

const _member = Session(
  userId: 'synthetic-member',
  username: 'thanhvienthu',
  displayName: 'Thành viên thử nghiệm',
);

void main() {
  late _Control control;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    control = _Control();
  });

  ProviderContainer container({bool android = true}) {
    final container = ProviderContainer(
      overrides: [
        androidPlatformProvider.overrideWithValue(android),
        backgroundServiceControlProvider.overrideWithValue(control),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('androidBackgroundServiceWantedProvider', () {
    test('needs Android, the member\'s choice and a session', () async {
      final subject = container();
      expect(subject.read(androidBackgroundServiceWantedProvider), isFalse);

      await subject.read(androidBackgroundSyncProvider.notifier).toggle(true);
      expect(subject.read(androidBackgroundServiceWantedProvider), isFalse);

      subject.read(sessionStateProvider.notifier).state = _member;
      expect(subject.read(androidBackgroundServiceWantedProvider), isTrue);

      await subject.read(androidBackgroundSyncProvider.notifier).toggle(false);
      expect(subject.read(androidBackgroundServiceWantedProvider), isFalse);
    });

    test('is never wanted off Android', () async {
      final subject = container(android: false);
      subject.read(sessionStateProvider.notifier).state = _member;
      await subject.read(androidBackgroundSyncProvider.notifier).toggle(true);

      expect(subject.read(androidBackgroundServiceWantedProvider), isFalse);
    });
  });

  testWidgets('the service runs only while a signed-in member wants it', (
    tester,
  ) async {
    final subject = container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: subject,
        child: const AndroidBackgroundServiceBinding(child: SizedBox()),
      ),
    );
    expect(control.calls, ['stop']);

    await subject.read(androidBackgroundSyncProvider.notifier).toggle(true);
    await tester.pump();
    expect(control.calls, ['stop'], reason: 'a guest has no connection');

    subject.read(sessionStateProvider.notifier).state = _member;
    await tester.pump();
    expect(control.calls, ['stop', 'start']);

    subject.read(sessionStateProvider.notifier).state = null;
    await tester.pump();
    expect(control.calls, ['stop', 'start', 'stop']);
  });

  testWidgets('a resumed app restarts a service Android stopped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'android_background_sync': true});
    final subject = container();
    subject.read(sessionStateProvider.notifier).state = _member;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: subject,
        child: const AndroidBackgroundServiceBinding(child: SizedBox()),
      ),
    );
    await tester.pump();
    expect(control.calls.last, 'start');
    control.calls.clear();

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();

    expect(control.calls, ['start']);
  });

  testWidgets('a resumed app leaves an unwanted service stopped', (
    tester,
  ) async {
    final subject = container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: subject,
        child: const AndroidBackgroundServiceBinding(child: SizedBox()),
      ),
    );
    control.calls.clear();

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();

    expect(control.calls, isEmpty);
  });
}

final class _Control implements BackgroundServiceControl {
  final calls = <String>[];

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> stop() async => calls.add('stop');
}
