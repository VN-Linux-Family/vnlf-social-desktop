import '../../design_system/design_system.dart';

/// Synthetic Vietnamese fixtures for the Gallery and 3 key screens (`feed`, `thread`, `profile`).
///
/// Strictly compliant with zero-reference-content rules: 100% synthetic discussions,
/// invented identities, and neutral placeholders. Zero production names or screenshot text.
abstract final class VnlfGalleryFixtures {
  /// Mandatory Vietnamese diacritic verification phrase.
  static const String diacriticSample = 'Tiếng Việt: ặ ữ ờ ẫ ệ';

  // Shell sample labels
  static const Map<VnlfNavDestination, String> destinationLabels = {
    VnlfNavDestination.feed: 'Bảng tin',
    VnlfNavDestination.explore: 'Khám phá',
    VnlfNavDestination.messages: 'Tin nhắn',
    VnlfNavDestination.voice: 'Voice',
    VnlfNavDestination.projects: 'Dự án',
  };

  static const String brandTitlePrefix = 'VNLF ';
  static const String brandTitleAccent = 'Social';
  static const String brandLogoSemanticLabel = 'Biểu trưng VNLF Social';
  static const String loginLabel = 'Đăng nhập';
  static const String loginSubtitleLabel = 'Để dùng đầy đủ tí...';
  static const String supportLabel = 'Hỗ trợ cộng đồng';
  static const String supportBadgeText = '3';
  static const String feedbackLabel = 'Góp ý & báo lỗi';
  static const String socialSectionLabel = 'VNLF trên các mạng xã hội khác';
  static const String facebookBadgeLabel = 'f';
  static const String facebookSemanticLabel = 'Facebook cộng đồng';
  static const String telegramSemanticLabel = 'Telegram cộng đồng';
  static const String discordSemanticLabel = 'Discord cộng đồng';
  static const String settingsLabel = 'Cài đặt';
  static const String helpLabel = 'Trợ giúp';
  static const String lightThemeTooltip = 'Sáng';
  static const String darkThemeTooltip = 'Tối';
  static const String systemThemeTooltip = 'Tự động';
  static const String themePickerSemanticLabel = 'Chọn giao diện sáng tối';
  static const String openDrawerTooltip = 'Mở menu';
  static const String searchSemanticLabel = 'Tìm kiếm';
  static const String notificationsSemanticLabel = 'Thông báo';
  static const String profileSemanticLabel = 'Tài khoản cá nhân';

  // Leaderboard sample labels
  static const String leaderboardTitle = 'Xếp hạng tuần';
  static const String leaderboardViewAllLabel = 'Xem tất cả ↗';
  static const String footerCopyright = 'VNLF Social · 2026';
  static const String communityRulesLabel = 'Quy chuẩn cộng đồng';
  static const String privacyLabel = 'Riêng tư';
  static const String leaderboardEmptyTitle = 'Chưa có dữ liệu xếp hạng';
  static const String leaderboardEmptyMessage =
      'Bảng xếp hạng tuần này đang được cập nhật.';
  static const String leaderboardErrorTitle = 'Không thể tải bảng xếp hạng';
  static const String leaderboardErrorMessage =
      'Đã xảy ra sự cố khi tải dữ liệu xếp hạng tuần.';
  static const String leaderboardLoadingSemanticLabel =
      'Đang tải bảng xếp hạng tuần';

