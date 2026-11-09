import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/direct_message_models.dart';

class DmConversationHeader extends StatelessWidget {
  const DmConversationHeader({
    super.key,
    required this.conversation,
    required this.wide,
    required this.loading,
    required this.busy,
    required this.onBack,
    required this.onSearch,
    required this.onMedia,
    required this.onRefresh,
    required this.onAction,
  });
  final DmConversation conversation;
  final bool wide, loading, busy;
  final VoidCallback onBack, onSearch, onMedia, onRefresh;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final peer = conversation.peer;
    final scale = MediaQuery.textScalerOf(context);
    final height = math.max(54.0, scale.scale(13) * 1.15 * 2 + 6);
    return SizedBox(
      key: const Key('dm-conversation-header'),
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                if (!wide)
                  IconButton(
                    key: const Key('dm-open-inbox-sheet-button'),
                    tooltip: vi.app.directMessages.danhSachCuocTro,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 20),
                  ),
                VnlfAvatar(
                  author: presentAuthor(peer.toAuthor()),
                  size: 32,
                  semanticLabel: peer.displayName,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      Text(
                        '${peer.username.isEmpty ? '' : '@${peer.username} · '}'
                        '${peer.isOnline ? vi.app.directMessages.trucTuyen : vi.app.directMessages.ngoaiTuyen}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VnlfTypography.meta(colors.muted)
                            .copyWith(height: 1.15),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('dm-search-button'),
                  tooltip: vi.conversationSearch.timTrongHoiThoai,
                  onPressed: onSearch,
                  icon: const Icon(Icons.search, size: 20),
                ),
                if (!compact) ...[
                  IconButton(
                    key: const Key('dm-media-button'),
                    tooltip: vi.app.directMessages.anhDaChiaSe2,
                    onPressed: onMedia,
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                  ),
                  IconButton(
                    key: const Key('dm-refresh-timeline-button'),
                    tooltip: vi.app.common.lamMoiTinNhan,
                    onPressed: loading ? null : onRefresh,
                    icon: const Icon(Icons.refresh, size: 20),
                  ),
                ],
                PopupMenuButton<String>(
                  key: const Key('dm-conversation-menu'),
                  tooltip: vi.directMessageLiveView.tuyChonHoiThoai,
                  enabled: !busy,
                  onSelected: (action) {
                    if (action == 'media') {
                      onMedia();
                    } else if (action == 'refresh') {
                      onRefresh();
                    } else {
                      onAction(action);
                    }
                  },
                  itemBuilder: (context) => [
                    if (compact) ...[
                      PopupMenuItem(
                        value: 'media',
                        child: Text(vi.app.directMessages.anhDaChiaSe2),
                      ),
                      PopupMenuItem(
                        value: 'refresh',
                        enabled: !loading,
                        child: Text(vi.app.common.lamMoiTinNhan),
                      ),
                    ],
                    PopupMenuItem(
                      value: 'mark_read',
                      child: Text(vi.app.directMessages.danhDauDaDoc),
                    ),
                    PopupMenuItem(
                      value: conversation.isBlockedByMe ? 'unblock' : 'block',
                      child: Text(
                        conversation.isBlockedByMe
                            ? vi.app.directMessages.boChanNguoiDung
                            : vi.app.directMessages.chanNguoiDung2,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Text(vi.app.directMessages.baoCaoCuocTro),
                    ),
                    PopupMenuItem(
                      value: 'delete_conversation',
                      child: Text(vi.app.directMessages.xoaCuocTroChuyen2),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
