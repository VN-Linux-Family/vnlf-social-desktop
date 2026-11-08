import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/features/auth/presentation/login_screen.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_models.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/live_voice_controls.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/voice_session_controller.dart';

import '../tool/ux_audit_fixtures.dart';

void _expectReadable(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  expect(
    (math.max(a, b) + .05) / (math.min(a, b) + .05),
    greaterThanOrEqualTo(4.5),
  );
}

void main() {
  for (final connected in [false, true]) {
    testWidgets('dark voice ${connected ? 'leave' : 'join'} text meets AA', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VnlfTheme.dark(),
          home: Scaffold(
            body: LiveVoiceControls(
              state: VoiceSessionState(
                phase: connected
                    ? VoicePhase.connected
                    : VoicePhase.disconnected,
                roomId: connected ? auditVoiceRoom.id : null,
              ),
              room: auditVoiceRoom,
              onJoin: () {},
              onLeave: () {},
              onMicrophone: () {},
              onDeafen: () {},
            ),
          ),
        ),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      _expectReadable(
        button.style!.foregroundColor!.resolve({})!,
        button.style!.backgroundColor!.resolve({})!,
      );
    });
  }
  testWidgets('dark auth action and its explicit text meet AA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: auditOverrides(),
        child: MaterialApp(theme: VnlfTheme.dark(), home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final background = button.style!.backgroundColor!.resolve({})!;
    _expectReadable(button.style!.foregroundColor!.resolve({})!, background);
    final text = tester.widget<Text>(find.text('Enter VNLF Social'));
    _expectReadable(text.style!.color!, background);
  });
}
