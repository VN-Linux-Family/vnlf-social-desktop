import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

final class VietnameseEditorLocalizations extends FleatherLocalizations {
  VietnameseEditorLocalizations() : super('vi');
  static const delegate = _VietnameseEditorDelegate();
  @override
  String get foregroundColorAutomatic => 'Tự động';
  @override
  String get backgroundColorNoColor => 'Không màu';
  @override
  String get headingNormal => 'Văn bản thường';
  @override
  String get headingLevel1 => 'Tiêu đề 1';
  @override
  String get headingLevel2 => 'Tiêu đề 2';
  @override
  String get headingLevel3 => 'Tiêu đề 3';
  @override
  String get headingLevel4 => 'Tiêu đề 4';
  @override
  String get headingLevel5 => 'Tiêu đề 5';
  @override
  String get headingLevel6 => 'Tiêu đề 6';
  @override
  String get addLinkDialogPasteLink => 'Dán liên kết';
  @override
  String get addLinkDialogApply => 'Áp dụng';
  @override
  String get linkDialogOpen => 'Mở';
  @override
  String get linkDialogCopy => 'Sao chép';
  @override
  String get linkDialogRemove => 'Gỡ liên kết';
}

final class _VietnameseEditorDelegate
    extends LocalizationsDelegate<FleatherLocalizations> {
  const _VietnameseEditorDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'vi';
  @override
  Future<FleatherLocalizations> load(Locale locale) =>
      SynchronousFuture(VietnameseEditorLocalizations());
  @override
  bool shouldReload(_VietnameseEditorDelegate old) => false;
}