  // Feed & Post sample labels
  static const String composerPromptText = 'Hôm nay bạn muốn chia sẻ điều gì?';
  static const String addMediaSemanticLabel = 'Thêm hình ảnh đính kèm';
  static const String codeCopyLabel = 'Sao chép';
  static const String codeCopiedLabel = 'Đã chép';
  static const String commentReplyLabel = 'Trả lời';
  static const String upvoteSemanticLabel = 'Bình chọn tăng';
  static const String downvoteSemanticLabel = 'Bình chọn giảm';
  static const String commentActionSemanticLabel = 'Xem bình luận';
  static const String shareActionSemanticLabel = 'Sao chép liên kết';
  static const String bookmarkActionSemanticLabel = 'Lưu bài viết';
  static const String moreOptionsSemanticLabel = 'Tùy chọn bài viết';
  static const String feedEmptyTitle = 'Chưa có bài viết nào';
  static const String feedEmptyMessage =
      'Bảng tin hiện chưa có bài viết trong mục này. Hãy thử chuyển sang mục khác hoặc làm mới.';
  static const String refreshActionLabel = 'Làm mới';
  static const String feedErrorTitle = 'Không thể tải bảng tin';
  static const String feedErrorMessage =
      'Đã xảy ra sự cố khi tải danh sách bài viết. Vui lòng kiểm tra kết nối và thử lại.';
  static const String retryActionLabel = 'Thử lại';
  static const String postCardSkeletonSemanticLabel = 'Đang tải bài viết';
  static const String feedSkeletonListSemanticLabel =
      'Đang tải danh sách bài viết bảng tin';

  static String voteCapsuleSemanticLabel(int score) =>
      'Bình chọn bài viết, điểm hiện tại $score';

  static String distroBadgeLabel(DistroBadgeType badge) => switch (badge) {
    DistroBadgeType.none => '',
    DistroBadgeType.arch => 'arch',
    DistroBadgeType.debian => 'debian',
    DistroBadgeType.cachyos => 'cachyos',
    DistroBadgeType.caramos => 'caramos',
    DistroBadgeType.nixos => 'nixos',
    DistroBadgeType.fedora => 'fedora',
    DistroBadgeType.ubuntu => 'ubuntu',
    DistroBadgeType.kali => 'kali',
    DistroBadgeType.gentoo => 'gentoo',
    DistroBadgeType.mint => 'mint',
    DistroBadgeType.linux => 'linux',
    DistroBadgeType.opensuse => 'opensuse',
  };

  static const AuthorData authorNam = AuthorData(
    id: '00000000-0000-7000-8000-000000000011',
    username: 'tranvannam',
    displayName: 'Trần Văn Nam',
    role: 'MEMBER',
    style: AuthorStyleData(
      frame: AvatarFrameType.ring,
      distroBadge: DistroBadgeType.fedora,
      distroBadgeLabel: 'fedora',
      hasTerminalBadge: true,
    ),
  );

  static const AuthorData authorMai = AuthorData(
    id: '00000000-0000-7000-8000-000000000012',
    username: 'lethimai',
    displayName: 'Lê Thị Mai',
    role: 'CONTRIBUTOR',
    style: AuthorStyleData(
      frame: AvatarFrameType.none,
      distroBadge: DistroBadgeType.nixos,
      distroBadgeLabel: 'nixos',
      hasPartnerStar: true,
    ),
  );

  static const AuthorData authorBao = AuthorData(
    id: '00000000-0000-7000-8000-000000000013',
    username: 'phamlqbao',
    displayName: 'Phạm Quốc Bảo',
    role: 'MEMBER',
    style: AuthorStyleData(
      frame: AvatarFrameType.none,
      distroBadge: DistroBadgeType.arch,
      distroBadgeLabel: 'arch',
      hasPixelBadge: true,
    ),
  );

  static const AuthorData authorHa = AuthorData(
    id: '00000000-0000-7000-8000-000000000014',
    username: 'hoangthibaoha',
    displayName: 'Hoàng Bảo Hà',
    role: 'MODERATOR',
    style: AuthorStyleData(
      frame: AvatarFrameType.ring,
      distroBadge: DistroBadgeType.debian,
      distroBadgeLabel: 'debian',
      hasTerminalBadge: true,
    ),
  );

  static const List<LeaderboardEntryData> weeklyLeaderboard = [
    LeaderboardEntryData(rank: 1, author: authorMai, points: 88),
    LeaderboardEntryData(rank: 2, author: authorNam, points: 74),
    LeaderboardEntryData(rank: 3, author: authorBao, points: 65),
  ];

