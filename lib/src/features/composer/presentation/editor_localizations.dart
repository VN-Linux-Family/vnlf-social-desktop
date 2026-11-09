import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../i18n/vi.dart';

final class VietnameseEditorLocalizations extends FleatherLocalizations {
  VietnameseEditorLocalizations() : super('vi');
  static const delegate = _VietnameseEditorDelegate();
  @override
  String get foregroundColorAutomatic => vi.app.composer.tuDong;
  @override
  String get backgroundColorNoColor => vi.app.composer.khongMau;
  @override
  String get headingNormal => vi.app.composer.vanBanThuong;
  @override
  String get headingLevel1 => vi.app.composer.tieuDe1;
  @override
  String get headingLevel2 => vi.app.composer.tieuDe2;
  @override
  String get headingLevel3 => vi.app.composer.tieuDe3;
  @override
  String get headingLevel4 => vi.app.composer.tieuDe4;
  @override
  String get headingLevel5 => vi.app.composer.tieuDe5;
  @override
  String get headingLevel6 => vi.app.composer.tieuDe6;
  @override
  String get addLinkDialogPasteLink => vi.app.composer.danLienKet;
  @override
  String get addLinkDialogApply => vi.articleEditor.apDung;
  @override
  String get linkDialogOpen => vi.app.composer.mo;
  @override
  String get linkDialogCopy => vi.socialOverlays.saoChep;
  @override
  String get linkDialogRemove => vi.app.composer.goLienKet;
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
