import '../../../domain/models.dart';
import '../../../i18n/vi.dart';

String composerFailureText(Object failure) {
  if (failure is ParseFailure) {
    final messages = <String, String>{
      'composer.empty': vi.app.composer.vietNoiDungHoac,
      'composer.pollInvalid': vi.app.composer.nhapCauHoiVa,
      'composer.pollLocked': vi.app.composer.khongTheThayHoac,
      'composer.pollPostOnly': vi.app.composer.binhChonChiDung,
      'composer.missingAsset': vi.app.composer.motSoAnhCan,
      'composer.metadata': vi.app.composer.kiemTraDoDai,
      'composer.tags': vi.app.composer.dungToiDa3,
      'composer.attachments': vi.app.composer.toiDa20Tep,
      'composer.videoPostOnly': vi.app.composer.videoChiDuocDung,
      'composer.videoDuration': vi.app.composer.videoKhongDuocDai,
      'composer.mediaNotReady': vi.app.composer.choVideoXuLy,
      'composer.postInlineImage': vi.app.composer.chuyenAnhTrongBai,
      'composer.assetLimit': vi.app.composer.dungToiDa21,
      'upload.size': vi.app.composer.anhToiDa10,
      'upload.placement': vi.app.composer.chonDinhDangAnh,
      'composer.publishUncertain': vi.app.composer.kiemTraLanDang,
    };
    final copy = messages[failure.field];
    if (copy != null) return copy;
  }
  if (failure is StorageFailure) {
    return vi.app.composer.khongLuuDuocBan;
  }
  if (failure is HttpFailure && failure.statusCode == 429) {
    return vi.app.composer.mayChuDangGioi;
  }
  if (failure is HttpFailure && failure.code == 'ARTICLE_VERSION_CONFLICT') {
    return vi.app.composer.banNhapDaThay;
  }
  return vi.app.composer.chuaLuuDuocBan;
}
