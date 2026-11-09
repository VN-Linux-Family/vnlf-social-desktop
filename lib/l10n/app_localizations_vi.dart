// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Vietnam Linux Family';

  @override
  String get backgroundNotificationsTitle => 'Thông báo khi chạy nền';

  @override
  String get backgroundNotificationsSubtitle =>
      'Giữ kết nối khi ứng dụng chạy nền để báo tin nhắn và hoạt động mới. Đóng hẳn ứng dụng thì sẽ không nhận được thông báo.';
}
