import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../domain/account_profile.dart';

String profileFieldLabel(ProfileField field) => switch (field) {
  ProfileField.username => vi.app.common.tenNguoiDung,
  ProfileField.displayName => vi.settingsViews.tenHienThi,
  ProfileField.bio => vi.settingsViews.gioiThieu,
  ProfileField.website => vi.app.common.trangWeb,
};

String profileFieldError(ProfileField field, ProfileFieldError error) =>
    switch (error) {
      ProfileFieldError.required => vi.app.settings.khongDuocDeTrong,
      ProfileFieldError.tooShort => vi.app.settings.toiThieu3Ky,
      ProfileFieldError.tooLong => vi.app.settings.quaDai,
      ProfileFieldError.invalidCharacters => vi.app.settings.chiGomChuCai,
    };

String profileFailureMessage(AppFailure failure) => switch (failure) {
  HttpFailure(code: 'USERNAME_TAKEN') => vi.app.settings.tenNguoiDungNay,
  HttpFailure(statusCode: 401) => vi.app.settings.phienDangNhapDa,
  HttpFailure(statusCode: 404) => vi.app.settings.khongTimThayHo,
  HttpFailure(statusCode: 400 || 422) => vi.app.settings.mayChuKhongChap,
  HttpFailure(statusCode: >= 500) => vi.app.settings.mayChuGapSu,
  HttpFailure() => vi.app.settings.yeuCauBiTu,
  RateLimited() => vi.app.settings.quaNhieuYeuCau,
  TransportFailure() => vi.app.settings.khongKetNoiDuoc,
  ParseFailure() => vi.app.settings.phanHoiMayChu,
  StorageFailure() => vi.app.settings.khongTheTruyCap,
};
