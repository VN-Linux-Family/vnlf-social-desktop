import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/community_samples.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import 'voice_participant.dart';

class FixtureVoiceScreen extends ConsumerStatefulWidget {
  const FixtureVoiceScreen({super.key});

  @override
  ConsumerState<FixtureVoiceScreen> createState() => _FixtureVoiceScreenState();
}

class _FixtureVoiceScreenState extends ConsumerState<FixtureVoiceScreen> {
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
    final colors = VnlfColors.of(context);
    final inRoom = _joined == _selected;
    final room = sampleVoiceRooms[_selected];
    final members = communityMembers.take(_selected == 2 ? 2 : 3).toList();
    final session =
        ref.watch(sessionStateProvider) ??
        ref.watch(sessionProvider).valueOrNull;

    final myAuthor = session != null
        ? AuthorData(
            id: session.userId,
            username: session.username,
            displayName: session.displayName.isNotEmpty
                ? session.displayName
                : vi.app.common.ban,
            avatarUrl: session.avatarUrl,
            role: session.role,
          )
        : communityGuest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (session == null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.brandSoft,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              border: Border.all(color: colors.brand.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.record_voice_over_rounded,
                  size: 20,
                  color: colors.brand,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vi.app.voice.dangNhapDeThamGia,
                    style: VnlfTypography.meta(colors.brand),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => context.push('/login'),
                  child: Text(
                    vi.common.dangNhap,
                    style: TextStyle(
                      color: colors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              FeatureSurface(
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < sampleVoiceRooms.length;
                      index++
                    ) ...[
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        leading: Icon(
                          Icons.headphones_rounded,
                          color: _selected == index
                              ? colors.brand
                              : colors.muted,
                          size: 20,
                        ),
                        title: Text(
                          sampleVoiceRooms[index].$1,
                          style: VnlfTypography.control(
                            _selected == index ? colors.brand : colors.ink,
                            fontWeight: _selected == index
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          sampleVoiceRooms[index].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VnlfTypography.caption(colors.muted),
                        ),
                        trailing: _joined == index
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: colors.brand,
                                size: 20,
                              )
                            : null,
                        selected: _selected == index,
                        onTap: () => setState(() => _selected = index),
                      ),
                      if (index < sampleVoiceRooms.length - 1)
                        Divider(color: colors.line, height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.$1, style: VnlfTypography.h3(colors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    format(vi.app.voice.nguoiThamGia, {
                      'inRoom': members.length + (inRoom ? 1 : 0),
                    }),
                    style: VnlfTypography.meta(colors.muted),
                  ),
                ],
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
                            author: myAuthor,
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
        const SizedBox(height: 10),
        // Bottom Audio Controls Dock
        FeatureSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inRoom) ...[
                Text(
                  _sharing
                      ? vi.app.voice.dangChiaSeMan
                      : _deafened
                      ? vi.app.voice.daTatAmThanh
                      : _muted
                      ? vi.app.voice.micDangTat
                      : vi.app.voice.micDangBatNoi,
                  textAlign: TextAlign.center,
                  style: VnlfTypography.meta(
                    _muted ? colors.muted : colors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: inRoom ? colors.red : colors.brand,
                      foregroundColor: inRoom
                          ? Theme.of(context).colorScheme.onError
                          : Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onPressed: (session != null || offlineFeatures)
                        ? _toggleJoin
                        : () => context.push('/login'),
                    icon: Icon(
                      inRoom
                          ? Icons.call_end
                          : (session != null || offlineFeatures
                                ? Icons.headphones
                                : Icons.lock_outline),
                    ),
                    label: Text(
                      (session != null || offlineFeatures)
                          ? (inRoom
                                ? vi.app.voice.roiPhong
                                : vi.app.voice.thamGiaPhong)
                          : vi.app.voice.dangNhapDeTham,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: _muted ? vi.voiceView.batMic : vi.voiceView.tatMic,
                    isSelected: !_muted,
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                    onPressed: inRoom && !_deafened
                        ? () => setState(() => _muted = !_muted)
                        : null,
                  ),
                  IconButton.filledTonal(
                    tooltip: _deafened
                        ? vi.voiceView.batAmThanh
                        : vi.app.common.tatAmThanh,
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
                        ? vi.app.voice.dungChiaSe
                        : vi.app.voice.chiaSeManHinh,
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
