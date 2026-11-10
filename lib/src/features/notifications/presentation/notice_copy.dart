import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../domain/notifications_repository.dart';

/// The in-app location for [item], or null when only its link can open it.
String? noticeRoute(CommunityNotice item) {
  if (item.targetType == 'ARTICLE' && item.targetId.isNotEmpty) {
    return '/thread/${Uri.encodeComponent(item.targetId)}';
  }
  if (item.targetType == 'USER' && item.actor.username.isNotEmpty) {
    return '/profile/${Uri.encodeComponent(item.actor.username)}';
  }
  if (item.targetType == 'CONVERSATION' && item.targetId.isNotEmpty) {
    return '/messages/${Uri.encodeComponent(item.targetId)}';
  }
  if (item.targetType == 'FEEDBACK' && item.targetId.isNotEmpty) {
    return '/feedback/${Uri.encodeComponent(item.targetId)}';
  }
  final href = Uri.tryParse(item.href);
  if (item.targetType == 'GUESTBOOK' &&
      href != null &&
      !href.hasScheme &&
      !href.hasAuthority &&
      href.path.startsWith('/') &&
      href.pathSegments.length == 2 &&
      href.pathSegments.first == 'u' &&
      href.pathSegments.last.isNotEmpty &&
      href.queryParameters['tab'] == 'guestbook') {
    return '/profile/${Uri.encodeComponent(href.pathSegments.last)}?tab=guestbook';
  }
  if (href != null &&
      !href.hasScheme &&
      !href.hasAuthority &&
      href.pathSegments.length == 2 &&
      href.pathSegments.first == 'projects' &&
      href.pathSegments.last.isNotEmpty &&
      href.path.startsWith('/')) {
    return '/projects/${Uri.encodeComponent(href.pathSegments.last)}';
  }
  return null;
}

/// How the website files a notice for its badge colour and filter.
enum NoticeKind { like, comment, follow, points, system }

/// `notification-center.tsx`: the first rule that matches wins.
NoticeKind noticeKind(String type) => type.contains('liked')
    ? NoticeKind.like
    : type.contains('comment')
    ? NoticeKind.comment
    : type.contains('follow')
    ? NoticeKind.follow
    : type.contains('point')
    ? NoticeKind.points
    : NoticeKind.system;

/// The icon on the notice's badge, by type and then by kind.
VnlfLucide noticeIcon(String type) {
  if (type.contains('feedback')) return VnlfLucide.messageSquareText;
  if (type.startsWith('sticker-pack-')) return VnlfLucide.sticker;
  if (type.startsWith('project-')) return VnlfLucide.folderGit2;
  if (type.contains('mentioned')) return VnlfLucide.atSign;
  if (type.contains('replied')) return VnlfLucide.reply;
  return switch (noticeKind(type)) {
    NoticeKind.like => VnlfLucide.heart,
    NoticeKind.comment => VnlfLucide.messageCircle,
    NoticeKind.follow => VnlfLucide.userPlus,
    NoticeKind.points => VnlfLucide.trophy,
    NoticeKind.system => VnlfLucide.shield,
  };
}

/// The text after the names, as `notificationAction` in
/// `lib/notification-copy.ts` words it.
String notificationAction(String type, Map<String, Object?> payload) {
  final copy = vi.notificationCopy;
  if (type == 'moderation-content-removed') {
    return switch (payload['kind']) {
      'ARTICLE' => copy.daGoBaiDangCuaBan,
      'COMMENT' => copy.daGoBinhLuanCuaBan,
      'MESSAGE' || 'VOICE_MESSAGE' => copy.daGoTinNhanCuaBan,
      'GUESTBOOK_ENTRY' => copy.daGoLoiNhanCuaBan,
      'HELP_ANSWER' => copy.daGoTraLoiCuaBan,
      'PROFILE_ICON' => copy.daGoIconCuaBan,
      'PROFILE_DECOR' => copy.daDatLaiTrangTri,
      _ => copy.daGoNoiDungCuaBan,
    };
  }
  return switch (type) {
    'article-liked' => copy.daThichBaiVietCua,
    'comment-liked' => copy.daThichBinhLuanCua,
    'comment-mentioned' => copy.daNhacDenBanTrong,
    'comment-replied' => copy.daTraLoiBinhLuan,
    'comment-created' => copy.daBinhLuanVeBai,
    'user-followed' => copy.daTheoDoiBan,
    'guestbook-signed' => copy.daVietVaoSoLuuBut,
    'feedback-status' => copy.daCapNhatTicket,
    'feedback-reply' => copy.daTraLoiGopY,
    'feedback-member-reply' => copy.daNhanVeGopY,
    'sticker-pack-approved' => copy.daDuyetBoSticker,
    'sticker-pack-rejected' => copy.chuaDuyetBoSticker,
    'sticker-pack-unlisted' => copy.daGoBoStickerKhoiCho,
    'project-approved' => copy.daDuyetDuAn,
    'project-rejected' => copy.chuaDuyetDuAn,
    'project-changes-approved' => copy.daDuyetThayDoiDuAn,
    'project-changes-rejected' => copy.chuaDuyetThayDoiDuAn,
    'project-hidden' => copy.daAnDuAn,
    'project-repo-unavailable' => copy.repoDuAnMat,
    _ => copy.coCapNhatMoi,
  };
}

/// The line under the action (`notificationSnippet`): the moderation reason,
/// a comment's excerpt, or the target's title.
String notificationSnippet(CommunityNotice notice) {
  if (notice.type == 'moderation-content-removed') {
    final reason = format(vi.notificationCopy.lyDo, {'reason': notice.title});
    return notice.excerpt.isEmpty ? reason : '$reason · “${notice.excerpt}”';
  }
  if (notice.type.startsWith('comment-')) {
    return notice.summarized
        ? notice.excerpt
        : vi.notificationCopy.binhLuanKhongConKha;
  }
  return notice.title;
}

/// Up to two names, newest first, then how many more; "VNLF" for a notice
/// from the system.
({List<Author> shown, String more}) noticeActors(CommunityNotice notice) => (
  shown: notice.actors.take(2).toList(),
  more: notice.actorCount > 2
      ? format(vi.notificationCenter.vaNguoiKhac, {
          'value': notice.actorCount - 2,
        })
      : '',
);

/// The day heading, by the calendar in Vietnam (UTC+7) as the website reads
/// it: today, yesterday, or earlier.
String noticeDay(DateTime? updatedAt, DateTime now) {
  if (updatedAt == null) return vi.notificationCenter.truocDo;
  DateTime day(DateTime time) {
    final local = time.toUtc().add(const Duration(hours: 7));
    return DateTime.utc(local.year, local.month, local.day);
  }

  final notice = day(updatedAt);
  if (notice == day(now)) return vi.notificationCenter.homNay;
  if (notice == day(now.subtract(const Duration(days: 1)))) {
    return vi.notificationCenter.homQua;
  }
  return vi.notificationCenter.truocDo;
}

/// Whole hours or days since the notice changed, without "trước", as the
/// website writes it.
String noticeAge(DateTime? updatedAt, DateTime now) {
  if (updatedAt == null) return '';
  final hours = now.difference(updatedAt).inHours;
  if (hours <= 0) return vi.notificationCenter.vuaXong;
  if (hours < 24) return format(vi.notificationCenter.gio, {'hours': hours});
  return format(vi.notificationCenter.ngay, {'Math': hours ~/ 24});
}
