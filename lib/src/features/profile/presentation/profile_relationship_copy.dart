import '../../../i18n/vi.dart';
import '../domain/profile_relationship.dart';
import 'profile_relationship_controller.dart';

/// Vietnamese-first copy for profile relationship actions.
final class ProfileRelationshipCopy {
  const ProfileRelationshipCopy({required this.name});
  final String name;

  String get follow => vi.common.theoDoi;
  String get following => vi.accountViews.dangTheoDoi;
  String get signInToFollow =>
      format(vi.app.profile.dangNhapDeTheo, {'name': name});
  String get updating => vi.accountViews.dangCapNhat;
  String get block => vi.guestbook.chanNguoiNay;
  String get unblock => vi.people.boChan;
  String get unblockLabel => format(vi.app.profile.boChan, {'name': name});
  String get blockedHint => vi.people.banDaChan;
  String get cancel => vi.common.huy;
  String get confirmBlock => vi.common.chan;
  String get blockTitle => format(vi.people.chanHoi, {'name': name});
  String get blockExplanation =>
      format(vi.people.chanGiaiThich, {'name': name});
  String followToggleLabel(bool followed) => followed
      ? format(vi.app.profile.dangTheoDoiCham, {'name': name})
      : format(vi.app.profile.theoDoi, {'name': name});

  String done(ProfileRelationshipAction action) => switch (action) {
    ProfileRelationshipAction.follow => format(vi.app.profile.dangTheoDoi, {
      'name': name,
    }),
    ProfileRelationshipAction.unfollow => format(vi.app.profile.daBoTheoDoi, {
      'name': name,
    }),
    ProfileRelationshipAction.block => format(vi.people.daChan, {'name': name}),
    ProfileRelationshipAction.unblock => format(vi.people.daBoChan, {
      'name': name,
    }),
  };

  String failure(
    ProfileRelationshipFailure failure,
    ProfileRelationshipAction? attempted,
  ) => switch (failure) {
    RelationshipRejected() => vi.app.profile.khongThucHienDuoc,
    RelationshipUserMissing() => vi.app.profile.khongTimThayThanh,
    RelationshipSignedOut() => vi.app.profile.phienDangNhapDa,
    RelationshipRateLimited() => vi.app.profile.thaoTacQuaNhanh,
    RelationshipUnconfirmed() => vi.app.profile.chuaXacNhanDuocKet,
    RelationshipNetworkFailure() => switch (attempted) {
      ProfileRelationshipAction.block => vi.people.chuaChanDuoc,
      ProfileRelationshipAction.unblock => vi.people.chuaBoChanDuoc,
      _ => vi.app.profile.chuaCapNhatDuoc,
    },
  };
}
