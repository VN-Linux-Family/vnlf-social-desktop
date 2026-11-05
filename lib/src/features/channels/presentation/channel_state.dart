import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/community_samples.dart';

class LocalChannel {
  const LocalChannel(this.id, this.topic, this.englishTopic, this.members);

  final String id;
  final String topic;
  final String englishTopic;
  final int members;
}

const localChannels = [
  LocalChannel(
    'chung',
    'Cùng chia sẻ chuyện Linux mỗi ngày.',
    'Everyday Linux conversations.',
    128,
  ),
  LocalChannel(
    'hoi-dap-linux',
    'Hỏi đáp cài đặt, cấu hình và sử dụng Linux.',
    'Help with installing and using Linux.',
    84,
  ),
  LocalChannel(
    'khoe-giao-dien',
    'Góc bàn làm việc, dotfiles và giao diện của bạn.',
    'Share your desktop and dotfiles.',
    62,
  ),
  LocalChannel(
    'du-an-phan-mem',
    'Kết nối và xây dựng phần mềm mã nguồn mở.',
    'Build open source software together.',
    45,
  ),
  LocalChannel(
    'off-topic',
    'Trà đá, chuyện vui và những điều ngoài Linux.',
    'Tea breaks and conversations beyond Linux.',
    96,
  ),
];

final selectedChannelProvider = StateProvider<String>((ref) => 'chung');

final channelMessagesProvider =
    NotifierProvider<ChannelMessages, Map<String, List<ChatMessageData>>>(
      ChannelMessages.new,
    );

class ChannelMessages extends Notifier<Map<String, List<ChatMessageData>>> {
  int _nextId = 0;

  @override
  Map<String, List<ChatMessageData>> build() => {
    for (final channel in localChannels)
      channel.id: [
        ChatMessageData(
          id: '${channel.id}-welcome',
          author: communityMembers[0],
          timestamp: '09:30',
          text: switch (channel.id) {
            'hoi-dap-linux' => 'Có bạn nào đang dùng Wayland trên laptop không? Mình muốn hỏi cách cấu hình màn hình ngoài.',
            'khoe-giao-dien' => 'Mình vừa hoàn thiện giao diện Hyprland. Mọi người thường dùng thanh trạng thái nào?',
            'du-an-phan-mem' => 'Mời mọi người cùng trao đổi ý tưởng cho công cụ Linux viết bằng Rust.',
            'off-topic' => 'Hôm nay mọi người đang nghe nhạc gì khi code?',
            _ =>
              'Chào mọi người! Hôm nay bạn đang dùng bản phân phối Linux nào?',
          },
          reactions: const {'👍': 3, '❤️': 2},
        ),
        ChatMessageData(
          id: '${channel.id}-reply',
          author: communityMembers[1],
          timestamp: '09:32',
          text: channel.id == 'chung'
              ? 'Mình đang dùng CachyOS. Rất vui được gặp cộng đồng!'
              : 'Cùng trao đổi ở đây nhé, nhớ chia sẻ cấu hình và những gì bạn đã thử.',
        ),
      ],
  };

  void send(String channelId, String text, [AuthorData? author]) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !state.containsKey(channelId)) return;
    final now = DateTime.now();
    state = {
      ...state,
      channelId: List.unmodifiable([
        ...state[channelId]!,
        ChatMessageData(
          id: 'local-${_nextId++}',
          author: author ?? communityGuest,
          timestamp:
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          text: trimmed,
        ),
      ]),
    };
  }
}
