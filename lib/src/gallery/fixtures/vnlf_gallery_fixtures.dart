import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Synthetic Vietnamese fixtures for the Gallery and 3 key screens (`feed`, `thread`, `profile`).
///
/// Strictly follows `PLAN.md` Gate 0 rules: preserves exact production schemas and
/// visual density while using only invented Vietnamese content and synthetic names.
abstract final class VnlfGalleryFixtures {
  static const AuthorData authorAn = AuthorData(
    id: '00000000-0000-7000-8000-000000000002',
    username: 'nguyenvanan',
    displayName: 'Nguyễn Văn An',
    role: 'MEMBER',
    avatarPreset: AvatarVisualPreset.workspaceCoder,
    style: AuthorStyleData(
      nameGradientLight: [Color(0xFF0F766E), Color(0xFF0369A1)],
      nameGradientDark: [Color(0xFF5EEAD4), Color(0xFF7DD3FC)],
      frame: AvatarFrameType.neon,
      distroBadge: DistroBadgeType.cachyos,
      hasTerminalBadge: true,
    ),
  );

  static const AuthorData authorMinhQuan = AuthorData(
    id: '00000000-0000-7000-8000-000000000003',
    username: 'minhquan_py',
    displayName: ':)',
    role: 'MEMBER',
    avatarPreset: AvatarVisualPreset.retroChef,
    style: AuthorStyleData(frame: AvatarFrameType.stars),
  );

  static const AuthorData authorHoangDung = AuthorData(
    id: '00000000-0000-7000-8000-000000000004',
    username: 'hoangdung_vn',
    displayName: 'Lê Hoàng Dũng',
    role: 'CONTRIBUTOR',
    avatarPreset: AvatarVisualPreset.matrixHacker,
    style: AuthorStyleData(
      nameGradientLight: [Color(0xFF0F5338), Color(0xFF14532D)],
      nameGradientDark: [Color(0xFF6EE7B7), Color(0xFF34D399)],
      frame: AvatarFrameType.matrix,
      nameEffect: NameEffectType.cursor,
      hasPixelBadge: true,
      hasPartnerStar: true,
      distroBadge: DistroBadgeType.arch,
    ),
  );

  static const AuthorData authorLinhChi = AuthorData(
    id: '00000000-0000-7000-8000-000000000005',
    username: 'linhchi_linux',
    displayName: 'linhchi_linux',
    role: 'MEMBER',
    avatarPreset: AvatarVisualPreset.pastelSakura,
    style: AuthorStyleData(
      nameGradientLight: [Color(0xFFC026D3), Color(0xFFE11D48)],
      nameGradientDark: [Color(0xFFF0ABFC), Color(0xFFFDA4AF)],
      frame: AvatarFrameType.stars,
      distroBadge: DistroBadgeType.cachyos,
    ),
  );

  static const AuthorData authorTuxArch = AuthorData(
    id: '00000000-0000-7000-8000-000000000006',
    username: 'TuxArchVN',
    displayName: 'TuxArchVN',
    role: 'MODERATOR',
    avatarPreset: AvatarVisualPreset.tuxMascot,
    style: AuthorStyleData(
      nameGradientLight: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
      nameGradientDark: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
      distroBadge: DistroBadgeType.caramos,
      hasTerminalBadge: true,
    ),
  );

  static const List<LeaderboardEntryData> weeklyLeaderboard = [
    LeaderboardEntryData(rank: 1, author: authorHoangDung, points: 75),
    LeaderboardEntryData(rank: 2, author: authorLinhChi, points: 70),
    LeaderboardEntryData(rank: 3, author: authorTuxArch, points: 62),
  ];

