import 'package:flutter/widgets.dart';

import '../../../domain/models.dart';

String dmText(BuildContext context, String vi, String en) {
  final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'vi';
  return code == 'en' ? en : vi;
}

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
      return dmText(
        context,
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        'Your session has expired. Please sign in again.',
      );
    }
    if (failure.statusCode == 403) {
      return dmText(
        context,
        'Bạn không thể thực hiện thao tác này trong trạng thái cuộc trò chuyện hiện tại.',
        'This action is not allowed in the current conversation state.',
      );
    }
    if (failure.statusCode == 404) {
      return dmText(
        context,
        'Không tìm thấy cuộc trò chuyện hoặc tin nhắn.',
        'Conversation or message not found.',
      );
    }
    if (failure.statusCode == 429) {
      return dmText(
        context,
        'Bạn thao tác quá nhanh. Vui lòng chờ rồi thử lại.',
        'Too many requests. Please wait before trying again.',
      );
    }
  }
  if (failure is RateLimited) {
    return dmText(
      context,
      'Máy chủ đang giới hạn yêu cầu. Vui lòng thử lại sau.',
      'The server is limiting requests. Please try again later.',
    );
  }
  if (failure is ParseFailure) {
    return dmText(
      context,
      'Không đọc được dữ liệu tin nhắn từ máy chủ. Hãy thử làm mới.',
      'The server response could not be read. Try refreshing.',
    );
  }
  if (failure is TransportFailure) {
    return mutation
        ? dmText(
            context,
            'Chưa xác nhận được thao tác do lỗi mạng. Nội dung nháp được giữ lại để bạn thử lại.',
            'Network error before confirmation. Your draft was kept so you can retry.',
          )
        : dmText(
            context,
            'Không tải được tin nhắn trực tiếp. Kiểm tra kết nối rồi thử lại.',
            'Direct messages could not be loaded. Check your connection and try again.',
          );
  }
  return mutation
      ? dmText(
          context,
          'Chưa xác nhận được thao tác. Nội dung được giữ lại; hãy làm mới hoặc thử lại.',
          'The action could not be confirmed. Your draft is retained; refresh or try again.',
        )
      : dmText(
          context,
          'Không tải được tin nhắn trực tiếp.',
          'Could not load direct messages.',
        );
}

String? _dmCodeMessage(BuildContext context, String? code) {
  if (code == null || code.isEmpty) return null;
  return switch (code.toUpperCase()) {
    'DM_SELF' => dmText(
      context,
      'Bạn không thể nhắn tin trực tiếp cho chính mình.',
      'You cannot send a direct message to yourself.',
    ),
    'DM_BLOCKED' => dmText(
      context,
      'Không thể gửi tin nhắn vì một trong hai bên đã chặn liên lạc.',
      'Cannot send messages because one of the participants has blocked communication.',
    ),
    'DM_REQUEST_REQUIRED' => dmText(
      context,
      'Cần gửi yêu cầu nhắn tin mới trước khi tiếp tục trò chuyện.',
      'A new message request is required before continuing this conversation.',
    ),
    'DM_REQUEST_PENDING' => dmText(
      context,
      'Đang chờ người nhận chấp nhận yêu cầu nhắn tin của bạn.',
      'Waiting for the recipient to accept your message request.',
    ),
    'DM_REQUEST_NOT_PENDING' => dmText(
      context,
      'Yêu cầu nhắn tin này đã được xử lý trước đó.',
      'This message request has already been handled.',
    ),
    'MESSAGE_EDIT_WINDOW_EXPIRED' => dmText(
      context,
      'Chỉ có thể chỉnh sửa tin nhắn trong vòng 15 phút sau khi gửi.',
      'Messages can only be edited within 15 minutes of sending.',
    ),
    'ASSET_UPLOAD_INCOMPLETE' => dmText(
      context,
      'Tệp đính kèm chưa tải lên hoàn tất. Vui lòng thử lại.',
      'Attachment upload is incomplete. Please try again.',
    ),
    'ASSET_TYPE_UNSUPPORTED' => dmText(
      context,
      'Định dạng ảnh đính kèm không được hỗ trợ.',
      'Unsupported image attachment format.',
    ),
    'ASSET_TOO_LARGE' => dmText(
      context,
      'Ảnh đính kèm vượt quá giới hạn 10 MB.',
      'Image attachment exceeds the 10 MB limit.',
    ),
    'ASSET_INVALID_IMAGE' => dmText(
      context,
      'Tệp ảnh đính kèm không hợp lệ hoặc bị hỏng.',
      'The attached image file is invalid or corrupted.',
    ),
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
