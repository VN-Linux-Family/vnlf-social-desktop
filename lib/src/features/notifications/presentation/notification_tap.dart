import 'dart:async';

import '../../../core/external_uri.dart';

/// Opens what a tapped system notification points at: an app route, or a
/// website page the app has no screen for.
void openNotificationTarget(
  String? payload, {
  required void Function(String route) go,
  required Future<bool> Function(Uri page) openWebsite,
}) {
  if (payload == null || payload.isEmpty) return;
  final page = externalWebUri(payload);
  if (page != null) {
    unawaited(openWebsite(page));
    return;
  }
  go(payload);
}
