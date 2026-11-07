import 'package:flutter/material.dart';

import '../../shared/presentation/feature_samples.dart' show offlineFeatures;
import 'fixture_voice_screen.dart';
import 'live_voice_screen.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      offlineFeatures ? const FixtureVoiceScreen() : const LiveVoiceScreen();
}