  static const List<PostData> feedPosts = [
    PostData(
      id: 'post-debian-xfce-01',
      author: authorAn,
      relativeTime: '1 giờ',
      paragraphs: [
        'Lúc mới biết Linux chưa có nhiều kinh nghiệm, mình cài thử bản rolling release cho máy trạm ở cửa hàng nhỏ (máy ít khi được mở mà gói cập nhật lại liên tục, đôi lúc ngại xung đột cấu hình).',
        'Giờ có nhiều kinh nghiệm hơn chút, cài lại Debian 13 + XFCE ổn định mượt mà cho máy trạm :))...',
      ],
      attachment: LinuxDesktopAttachment(
        distroHeader: 'debian 13',
        terminalTitle: 'terminal - annguyen@debian: ~',
        userHost: 'annguyen@debian',
        osLine: 'Debian GNU/Linux 13 (trixie) x86_64',
        kernelLine: 'Linux 6.12.10+deb13-amd64',
        uptimeLine: '35 mins',
        packagesLine: '1813 (dpkg), 6 (flatpak)',
        shellLine: 'bash 5.2.37',
        deLine: 'Xfce 4.20',
        wmLine: 'Xfwm4 (X11) / Default',
        cpuLine: 'Intel(R) Core(TM) i5-8250U (8) @ 3.40 GHz',
        memoryLine: '1.73 GiB / 7.76 GiB (22%) - btrfs',
      ),
      voteScore: 4,
      viewerVote: VoteState.neutral,
      commentCount: 0,
    ),
    PostData(
      id: 'post-python-prompt-02',
      author: authorMinhQuan,
      relativeTime: '3 giờ',
      paragraphs: [
        'Fact của ngày: Bạn có thể chỉnh prompt của Python',
        'Và prompt ở đây là (xét ví dụ):',
      ],
      attachment: CodeBlockAttachment(
        code:
            'Python 3.14.3 (tags/v3.14.3:323c59a, Feb  3 2026, 16:04:56) [GCC 14.2.0] on linux\n'
            'Type "help", "copyright", "credits" or "license" for more information.\n'
            '>>>\n'
            '^^^ đây là prompt (PS1)\n'
            '>>> for i in range(10):\n'
            '...     print(i)\n'
            '^^^ đây cũng là prompt (PS2)',
      ),
      voteScore: 18,
      viewerVote: VoteState.upvoted,
      commentCount: 5,
    ),
    PostData(
      id: 'post-caramos-wayland-03',
      author: authorHoangDung,
      relativeTime: '6 giờ',
      isArticle: true,
      title: 'Cấu hình hiển thị Tiếng Việt: ặ ữ ờ ẫ ệ trên Wayland & CaramOS',
      paragraphs: [
        'Khi sử dụng bộ gõ Fcitx5 kết hợp phông chữ Be Vietnam Pro trên môi trường Wayland, việc bật subpixel hinting và thiết lập fontconfig chuẩn giúp dấu thanh Tiếng Việt: ặ ữ ờ ẫ ệ hiển thị sắc nét không bị cắt dấu.',
      ],
      tags: ['caramos', 'wayland', 'fcitx5', 'tiengviet'],
      attachment: ProjectPreviewAttachment(project: projectCaramControl),
      voteScore: 42,
      viewerVote: VoteState.upvoted,
      commentCount: 12,
      isBookmarked: true,
    ),
  ];

  static const PostData threadDetailPost = PostData(
    id: 'thread-detail-01',
    author: authorAn,
    relativeTime: '1 giờ trước',
    isArticle: true,
    title: 'Kinh nghiệm chuyển từ Rolling Release sang Debian 13 + XFCE cho máy trạm sản xuất (Tiếng Việt: ặ ữ ờ ẫ ệ)',
    paragraphs: [
      'Lúc mới biết Linux chưa có nhiều kinh nghiệm, mình cài thử bản rolling release cho máy trạm ở cửa hàng nhỏ (máy ít khi được mở mà gói cập nhật lại liên tục, đôi lúc ngại xung đột cấu hình).',
      'Giờ có nhiều kinh nghiệm hơn chút, cài lại Debian 13 (Trixie) + XFCE 4.20 kèm bộ gõ Fcitx5 hiển thị đầy đủ Tiếng Việt: ặ ữ ờ ẫ ệ. Hệ thống chỉ tiêu thụ khoảng 1.7 GiB RAM trên phân vùng Btrfs với snapshot tự động.',
      'Dưới đây là màn hình fastfetch thực tế và cấu hình tự động dọn gói apt hàng tuần:',
    ],
    tags: ['debian13', 'xfce', 'btrfs', 'fcitx5', 'kinhnghiem'],
    attachment: LinuxDesktopAttachment(
      distroHeader: 'debian 13',
      terminalTitle: 'terminal - annguyen@debian: ~',
      userHost: 'annguyen@debian',
      osLine: 'Debian GNU/Linux 13 (trixie) x86_64',
      kernelLine: 'Linux 6.12.10+deb13-amd64',
      uptimeLine: '35 mins',
      packagesLine: '1813 (dpkg), 6 (flatpak)',
      shellLine: 'bash 5.2.37',
      deLine: 'Xfce 4.20',
      wmLine: 'Xfwm4 (X11) / Default',
      cpuLine: 'Intel(R) Core(TM) i5-8250U (8) @ 3.40 GHz',
      memoryLine: '1.73 GiB / 7.76 GiB (22%) - btrfs',
    ),
    voteScore: 48,
    viewerVote: VoteState.upvoted,
    commentCount: 6,
    isBookmarked: true,
  );

