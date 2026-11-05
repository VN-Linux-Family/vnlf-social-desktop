import 'dart:io';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';

bool _isOfflineDefault() {
  if (const bool.hasEnvironment('VNLF_LIVE')) {
    return !const bool.fromEnvironment('VNLF_LIVE');
  }
  try {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
  } catch (_) {}
  return false;
}

/// Offline fixture flag: false in production (live server), true during unit/widget tests.
final bool offlineFeatures = _isOfflineDefault();

const sampleAuthor = Author(
  id: 'user-sample-hoangnam',
  username: 'hoangnam',
  displayName: 'Hoàng Nam',
  style: AuthorStyle(
    distroBadge: 'arch',
    frame: {'id': 'ring', 'color': '#D97706'},
  ),
);

final samplePost = FeedPost(
  id: 'post-synth-1',
  author: sampleAuthor,
  title: 'Trải nghiệm Arch Linux và Wayland',
  excerpt: 'Chia sẻ cấu hình Arch Linux, Wayland và Hyprland cho máy cá nhân.',
  contentText:
      'Mình vừa chuyển sang Arch Linux và Wayland. '
      'Hyprland giúp bố trí cửa sổ gọn gàng và thao tác bằng bàn phím thuận tiện.\n\n'
      'Hãy thử trên máy ảo, sao lưu cấu hình và đọc tài liệu trước khi thay đổi hệ thống. '
      'Tiếng Việt: ặ ữ ờ ẫ ệ',
  tags: const ['Arch Linux', 'Wayland', 'Hyprland'],
  format: 'article',
  voteScore: 12,
  commentCount: 2,
  publishedAt: DateTime.utc(2026, 11, 4, 8),
);

const localCommentAuthor = AuthorData(
  id: 'local-guest',
  username: 'ban',
  displayName: 'Bạn',
);

const sampleComments = [
  CommentNodeData(
    id: 'comment-synth-1',
    author: AuthorData(
      id: 'user-sample-minhtri',
      username: 'minhtri',
      displayName: 'Minh Trí',
    ),
    relativeTime: '',
    body: 'Cảm ơn bạn đã chia sẻ! Mình cũng đang thử Wayland trên máy ảo.',
    voteScore: 3,
    replies: [
      CommentNodeData(
        id: 'comment-synth-2',
        author: AuthorData(
          id: 'user-sample-hoangnam',
          username: 'hoangnam',
          displayName: 'Hoàng Nam',
        ),
        relativeTime: '',
        body: 'Bạn nhớ sao lưu cấu hình trước khi thử nhé.',
        voteScore: 1,
      ),
    ],
  ),
];
