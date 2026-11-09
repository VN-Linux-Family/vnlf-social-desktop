import 'package:flutter/material.dart';

import '../../../domain/models.dart';
import '../../../i18n/vi.dart';

String channelFailure(
  BuildContext context,
  Object? failure, {
  bool mutation = false,
}) {
  if (failure is HttpFailure) {
    if (failure.statusCode == 401) {
      return (vi.app.common.phienDangNhapDa);
    }
    if (failure.statusCode == 403) {
      return (vi.app.channels.banChuaCoQuyen);
    }
    if (failure.statusCode == 404) {
      return (vi.app.channels.kenhHoacTinNhan);
    }
    if (failure.statusCode == 429) {
      return (vi.app.common.banThaoTacQua);
    }
  }
  if (failure is RateLimited) {
    return (vi.app.common.mayChuDangGioi);
  }
  if (failure is ParseFailure) {
    return (vi.app.channels.khongDocDuocDu);
  }
  return mutation
      ? (vi.app.channels.chuaXacNhanDuoc)
      : (vi.app.channels.khongTaiDuocTin);
}