  static const List<CommentNodeData> threadComments = [
    CommentNodeData(
      id: 'c-1',
      author: authorHoangDung,
      relativeTime: '45 phút',
      body: 'Chuẩn bài rồi bạn! Máy văn phòng hoặc máy ít bật thì Debian Trixie + XFCE là chân ái. Kết hợp thêm snapper cho phân vùng btrfs nữa là yên tâm tuyệt đối.',
      inlineCode: 'sudo apt install snapper btrfs-assistant && sudo snapper -c root create-config /',
      voteScore: 14,
      viewerVote: VoteState.upvoted,
      replies: [
        CommentNodeData(
          id: 'c-1-1',
          author: authorAn,
          relativeTime: '32 phút',
          body: 'Cảm ơn anh! Em vừa cấu hình thêm hook apt để tự tạo snapshot trước mỗi lần upgrade luôn ạ.',
          voteScore: 6,
          viewerVote: VoteState.neutral,
          replies: [
            CommentNodeData(
              id: 'c-1-1-1',
              author: authorTuxArch,
              relativeTime: '18 phút',
              body: 'Nhớ giới hạn NUMBER_LIMIT="10" trong /etc/snapper/configs/root để tránh đầy ổ cứng nhé!',
              voteScore: 9,
              viewerVote: VoteState.upvoted,
            ),
          ],
        ),
      ],
    ),
    CommentNodeData(
      id: 'c-2',
      author: authorLinhChi,
      relativeTime: '25 phút',
      body: 'Giao diện XFCE 4.20 nhìn gọn quá, font Be Vietnam Pro hiển thị Tiếng Việt: ặ ữ ờ ẫ ệ trên thanh panel rất rõ ràng.',
      voteScore: 5,
      viewerVote: VoteState.neutral,
    ),
  ];

  static const ProjectShowcaseData projectCaramControl = ProjectShowcaseData(
    id: 'proj-caram-welcome',
    name: 'caramos-control-center',
    summary: 'Trung tâm cấu hình nhanh trình điều khiển, bộ gõ Tiếng Việt: ặ ữ ờ ẫ ệ và kho ứng dụng cho CaramOS.',
    category: 'CaramOS',
    language: 'Rust / GTK4',
    stars: 342,
    forks: 41,
    rating: 4.9,
    tags: ['gtk4', 'rust', 'linux-vn'],
  );

  static const List<ProjectShowcaseData> featuredProjects = [
    projectCaramControl,
    ProjectShowcaseData(
      id: 'proj-vnlf-cli',
      name: 'vnlf-dotenv-sync',
      summary: 'Công cụ đồng bộ cấu hình dotfiles (Hyprland, Waybar, Neovim, Kitty) tự động sao lưu qua Git.',
      category: 'Tiện ích',
      language: 'Shell / Go',
      stars: 189,
      forks: 23,
      rating: 4.8,
      tags: ['dotfiles', 'hyprland', 'cli'],
    ),
  ];

  static const List<ChatMessageData> sampleChatMessages = [
    ChatMessageData(
      id: 'msg-1',
      author: authorTuxArch,
      timestamp: '10:24',
      text: 'Chào buổi sáng anh em! Bản ISO thử nghiệm CaramOS 2026.11 đã cập nhật nhân Linux 6.12 LTS và sửa lỗi gõ Tiếng Việt: ặ ữ ờ ẫ ệ trên Wayland.',
      stickerLabel: 'Sticker: Tux Thả Tim 🐧💚',
      reactions: {'🐧': 8, '🔥': 5, '❤️': 4},
    ),
    ChatMessageData(
      id: 'msg-2',
      author: authorLinhChi,
      timestamp: '10:26',
      text: 'Mình vừa tải về chạy thử trên máy ảo QEMU, tốc độ khởi động vào phiên làm việc nhanh hơn hẳn!',
      reactions: {'🎉': 3, '👍': 4},
    ),
  ];
}
