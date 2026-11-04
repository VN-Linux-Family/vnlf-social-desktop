import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/community_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import 'voice_participant.dart';

const _rooms = [
  (
    'Phòng Voice Chung',
    'General voice room',
    'Cùng gặp gỡ cộng đồng',
    'Meet the community',
  ),
  (
    'Trà đá chém gió Linux',
    'Linux tea break',
    'Chuyện trò sau giờ làm',
    'Conversations after work',
  ),
  (
    'Phòng Code & Học tập',
    'Code & study room',
    'Tập trung, học hỏi và cùng viết code',
    'Focus, learn and code together',
  ),
];

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  int _selected = 0;
  int? _joined;
  bool _muted = true;
  bool _deafened = false;
  bool _mutedBeforeDeafen = true;
  bool _sharing = false;

  void _toggleJoin() => setState(() {
    _joined = _joined == _selected ? null : _selected;
    _muted = true;
    _deafened = false;
    _sharing = false;
  });

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final inRoom = _joined == _selected;
    final room = _rooms[_selected];
    final members = communityMembers.take(_selected == 2 ? 2 : 3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VnlfCenterPageHeader(title: english ? 'Voice rooms' : 'Phòng Voice'),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              Text(
                english
                    ? 'Local voice preview · Microphone, audio and screen are not broadcast.'
                    : 'Trải nghiệm Voice cục bộ · Không thu mic, phát âm thanh hay truyền màn hình.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FeatureSurface(
                child: Column(
                  children: [
                    for (var index = 0; index < _rooms.length; index++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.headphones,
                          color: _selected == index
                              ? colors.brand
                              : colors.muted,
                        ),
                        title: Text(
                          english ? _rooms[index].$2 : _rooms[index].$1,
                        ),
                        subtitle: Text(
                          english ? _rooms[index].$4 : _rooms[index].$3,
                        ),
                        trailing: _joined == index
                            ? Icon(Icons.check_circle, color: colors.brand)
                            : null,
                        selected: _selected == index,
                        onTap: () => setState(() => _selected = index),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                english ? room.$2 : room.$1,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                english
                    ? '${members.length + (inRoom ? 1 : 0)} participants'
                    : '${members.length + (inRoom ? 1 : 0)} người tham gia',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 3 : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var index = 0; index < members.length; index++)
                        SizedBox(
                          width: width,
                          child: VoiceParticipant(
                            author: members[index],
                            speaking: index == 0,
                          ),
                        ),
                      if (inRoom)
                        SizedBox(
                          width: width,
                          child: VoiceParticipant(
                            author: communityGuest,
                            muted: _muted,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FeatureSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inRoom) ...[
                Text(
                  _sharing
                      ? (english
                            ? 'Screen share preview active'
                            : 'Đang xem thử chia sẻ màn hình')
                      : _deafened
                      ? (english
                            ? 'Sound off · Microphone muted'
                            : 'Đã tắt âm thanh và mic')
                      : _muted
                      ? (english ? 'Microphone muted' : 'Mic đang tắt')
                      : (english
                            ? 'Microphone unmuted (preview)'
                            : 'Mic đã bật (trải nghiệm)'),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _toggleJoin,
                    icon: Icon(inRoom ? Icons.call_end : Icons.headphones),
                    label: Text(
                      inRoom
                          ? (english ? 'Leave room' : 'Rời phòng')
                          : (english ? 'Join room' : 'Tham gia phòng'),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: _muted
                        ? (english ? 'Unmute microphone' : 'Bật mic')
                        : (english ? 'Mute microphone' : 'Tắt mic'),
                    isSelected: !_muted,
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                    onPressed: inRoom && !_deafened
                        ? () => setState(() => _muted = !_muted)
                        : null,
                  ),
                  IconButton.filledTonal(
                    tooltip: _deafened
                        ? (english ? 'Enable sound' : 'Bật âm thanh')
                        : (english ? 'Deafen' : 'Tắt âm thanh'),
                    isSelected: _deafened,
                    icon: Icon(
                      _deafened ? Icons.headset_off : Icons.headphones,
                    ),
                    onPressed: inRoom
                        ? () => setState(() {
                            if (!_deafened) {
                              _mutedBeforeDeafen = _muted;
                              _muted = true;
                            } else {
                              _muted = _mutedBeforeDeafen;
                            }
                            _deafened = !_deafened;
                          })
                        : null,
                  ),
                  IconButton.filledTonal(
                    tooltip: _sharing
                        ? (english ? 'Stop sharing' : 'Dừng chia sẻ')
                        : (english ? 'Share screen' : 'Chia sẻ màn hình'),
                    isSelected: _sharing,
                    icon: Icon(
                      _sharing
                          ? Icons.stop_screen_share_outlined
                          : Icons.screen_share_outlined,
                    ),
                    onPressed: inRoom
                        ? () => setState(() => _sharing = !_sharing)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
