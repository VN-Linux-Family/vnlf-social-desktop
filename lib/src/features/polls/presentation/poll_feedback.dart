import 'package:flutter/material.dart';

import '../../../domain/models.dart';
import '../../../i18n/vi.dart';

String pollFailureText(BuildContext context, AppFailure failure) {
  if (failure is HttpFailure) {
    if (failure.code == 'POLL_HAS_VOTES') {
      return vi.app.polls.binhChonDaCo;
    }
    if (failure.statusCode == 401) {
      return vi.app.polls.dangNhapLaiDe;
    }
    if (failure.statusCode == 404) {
      return vi.app.polls.binhChonNayKhong;
    }
    if (failure.statusCode == 429) {
      return vi.app.polls.vuiLongChoRoi;
    }
  }
  return vi.app.polls.chuaXacNhanDuoc;
}
