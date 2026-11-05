import 'package:flutter/material.dart';

import '../../../domain/models.dart';

String channelText(BuildContext context, String vi, String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : vi;

String channelFailure(
  BuildContext context,
  Object? failure, {
  bool mutation = false,
}) {
  if (failure is HttpFailure) {
    if (failure.statusCode == 401) {
      return channelText(
        context,
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        'Your session has expired. Please sign in again.',
      );
    }
    if (failure.statusCode == 403) {
      return channelText(
        context,
        'Bạn chưa có quyền truy cập nội dung này.',
        'You do not have access to this content.',
      );
    }
    if (failure.statusCode == 404) {
      return channelText(
        context,
        'Kênh hoặc tin nhắn không còn tồn tại.',
        'This channel or message no longer exists.',
      );
    }
    if (failure.statusCode == 429) {
      return channelText(
        context,
        'Bạn thao tác quá nhanh. Vui lòng chờ rồi thử lại.',
        'Too many requests. Please wait before trying again.',
      );
    }
  }
  if (failure is RateLimited) {
    return channelText(
      context,
      'Máy chủ đang giới hạn yêu cầu. Vui lòng thử lại sau.',
      'The server is limiting requests. Please try again later.',
    );
  }
  if (failure is ParseFailure) {
    return channelText(
      context,
      'Không đọc được dữ liệu từ máy chủ. Hãy thử làm mới.',
      'The server response could not be read. Try refreshing.',
    );
  }
  return mutation
      ? channelText(
          context,
          'Chưa xác nhận được thao tác. Nội dung được giữ lại; hãy làm mới trước khi gửi lại.',
          'The action could not be confirmed. Your draft is retained; refresh before sending again.',
        )
      : channelText(
          context,
          'Không tải được tin nhắn. Kiểm tra kết nối rồi thử lại.',
          'Messages could not be loaded. Check your connection and try again.',
        );
}
