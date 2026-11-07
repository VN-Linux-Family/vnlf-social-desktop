import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_models.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_repository.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_room_session.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/live_voice_screen.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/voice_participant.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/voice_providers.dart';

void main() {
  testWidgets(
    'signed-out live screen never loads fixture rooms or calls directory',
    (tester) async {
      final repository = _Repository();
      await _pump(tester, repository, null);
      expect(find.text('Kênh đàm thoại chung'), findsNothing);
      expect(find.text('Phòng Voice Chung'), findsNothing);
      expect(find.text('Đăng nhập để tham gia Voice'), findsOneWidget);
      expect(repository.reads, 0);
    },
  );

  testWidgets(
    'failed live join shows error and no connected participant or share control',
    (tester) async {
      final repository = _Repository()..rejectJoin = true;
      await _pump(tester, repository, 'synthetic-user');
      expect(find.text('Phòng từ máy chủ'), findsWidgets);
      expect(find.byTooltip('Chia sẻ màn hình'), findsNothing);
      await tester.tap(find.text('Tham gia phòng'));
      await tester.pumpAndSettle();
      expect(find.text('Rời phòng'), findsNothing);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.textContaining('Không thể kết nối'), findsOneWidget);
      expect(find.byType(VoiceParticipant), findsNothing);
    },
  );

  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('live directory fits $width with scaled Vietnamese text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, _Repository(), 'synthetic-user');
      expect(tester.takeException(), isNull);
      expect(find.textContaining('4 người tham gia'), findsWidgets);
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Repository repository,
  String? account,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        voiceAccountIdProvider.overrideWithValue(account),
        voiceRepositoryProvider.overrideWithValue(repository),
        voiceRoomSessionFactoryProvider.overrideWithValue(() => _Audio()),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: VnlfTheme.light(),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: LiveVoiceScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Repository implements VoiceRepository {
  int reads = 0;
  bool rejectJoin = false;
  @override
  Future<List<VoiceRoom>> getRooms() async {
    reads++;
    return [
      const VoiceRoom(
        id: 'room-1',
        name: 'Phòng từ máy chủ',
        status: 'ACTIVE',
        description: 'Tiếng Việt: ặ ữ ờ ẫ ệ',
        participantCount: 4,
      ),
    ];
  }

  @override
  Future<VoiceConnection> join(String roomId) async {
    if (rejectJoin) throw const VoiceConnectionFailure();
    return const VoiceConnection(
      serverUrl: 'wss://voice.example.invalid',
      token: 'synthetic-test-value',
    );
  }

  @override
  Future<void> leave(String roomId) async {}
}

class _Audio implements VoiceRoomSession {
  final controller = StreamController<VoiceRoomSnapshot>.broadcast();
  @override
  Stream<VoiceRoomSnapshot> get changes => controller.stream;
  @override
  VoiceRoomSnapshot get snapshot =>
      const VoiceRoomSnapshot(phase: VoicePhase.connected);
  @override
  Future<void> connect(VoiceConnection connection) async {}
  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {}
  @override
  Future<void> setPlaybackEnabled(bool enabled) async {}
  @override
  Future<void> close() => controller.close();
}
