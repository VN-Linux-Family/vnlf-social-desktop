import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../domain/direct_message_models.dart';
import 'direct_message_feedback.dart';
import 'direct_message_media.dart';
import 'direct_message_state.dart';

Future<void> showNewDmDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final recipientId = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        dmText(
          dialogContext,
          'Bắt đầu cuộc trò chuyện mới',
          'Start a new conversation',
        ),
      ),
      content: TextField(
        key: const Key('dm-new-recipient-input'),
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: dmText(
            dialogContext,
            'ID người nhận',
            'Recipient user ID',
          ),
          hintText: dmText(
            dialogContext,
            'Nhập ID thành viên để gửi yêu cầu',
            'Enter member ID to open or request a DM',
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(dmText(dialogContext, 'Hủy', 'Cancel')),
        ),
        FilledButton(
          key: const Key('dm-new-submit-button'),
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: Text(dmText(dialogContext, 'Mở trò chuyện', 'Open chat')),
        ),
      ],
    ),
  );
  controller.dispose();
  if (recipientId == null || recipientId.isEmpty) return;
  await ref.read(dmInboxProvider.notifier).openOrRequestConversation(
    recipientId,
  );
}

Future<void> showDmReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String conversationId,
}) async {
  var selectedReason = DmReportReason.spam;
  final detailController = TextEditingController();
  final submitted = await showDialog<(DmReportReason, String)>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setModalState) => AlertDialog(
        title: Text(
          dmText(
            dialogContext,
            'Báo cáo cuộc trò chuyện',
            'Report conversation',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final reason in DmReportReason.values)
                    ChoiceChip(
                      selected: selectedReason == reason,
                      label: Text(_reportReasonLabel(dialogContext, reason)),
                      onSelected: (_) =>
                          setModalState(() => selectedReason = reason),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('dm-report-detail-input'),
                controller: detailController,
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: dmText(
                    dialogContext,
                    'Chi tiết bổ sung (tùy chọn)',
                    'Additional details (optional)',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dmText(dialogContext, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            key: const Key('dm-report-submit-button'),
            onPressed: () => Navigator.pop(
              dialogContext,
              (selectedReason, detailController.text.trim()),
            ),
            child: Text(dmText(dialogContext, 'Gửi báo cáo', 'Submit report')),
          ),
        ],
      ),
    ),
  );
  detailController.dispose();
  if (submitted == null) return;
  await ref
      .read(dmTimelineProvider(conversationId).notifier)
      .reportConversation(reason: submitted.$1, detail: submitted.$2);
}

String _reportReasonLabel(BuildContext context, DmReportReason reason) =>
    switch (reason) {
      DmReportReason.spam => dmText(context, 'Tin nhắn rác (Spam)', 'Spam'),
      DmReportReason.harassment => dmText(
        context,
        'Quấy rối hoặc xúc phạm',
        'Harassment or abuse',
      ),
      DmReportReason.scam => dmText(
        context,
        'Lừa đảo hoặc giả mạo',
        'Scam or impersonation',
      ),
      DmReportReason.other => dmText(context, 'Lý do khác', 'Other'),
    };

