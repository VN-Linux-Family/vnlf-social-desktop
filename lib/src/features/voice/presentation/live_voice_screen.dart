import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/voice_models.dart';
import 'live_voice_controls.dart';
import 'voice_participant.dart';
import 'voice_providers.dart';
import 'voice_session_controller.dart';

class LiveVoiceScreen extends ConsumerStatefulWidget {
  const LiveVoiceScreen({super.key});
  @override
  ConsumerState<LiveVoiceScreen> createState() => _LiveVoiceScreenState();
}

class _LiveVoiceScreenState extends ConsumerState<LiveVoiceScreen>
    with WidgetsBindingObserver {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(ref.read(voiceSessionProvider.notifier).leave());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final account = ref.watch(voiceAccountIdProvider);
    final state = ref.watch(voiceSessionProvider);
    final rooms = ref.watch(voiceRoomsProvider);
    final values = rooms.valueOrNull ?? const <VoiceRoom>[];
    final room =
        values.where((room) => room.id == _selectedId).firstOrNull ??
        values.firstOrNull;
    final controller = ref.read(voiceSessionProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VnlfCenterPageHeader(title: english ? 'Voice rooms' : 'Phòng Voice'),
        const SizedBox(height: 12),
        if (account == null)
          FeatureSurface(
            child: Column(
              children: [
                const Icon(Icons.headphones_rounded),
                const SizedBox(height: 8),
                Text(
                  english
                      ? 'Sign in to join Voice'
                      : 'Đăng nhập để tham gia Voice',
                  style: VnlfTypography.h3(colors.ink),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.push('/login'),
                  child: Text(english ? 'Sign in' : 'Đăng nhập'),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: rooms.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      english
                          ? 'Unable to load voice rooms.'
                          : 'Không tải được danh sách phòng Voice.',
                      style: VnlfTypography.body(colors.muted),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(voiceRoomsProvider),
                      child: Text(english ? 'Try again' : 'Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Text(
                        english
                            ? 'No voice rooms available.'
                            : 'Chưa có phòng Voice khả dụng.',
                        style: VnlfTypography.body(colors.muted),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        _RoomDirectory(
                          rooms: items,
                          selectedId: room?.id,
                          state: state,
                          onSelect: (id) => setState(() => _selectedId = id),
                        ),
                        if (room != null) ...[
                          const SizedBox(height: 16),
                          Text(room.name, style: VnlfTypography.h3(colors.ink)),
                          const SizedBox(height: 2),
                          Text(
                            english
                                ? '${_count(room, state)} participants'
                                : '${_count(room, state)} người tham gia',
                            style: VnlfTypography.meta(colors.muted),
                          ),
                          const SizedBox(height: 12),
                          if (state.roomId == room.id && state.connected)
                            _Participants(members: state.participants)
                          else
                            Text(
                              english
                                  ? 'Connect to see room participants.'
                                  : 'Kết nối để xem thành viên trong phòng.',
                              style: VnlfTypography.meta(colors.muted),
                            ),
                        ],
                      ],
                    ),
            ),
          ),
        if (account != null) ...[
          const SizedBox(height: 10),
          LiveVoiceControls(
            state: state,
            room: room,
            onJoin: () => unawaited(controller.join(room!)),
            onLeave: () => unawaited(controller.leave()),
            onMicrophone: () => unawaited(controller.toggleMicrophone()),
            onDeafen: () => unawaited(controller.toggleDeafen()),
          ),
        ],
      ],
    );
  }
}

int _count(VoiceRoom room, VoiceSessionState state) =>
    state.roomId == room.id && state.connected
    ? state.participants.length
    : room.participantCount;

class _RoomDirectory extends StatelessWidget {
  const _RoomDirectory({
    required this.rooms,
    required this.selectedId,
    required this.state,
    required this.onSelect,
  });
  final List<VoiceRoom> rooms;
  final String? selectedId;
  final VoiceSessionState state;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';
    return FeatureSurface(
      child: Column(
        children: [
          for (var index = 0; index < rooms.length; index++) ...[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Icon(
                Icons.headphones_rounded,
                color: selectedId == rooms[index].id
                    ? colors.brand
                    : colors.muted,
                size: 20,
              ),
              title: Text(
                rooms[index].name,
                style: VnlfTypography.control(
                  selectedId == rooms[index].id ? colors.brand : colors.ink,
                ),
              ),
              subtitle: Text(
                rooms[index].description.isNotEmpty
                    ? rooms[index].description
                    : (english
                          ? '${_count(rooms[index], state)} participants'
                          : '${_count(rooms[index], state)} người tham gia'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VnlfTypography.caption(colors.muted),
              ),
              trailing: state.roomId == rooms[index].id && state.connected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: colors.brand,
                      size: 20,
                    )
                  : !rooms[index].canJoin
                  ? const Icon(Icons.lock_outline, size: 18)
                  : null,
              selected: selectedId == rooms[index].id,
              onTap: () => onSelect(rooms[index].id),
            ),
            if (index < rooms.length - 1)
              Divider(color: colors.line, height: 1),
          ],
        ],
      ),
    );
  }
}

class _Participants extends StatelessWidget {
  const _Participants({required this.members});
  final List<VoiceMember> members;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 600 ? 3 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final member in members)
            SizedBox(
              width: width,
              child: VoiceParticipant(
                author: AuthorData(
                  id: member.id,
                  username: member.username,
                  displayName: member.name,
                  avatarUrl: member.avatarUrl,
                  role: member.role,
                ),
                speaking: member.speaking,
                muted: member.muted,
              ),
            ),
        ],
      );
    },
  );
}