  static const List<PostData> feedPosts = [
    PostData(
      id: 'post-pipewire-audio-01',
      author: authorNam,
      relativeTime: '2 giờ',
      paragraphs: [
        'Chia sẻ kinh nghiệm tinh chỉnh bộ đệm âm thanh PipeWire và WirePlumber để đạt độ trễ siêu thấp khi làm việc với các phần mềm xử lý âm thanh số trên Linux.',
        'Sau khi cấu hình quantum 64/48000 trong pipewire.conf, hệ thống xử lý hoàn toàn trơn tru mà không gặp hiện tượng xé tiếng (xruns).',
      ],
      attachment: ImagePlaceholderAttachment(
        aspectRatio: 16 / 9,
        label: 'Sơ đồ định tuyến luồng âm thanh PipeWire & JACK',
        semanticLabel: 'Hình minh họa sơ đồ định tuyến luồng âm thanh PipeWire',
      ),
      voteScore: 12,
      viewerVote: VoteState.neutral,
      commentCount: 4,
    ),
    PostData(
      id: 'post-shell-script-02',
      author: authorMai,
      relativeTime: '4 giờ',
      paragraphs: [
        'Mẹo dòng lệnh: Sử dụng GNU Parallel kết hợp ffmpeg để trích xuất âm thanh FLAC đa luồng nhanh gấp 4 lần so với vòng lặp tuần tự.',
        'Đoạn script ngắn gọn sử dụng cú pháp chuẩn POSIX và hỗ trợ thư mục Tiếng Việt: ặ ữ ờ ẫ ệ:',
      ],
      attachment: CodeBlockAttachment(
        language: 'bash',
        copyLabel: codeCopyLabel,
        copiedLabel: codeCopiedLabel,
        semanticLabel: 'Đoạn mã bash chuyển đổi âm thanh đa luồng',
        code:
            '#!/usr/bin/env bash\n'
            '# Chuyển đổi video đa luồng với GNU Parallel\n'
            'find ./video -type f -name "*.mkv" | \\\n'
            '  parallel -j 4 ffmpeg -i {} -vn -c:a flac {.}.flac\n'
            '\n'
            'echo "Hoàn thành xử lý đa luồng!"',
      ),
      voteScore: 24,
      viewerVote: VoteState.upvoted,
      commentCount: 7,
    ),
    PostData(
      id: 'post-flutter-wayland-03',
      author: authorBao,
      relativeTime: '7 giờ',
      isArticle: true,
      title: 'Xây dựng ứng dụng Flutter native mượt mà trên môi trường Wayland',
      paragraphs: [
        'Kiến trúc render Impeller trên Linux desktop hiện đã hỗ trợ tốt tính năng tăng tốc phần cứng qua EGL. Nhờ phông chữ Be Vietnam Pro và cấu hình fontconfig hợp lý, các ký tự Tiếng Việt: ặ ữ ờ ẫ ệ hiển thị sắc nét ở mọi độ phân giải.',
      ],
      tags: ['flutter', 'linux', 'wayland', 'tiengviet'],
      attachment: ProjectPreviewAttachment(project: projectFlutterWayland),
      voteScore: 56,
      viewerVote: VoteState.upvoted,
      commentCount: 15,
      isBookmarked: true,
    ),
  ];