Future<void> showDmSearchSheet(
  BuildContext context, {
  required String conversationId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => FractionallySizedBox(
    heightFactor: 0.75,
    child: SafeArea(
      child: _DmSearchSheet(conversationId: conversationId),
    ),
  ),
);

class _DmSearchSheet extends ConsumerStatefulWidget {
  const _DmSearchSheet({required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<_DmSearchSheet> createState() => _DmSearchSheetState();
}

class _DmSearchSheetState extends ConsumerState<_DmSearchSheet> {
  final TextEditingController _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _queryController.text = ref
        .read(dmTimelineProvider(widget.conversationId))
        .searchQuery;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmTimelineProvider(widget.conversationId));
    final controller = ref.read(
      dmTimelineProvider(widget.conversationId).notifier,
    );
    final colors = VnlfColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  dmText(
                    context,
                    'Tìm trong cuộc trò chuyện',
                    'Search in conversation',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('dm-search-query-input'),
                  controller: _queryController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: controller.searchMessages,
                  decoration: InputDecoration(
                    hintText: dmText(
                      context,
                      'Nhập từ khóa (tối thiểu 2 ký tự)...',
                      'Enter keyword (at least 2 characters)...',
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('dm-search-submit-button'),
                onPressed: state.searching
                    ? null
                    : () => controller.searchMessages(_queryController.text),
                child: Text(dmText(context, 'Tìm', 'Search')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.searching)
            const LinearProgressIndicator()
          else if (state.searchFailure != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dmFailureMessage(context, state.searchFailure),
                style: TextStyle(color: colors.red),
              ),
            ),
          Expanded(
            child: state.searchResults.isEmpty
                ? Center(
                    child: Text(
                      state.searchQuery.isEmpty
                          ? dmText(
                              context,
                              'Nhập từ khóa để tìm tin nhắn trong cuộc trò chuyện.',
                              'Enter a query to search messages in this conversation.',
                            )
                          : dmText(
                              context,
                              'Không tìm thấy tin nhắn phù hợp.',
                              'No matching messages found.',
                            ),
                      style: VnlfTypography.body(colors.muted),
                    ),
                  )
                : ListView.separated(
                    itemCount: state.searchResults.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final hit = state.searchResults[index];
                      return ListTile(
                        title: Text(
                          hit.sender.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          hit.excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          formatDmTimestamp(hit.sentAt),
                          style: VnlfTypography.meta(colors.muted),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          controller.jumpToMessageContext(hit.messageId);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> showDmMediaSheet(
  BuildContext context, {
  required String conversationId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => FractionallySizedBox(
    heightFactor: 0.75,
    child: SafeArea(
      child: _DmMediaSheet(conversationId: conversationId),
    ),
  ),
);

class _DmMediaSheet extends ConsumerStatefulWidget {
  const _DmMediaSheet({required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<_DmMediaSheet> createState() => _DmMediaSheetState();
}

class _DmMediaSheetState extends ConsumerState<_DmMediaSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(dmTimelineProvider(widget.conversationId));
      if (!state.mediaLoaded && !state.loadingMedia) {
        ref.read(dmTimelineProvider(widget.conversationId).notifier).loadMedia();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmTimelineProvider(widget.conversationId));
    final controller = ref.read(
      dmTimelineProvider(widget.conversationId).notifier,
    );
    final colors = VnlfColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  dmText(
                    context,
                    'Ảnh đã chia sẻ trong cuộc trò chuyện',
                    'Shared media in conversation',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: dmText(context, 'Làm mới', 'Refresh'),
                onPressed: state.loadingMedia
                    ? null
                    : () => controller.loadMedia(),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.loadingMedia && !state.mediaLoaded)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.mediaFailure != null && state.mediaItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      dmFailureMessage(context, state.mediaFailure),
                      style: TextStyle(color: colors.red),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => controller.loadMedia(),
                      child: Text(dmText(context, 'Thử lại', 'Retry')),
                    ),
                  ],
                ),
              ),
            )
          else if (state.mediaItems.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  dmText(
                    context,
                    'Chưa có ảnh nào được chia sẻ trong cuộc trò chuyện này.',
                    'No images have been shared in this conversation yet.',
                  ),
                  style: VnlfTypography.body(colors.muted),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount:
                    state.mediaItems.length +
                    (state.mediaNextCursor != null ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == state.mediaItems.length) {
                    return Center(
                      child: TextButton(
                        onPressed: state.loadingMedia
                            ? null
                            : () => controller.loadMedia(loadMore: true),
                        child: Text(
                          dmText(
                            context,
                            'Tải thêm ảnh cũ hơn',
                            'Load older media',
                          ),
                        ),
                      ),
                    );
                  }
                  final item = state.mediaItems[index];
                  return DirectMessageMediaTilePreview(
                    item: item,
                    onJumpToMessage: () {
                      Navigator.pop(context);
                      controller.jumpToMessageContext(item.messageId);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
