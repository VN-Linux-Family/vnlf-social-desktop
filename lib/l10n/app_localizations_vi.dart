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

  @override
  String get messageNotificationTitle => 'Tin nhắn mới';

  @override
  String get messageNotificationBody => 'Bạn có tin nhắn mới';

  @override
  String get channelNotificationTitle => 'Kênh chat';

  @override
  String get channelNotificationBody => 'Có tin nhắn mới trong kênh';

  @override
  String get activityNotificationBody =>
      'Bạn có hoạt động mới trên Vietnam Linux Family.';
}
