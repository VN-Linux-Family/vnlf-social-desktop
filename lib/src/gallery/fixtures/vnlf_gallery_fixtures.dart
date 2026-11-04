import '../../design_system/design_system.dart';

/// Synthetic Vietnamese fixtures for the Gallery and 3 key screens (`feed`, `thread`, `profile`).
///
/// Strictly compliant with zero-reference-content rules: 100% synthetic discussions,
/// invented identities, and neutral placeholders. Zero production names or screenshot text.
abstract final class VnlfGalleryFixtures {
  static const AuthorData authorNam = AuthorData(
    id: '00000000-0000-7000-8000-000000000011',
    username: 'tranvannam',
    displayName: 'Trần Văn Nam',
    role: 'MEMBER',
    style: AuthorStyleData(
      frame: AvatarFrameType.ring,
      distroBadge: DistroBadgeType.fedora,
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