  static const PostData threadDetailPost = PostData(
    id: 'thread-detail-pipewire-01',
    author: authorNam,
    relativeTime: '2 giờ trước',
    isArticle: true,
    title: 'Tối ưu hóa âm thanh độ trễ thấp với PipeWire và WirePlumber trên máy trạm Linux (Tiếng Việt: ặ ữ ờ ẫ ệ)',
    paragraphs: [
      'Nhiều bạn khi mới làm quen với PipeWire trên Linux thường gặp khó khăn trong việc cân bằng giữa mức tiêu thụ CPU và độ trễ âm thanh khi cắm tai nghe DAC hoặc micro thu âm.',
      'Bài viết này tổng hợp toàn bộ các bước thiết lập WirePlumber policy, quyền hạn nhóm realtime trong /etc/security/limits.d, và cách kiểm tra thông số buffer trực tiếp từ terminal.',
      'Dưới đây là sơ đồ kiến trúc định tuyến và file cấu hình mẫu:',
    ],
    tags: ['pipewire', 'audio', 'realtime', 'linux-pro'],
    attachment: ImagePlaceholderAttachment(
      aspectRatio: 16 / 9,
      label: 'Sơ đồ kết nối PipeWire node graph',
      semanticLabel: 'Hình minh họa sơ đồ kết nối PipeWire node graph',
    ),
    voteScore: 36,
    viewerVote: VoteState.upvoted,
    commentCount: 5,
    isBookmarked: true,
  );

  static const List<CommentNodeData> threadComments = [
    CommentNodeData(
      id: 'c-1',
      author: authorMai,
      relativeTime: '1 giờ',
      body: 'Cấu hình này rất chi tiết! Mình bổ sung thêm là nên kiểm tra quyền nhóm audio và thêm người dùng vào nhóm realtime để tránh tình trạng kernel priority scheduling bị từ chối.',
      inlineCode: 'pw-top # Theo dõi trực tiếp buffer và latency từng node',
      voteScore: 11,
      viewerVote: VoteState.upvoted,
      replies: [
        CommentNodeData(
          id: 'c-1-1',
          author: authorNam,
          relativeTime: '40 phút',
          body: 'Chính xác bạn! Thêm rule trong /etc/security/limits.d/99-realtime.conf với rtprio 95 và memlock unlimited là chạy mượt mà ngay.',
          voteScore: 5,
          viewerVote: VoteState.neutral,
          replies: [
            CommentNodeData(
              id: 'c-1-1-1',
              author: authorBao,
              relativeTime: '20 phút',
              body: 'Đã áp dụng thành công trên máy của mình, độ trễ tai nghe giảm hẳn!',
              voteScore: 4,
              viewerVote: VoteState.upvoted,
            ),
          ],
        ),
      ],
    ),
    CommentNodeData(
      id: 'c-2',
      author: authorHa,
      relativeTime: '30 phút',
      body: 'Bài viết rất hữu ích cho cộng đồng anh em làm nhạc và dựng video trên Linux. Cảm ơn bạn đã đóng góp!',
      voteScore: 8,
      viewerVote: VoteState.neutral,
    ),
  ];

  static const ProjectShowcaseData projectFlutterWayland = ProjectShowcaseData(
    id: 'proj-flutter-wayland-shell',
    name: 'vnlf-wayland-toolkit',
    description: 'Thư viện tiện ích tối ưu hóa trải nghiệm native cho ứng dụng Flutter trên Wayland và Linux desktop.',
    primaryLanguage: 'Dart / C++',
    tag: 'Wayland',
    stars: 218,
    forks: 32,
  );

  static const List<ProjectShowcaseData> featuredProjects = [
    projectFlutterWayland,
    ProjectShowcaseData(
      id: 'proj-pipewire-gui',
      name: 'wireplumber-patchbay',
      description: 'Giao diện đồ họa nhẹ nhàng quản lý kết nối và mức âm lượng thời gian thực cho PipeWire.',
      primaryLanguage: 'Rust / GTK4',
      tag: 'Audio',
      stars: 164,
      forks: 19,
    ),
  ];

  static const List<ChatMessageData> sampleChatMessages = [
    ChatMessageData(
      id: 'msg-01',
      author: authorNam,
      timestamp: '14:20',
      text: 'Chào mọi người, dự án toolkit đã có bản cập nhật mới hỗ trợ Wayland.',
    ),
    ChatMessageData(
      id: 'msg-02',
      author: authorMai,
      timestamp: '14:22',
      text:
          'Tuyệt vời quá! Mình vừa kiểm tra trên NixOS, hoạt động rất ổn định.',
    ),
  ];
}
