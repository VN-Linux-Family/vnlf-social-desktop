import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../settings/preferences/preferences_controller.dart';
import '../data/media_kit_chime_output.dart';
import '../domain/community_sounds.dart';

/// Plays a chime on this device.
final chimeOutputProvider = Provider<PlayChime>((ref) {
  final output = MediaKitChimeOutput();
  ref.onDispose(() => unawaited(output.dispose()));
  return output.play;
});

/// The chime rules for the signed-in member. Another account starts afresh,
/// as the website forgets its chimes on sign-out.
final communitySoundsProvider = Provider<CommunitySounds>((ref) {
  ref.watch(sessionStateProvider.select((session) => session?.userId));
  return CommunitySounds(ref.watch(chimeOutputProvider));
});

/// Whether chimes may ring: the member's saved choice, once it has loaded,
/// as the website waits for its preferences before ringing.
final chimesEnabledProvider = Provider.autoDispose<bool>((ref) {
  if (ref.watch(sessionStateProvider) == null) return false;
  return ref.watch(
    preferencesControllerProvider.select(
      (state) => state.confirmed?.messageSoundEnabled ?? false,
    ),
  );
});
