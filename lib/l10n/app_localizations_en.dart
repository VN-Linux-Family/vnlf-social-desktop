// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vietnam Linux Family';

  @override
  String get backgroundNotificationsTitle => 'Background notifications';

  @override
  String get backgroundNotificationsSubtitle =>
      'Keeps the connection open while the app runs in the background so new messages and activity can notify you. Nothing arrives after the app is fully closed.';
}
