import '../../../domain/models.dart';
import '../domain/account_profile.dart';

String profileFieldLabel(ProfileField field, bool english) => switch (field) {
  ProfileField.username => english ? 'Username' : 'Tên người dùng',
  ProfileField.displayName => english ? 'Display name' : 'Tên hiển thị',
  ProfileField.bio => english ? 'Bio' : 'Giới thiệu',
  ProfileField.website => english ? 'Website' : 'Trang web',
};

String profileFieldError(
  ProfileField field,
  ProfileFieldError error,
  bool english,
) => switch (error) {
  ProfileFieldError.required => english ? 'Required.' : 'Không được để trống.',
  ProfileFieldError.tooShort =>
    english ? 'At least 3 characters.' : 'Tối thiểu 3 ký tự.',
  ProfileFieldError.tooLong => english ? 'Too long.' : 'Quá dài.',
  ProfileFieldError.invalidCharacters =>
    english
        ? 'Letters, digits, dots and underscores only.'
        : 'Chỉ gồm chữ cái, chữ số, dấu chấm và gạch dưới.',
};

String profileFailureMessage(
  AppFailure failure,
  bool english,
) => switch (failure) {
  HttpFailure(code: 'USERNAME_TAKEN') =>
    english
        ? 'This username is already taken or reserved.'
        : 'Tên người dùng này đã được sử dụng hoặc đang được giữ chỗ.',
  HttpFailure(statusCode: 401) =>
    english
        ? 'Your session has ended. Please sign in again.'
        : 'Phiên đăng nhập đã kết thúc. Vui lòng đăng nhập lại.',
  HttpFailure(statusCode: 404) =>
    english ? 'Profile not found.' : 'Không tìm thấy hồ sơ.',
  HttpFailure(statusCode: 400 || 422) =>
    english
        ? 'The server rejected these values.'
        : 'Máy chủ không chấp nhận các giá trị này.',
  HttpFailure(statusCode: >= 500) =>
    english
        ? 'The server had a problem. The change may not have been saved.'
        : 'Máy chủ gặp sự cố. Thay đổi có thể chưa được lưu.',
  HttpFailure() => english ? 'The request was refused.' : 'Yêu cầu bị từ chối.',
  RateLimited() =>
    english
        ? 'Too many requests. Please wait a moment.'
        : 'Quá nhiều yêu cầu. Vui lòng chờ một lát.',
  TransportFailure() =>
    english
        ? 'No connection to the server. The change may not have been saved.'
        : 'Không kết nối được máy chủ. Thay đổi có thể chưa được lưu.',
  ParseFailure() =>
    english
        ? 'Unexpected server response. The change may not have been saved.'
        : 'Phản hồi máy chủ không hợp lệ. Thay đổi có thể chưa được lưu.',
  StorageFailure() =>
    english ? 'Could not access local storage.' : 'Không thể truy cập bộ nhớ.',
};
