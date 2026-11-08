import 'package:flutter/material.dart';
import 'package:vnlfsocialapp/src/features/settings/blocked/presentation/blocked_people_panel.dart';
import 'package:vnlfsocialapp/src/features/settings/preferences/preferences_panel.dart';
import 'package:vnlfsocialapp/src/features/settings/presentation/security_sessions_panel.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/live_voice_screen.dart';

// Live feature widgets whose route wrappers deliberately use offline demos
// during fixture runs. These panels exercise the production presentations.
Map<String, Widget> auditAuxiliarySurfaces() => {
  'voice-live': const LiveVoiceScreen(),
  'settings-sessions': ListView(
    padding: const EdgeInsets.all(16),
    children: const [SecuritySessionsPanel()],
  ),
  'settings-blocked': ListView(
    padding: const EdgeInsets.all(16),
    children: const [BlockedPeoplePanel()],
  ),
  'settings-privacy': ListView(
    padding: const EdgeInsets.all(16),
    children: const [PreferencesPanel()],
  ),
};
