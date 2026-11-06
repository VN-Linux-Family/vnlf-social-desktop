import '../domain/profile_relationship.dart';
import 'profile_relationship_controller.dart';

/// Vietnamese-first copy for profile relationship actions.
final class ProfileRelationshipCopy {
  const ProfileRelationshipCopy({required this.english, required this.name});
  final bool english;
  final String name;

  String get follow => english ? 'Follow' : 'Theo dõi';
  String get following => english ? 'Following' : 'Đang theo dõi';
  String get signInToFollow =>
      english ? 'Sign in to follow $name' : 'Đăng nhập để theo dõi $name';
  String get updating => english ? 'Updating…' : 'Đang cập nhật…';
  String get block => english ? 'Block this person' : 'Chặn người này';
  String get unblock => english ? 'Unblock' : 'Bỏ chặn';
  String get unblockLabel => english ? 'Unblock $name' : 'Bỏ chặn $name';
  String get blockedHint =>
      english ? 'You blocked this person.' : 'Bạn đã chặn người này.';
  String get moreOptions => english ? 'Profile options' : 'Tùy chọn hồ sơ';
  String get cancel => english ? 'Cancel' : 'Hủy';
  String get confirmBlock => english ? 'Block' : 'Chặn';
  String get blockTitle => english ? 'Block $name?' : 'Chặn $name?';
  String get blockExplanation => english
      ? 'You will stop seeing each other’s posts in feeds and cannot message, '
            'follow or mention each other. $name is not notified.'
      : 'Hai bạn sẽ không thấy bài của nhau trên bảng tin, không nhắn tin, '
            'theo dõi hay mention được nhau. $name không nhận được thông báo '
            'nào về việc này.';
  String followToggleLabel(bool followed) => followed
      ? (english
            ? 'Following $name. Tap to unfollow'
            : 'Đang theo dõi $name. Chạm để bỏ theo dõi')
      : (english ? 'Follow $name' : 'Theo dõi $name');

  String done(ProfileRelationshipAction action) => switch (action) {
    ProfileRelationshipAction.follow =>
      english ? 'Now following $name' : 'Đang theo dõi $name',
    ProfileRelationshipAction.unfollow =>
      english ? 'Unfollowed $name' : 'Đã bỏ theo dõi $name',
    ProfileRelationshipAction.block =>
      english ? 'Blocked $name' : 'Đã chặn $name',
    ProfileRelationshipAction.unblock =>
      english ? 'Unblocked $name' : 'Đã bỏ chặn $name',
  };

  String failure(
    ProfileRelationshipFailure failure,
    ProfileRelationshipAction? attempted,
  ) => switch (failure) {
    RelationshipRejected() =>
      english
          ? 'This action is not available for this member.'
          : 'Không thực hiện được với thành viên này.',
    RelationshipUserMissing() =>
      english ? 'This member was not found.' : 'Không tìm thấy thành viên này.',
    RelationshipSignedOut() =>
      english
          ? 'Your session ended. Sign in again.'
          : 'Phiên đăng nhập đã hết. Hãy đăng nhập lại.',
    RelationshipRateLimited() =>
      english
          ? 'Too many requests. Try again shortly.'
          : 'Thao tác quá nhanh. Thử lại sau.',
    RelationshipUnconfirmed() =>
      english
          ? 'The result is not confirmed. Reload the profile to check.'
          : 'Chưa xác nhận được kết quả. Hãy tải lại hồ sơ để kiểm tra.',
    RelationshipNetworkFailure() => switch (attempted) {
      ProfileRelationshipAction.block =>
        english
            ? 'Could not block. Try again later.'
            : 'Chưa chặn được. Thử lại sau.',
      ProfileRelationshipAction.unblock =>
        english
            ? 'Could not unblock. Try again later.'
            : 'Chưa bỏ chặn được. Thử lại sau.',
      _ =>
        english
            ? 'Could not update following. Try again later.'
            : 'Chưa cập nhật được theo dõi. Thử lại sau.',
    },
  };
}
