import 'package:flutter/widgets.dart';

import '../../../domain/models.dart';
import '../../../i18n/vi.dart';

String dmFailureMessage(
  BuildContext context,
  Object? failure, {
  bool mutation = false,
}) {
  if (failure is HttpFailure) {
    final codeMessage = _dmCodeMessage(context, failure.code);
    if (codeMessage != null) {
      return codeMessage;
    }
    if (failure.statusCode == 401) {
      return vi.app.common.phienDangNhapDa;
    }
    if (failure.statusCode == 403) {
      return vi.app.directMessages.banKhongTheThuc;
    }
    if (failure.statusCode == 404) {
      return vi.app.directMessages.khongTimThayCuoc;
    }
    if (failure.statusCode == 429) {
      return vi.app.common.banThaoTacQua;
    }
  }
  if (failure is RateLimited) {
    return vi.app.common.mayChuDangGioi;
  }
  if (failure is ParseFailure) {
    return vi.app.directMessages.khongDocDuocDu;
  }
  if (failure is TransportFailure) {
    return mutation
        ? vi.app.directMessages.chuaXacNhanDuoc
        : vi.app.directMessages.khongTaiDuocTin;
  }
  return mutation
      ? vi.app.directMessages.chuaXacNhanDuocThao
      : vi.app.directMessages.khongTaiDuocTinNhan;
}

String? _dmCodeMessage(BuildContext context, String? code) {
  if (code == null || code.isEmpty) return null;
  return switch (code.toUpperCase()) {
    'DM_SELF' => vi.app.directMessages.banKhongTheNhan,
    'DM_BLOCKED' => vi.app.directMessages.khongTheGuiTin,
    'DM_REQUEST_REQUIRED' => vi.app.directMessages.canGuiYeuCau,
    'DM_REQUEST_PENDING' => vi.app.directMessages.dangChoNguoiNhan,
    'DM_REQUEST_NOT_PENDING' => vi.app.directMessages.yeuCauNhanTin,
    'MESSAGE_EDIT_WINDOW_EXPIRED' => vi.app.directMessages.chiCoTheChinh,
    'ASSET_UPLOAD_INCOMPLETE' => vi.app.directMessages.tepDinhKemChua,
    'ASSET_TYPE_UNSUPPORTED' => vi.app.directMessages.dinhDangAnhDinh,
    'ASSET_TOO_LARGE' => vi.app.directMessages.anhDinhKemVuot,
    'ASSET_INVALID_IMAGE' => vi.app.directMessages.tepAnhDinhKem,
    _ => null,
  };
}

String formatDmTimestamp(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${local.day}/${local.month} $hh:$mm';
}
