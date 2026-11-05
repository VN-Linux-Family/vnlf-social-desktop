import '../../../domain/models.dart';

String composerFailureText(Object failure, bool english) {
  if (failure is ParseFailure) {
    final messages = <String, (String, String)>{
      'composer.empty': (
        'Write some content or add media before publishing.',
        'Viết nội dung hoặc thêm ảnh, video trước khi đăng.',
      ),
      'composer.missingAsset': (
        'Some images need uploading before switching formats. Your article is kept.',
        'Một số ảnh cần được tải lên trước khi đổi định dạng. Bài viết vẫn được giữ.',
      ),
      'composer.metadata': (
        'Check the title, excerpt and cover text lengths.',
        'Kiểm tra độ dài tiêu đề, mô tả và văn bản ảnh bìa.',
      ),
      'composer.tags': (
        'Use up to 3 tags, each at most 40 characters.',
        'Dùng tối đa 3 thẻ, mỗi thẻ không quá 40 ký tự.',
      ),
      'composer.attachments': (
        'Up to 20 attachments and one video are allowed.',
        'Tối đa 20 tệp đính kèm và một video.',
      ),
      'composer.videoPostOnly': (
        'Videos are supported in regular posts only.',
        'Video chỉ được dùng trong bài đăng thường.',
      ),
      'composer.videoDuration': (
        'Video must be 30 seconds or shorter.',
        'Video không được dài quá 30 giây.',
      ),
      'composer.mediaNotReady': (
        'Wait for video processing or remove failed media before publishing.',
        'Chờ video xử lý xong hoặc gỡ tệp lỗi trước khi đăng.',
      ),
      'composer.postInlineImage': (
        'Move article images into attachments before switching to a regular post.',
        'Chuyển ảnh trong bài thành tệp đính kèm trước khi đổi sang bài thường.',
      ),
      'composer.assetLimit': (
        'Use up to 21 images including the cover.',
        'Dùng tối đa 21 ảnh kể cả ảnh bìa.',
      ),
      'upload.size': (
        'Images must be at most 10 MiB and videos at most 200 MiB.',
        'Ảnh tối đa 10 MiB, video tối đa 200 MiB.',
      ),
      'upload.placement': (
        'Choose a supported image or a video for a regular post.',
        'Chọn định dạng ảnh được hỗ trợ hoặc video cho bài thường.',
      ),
      'composer.publishUncertain': (
        'Check the pending publication before editing again.',
        'Kiểm tra lần đăng đang chờ xác nhận trước khi sửa tiếp.',
      ),
    };
    final copy = messages[failure.field];
    if (copy != null) return english ? copy.$1 : copy.$2;
  }
  if (failure is StorageFailure) {
    return english
        ? 'Could not keep a recovery copy on this device. Your editor is still open.'
        : 'Không lưu được bản khôi phục trên thiết bị. Nội dung vẫn còn trong trình soạn thảo.';
  }
  if (failure is HttpFailure && failure.statusCode == 429) {
    return english
        ? 'The server is limiting requests. Your draft is kept; try again later.'
        : 'Máy chủ đang giới hạn yêu cầu. Bản nháp được giữ; vui lòng thử lại sau.';
  }
  if (failure is HttpFailure && failure.code == 'ARTICLE_VERSION_CONFLICT') {
    return english
        ? 'This draft changed on another device. Compare versions before saving.'
        : 'Bản nháp đã thay đổi trên thiết bị khác. Chọn phiên bản trước khi lưu.';
  }
  return english
      ? 'Could not save. Your draft is kept; try again.'
      : 'Chưa lưu được. Bản nháp vẫn được giữ; vui lòng thử lại.';
}
