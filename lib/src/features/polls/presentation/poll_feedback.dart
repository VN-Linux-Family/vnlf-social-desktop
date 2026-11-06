import 'package:flutter/material.dart';

import '../../../domain/models.dart';

String pollFailureText(BuildContext context, AppFailure failure) {
  final en = Localizations.localeOf(context).languageCode == 'en';
  if (failure is HttpFailure) {
    if (failure.code == 'POLL_HAS_VOTES') {
      return en
          ? 'This poll already has votes and can no longer be edited.'
          : 'Bình chọn đã có phiếu và không thể sửa.';
    }
    if (failure.statusCode == 401) {
      return en
          ? 'Sign in again to save your choice.'
          : 'Đăng nhập lại để lưu lựa chọn.';
    }
    if (failure.statusCode == 404) {
      return en
          ? 'This poll is no longer available.'
          : 'Bình chọn này không còn khả dụng.';
    }
    if (failure.statusCode == 429) {
      return en
          ? 'Please wait before trying again.'
          : 'Vui lòng chờ rồi thử lại.';
    }
  }
  return en
      ? 'The change was not confirmed. Your previous choice is retained; refresh or try again.'
      : 'Chưa xác nhận được thay đổi. Lựa chọn trước được giữ lại; hãy tải lại hoặc thử lại.';
}
