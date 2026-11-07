import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/request_identity.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../domain/feedback_models.dart';
import 'feedback_providers.dart';

/// Own-account ticket history. The app shell can supply its own detail navigation.
class FeedbackHistoryScreen extends ConsumerWidget {
  const FeedbackHistoryScreen({super.key, this.onOpenThread});
  final ValueChanged<String>? onOpenThread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(sessionStateProvider)?.userId;
    final en = Localizations.localeOf(context).languageCode == 'en';
    if (owner == null || owner.isEmpty) {
      return _FeedbackPage(
        title: _text(en, 'Góp ý của tôi', 'My feedback'),
        child: _stateCard(
          context,
          Icons.lock_outline,
          _text(
            en,
            'Đăng nhập để xem lịch sử góp ý của bạn.',
            'Sign in to view your feedback history.',
          ),
        ),
      );
    }
    final history = ref.watch(feedbackHistoryProvider(owner));
    return _FeedbackPage(
      title: _text(en, 'Góp ý của tôi', 'My feedback'),
      child: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(feedbackHistoryProvider(owner)),
        ),
        data: (tickets) => tickets.isEmpty
            ? _stateCard(
                context,
                Icons.inbox_outlined,
                _text(
                  en,
                  'Bạn chưa gửi góp ý nào.',
                  'You have not sent any feedback yet.',
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref
                    .refresh(feedbackHistoryProvider(owner).future)
                    .then((_) {}),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _TicketCard(
                    ticket: tickets[index],
                    en: en,
                    onTap: onOpenThread == null
                        ? null
                        : () => onOpenThread!(tickets[index].id),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Member conversation for one of the current account's tickets.
class FeedbackThreadScreen extends ConsumerStatefulWidget {
  const FeedbackThreadScreen({super.key, required this.ticketId, this.onBack});
  final String ticketId;
  final VoidCallback? onBack;

  @override
  ConsumerState<FeedbackThreadScreen> createState() =>
      _FeedbackThreadScreenState();
}

class _FeedbackThreadScreenState extends ConsumerState<FeedbackThreadScreen> {
  final _input = TextEditingController();
  String? _retryId;
  String? _error;
  bool _sending = false;

  @override
  void didUpdateWidget(covariant FeedbackThreadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticketId != widget.ticketId) {
      _input.clear();
      _retryId = null;
      _error = null;
      _sending = false;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(sessionStateProvider)?.userId;
    final en = Localizations.localeOf(context).languageCode == 'en';
    final title = _text(en, 'Cuộc trò chuyện', 'Ticket conversation');
    ref.listen(sessionStateProvider.select((session) => session?.userId), (
      before,
      after,
    ) {
      if (before != after && mounted) {
        setState(() {
          _input.clear();
          _retryId = null;
          _error = null;
          _sending = false;
        });
      }
    });
    if (owner == null || owner.isEmpty) {
      return _FeedbackPage(
        title: title,
        child: _stateCard(
          context,
          Icons.lock_outline,
          _text(
            en,
            'Đăng nhập để xem cuộc trò chuyện này.',
            'Sign in to view this conversation.',
          ),
        ),
      );
    }
    final key = (owner, widget.ticketId);
    final thread = ref.watch(feedbackThreadProvider(key));
    return _FeedbackPage(
      title: title,
      leading: IconButton(
        tooltip: _text(en, 'Quay lại', 'Back'),
        onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      child: thread.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(feedbackThreadProvider(key)),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(feedbackThreadProvider(key).future).then((_) {}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              _TicketSummary(ticket: data.ticket, en: en),
              const SizedBox(height: 14),
              Text(
                _text(en, 'Thảo luận', 'Conversation'),
                style: VnlfTypography.h2(VnlfColors.of(context).ink),
              ),
              const SizedBox(height: 8),
              if (data.messages.isEmpty)
                _stateCard(
                  context,
                  Icons.forum_outlined,
                  _text(
                    en,
                    'Chưa có tin nhắn. Đội VNLF sẽ trả lời tại đây.',
                    'No messages yet. The VNLF team will reply here.',
                  ),
                )
              else
                for (final message in data.messages)
                  _MessageCard(message: message, en: en),
              const SizedBox(height: 10),
              _composer(context, ref, owner, key, en),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer(
    BuildContext context,
    WidgetRef ref,
    String owner,
    (String, String) key,
    bool en,
  ) {
    final colors = VnlfColors.of(context);
    return Card(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _input,
              minLines: 2,
              maxLines: 6,
              maxLength: 4000,
              enabled: !_sending,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _text(
                  en,
                  'Viết tin nhắn cho Đội VNLF…',
                  'Write a message to the VNLF team…',
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                _retryId = null;
                setState(() => _error = null);
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  key: const Key('feedback-send-error'),
                  style: TextStyle(color: colors.red),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _sending || _input.text.trim().isEmpty
                    ? null
                    : () => _send(ref, owner, key, en),
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(_text(en, 'Gửi tin nhắn', 'Send message')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(
    WidgetRef ref,
    String owner,
    (String, String) key,
    bool en,
  ) async {
    final content = _input.text.trim();
    if (content.isEmpty || content.length > 4000 || _sending) return;
    final clientId = _retryId ??= newRequestIdentity();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final sent = await ref
          .read(feedbackRepositoryProvider)
          .sendMessage(
            ticketId: key.$2,
            clientMessageId: clientId,
            content: content,
          );
      if (!mounted ||
          widget.ticketId != key.$2 ||
          ref.read(sessionStateProvider)?.userId != owner) {
        return;
      }
      // The server response is accepted only after repository validation; fresh history
      // replaces the cached transcript so ordering remains server-defined.
      if (sent.id.isEmpty) {
        throw const ParseFailure('feedback.message.acknowledgement');
      }
      _input.clear();
      _retryId = null;
      ref.invalidate(feedbackThreadProvider(key));
      ref.invalidate(feedbackHistoryProvider(owner));
    } catch (error) {
      if (mounted &&
          widget.ticketId == key.$2 &&
          ref.read(sessionStateProvider)?.userId == owner) {
        setState(() => _error = feedbackFailureMessage(error, en));
      }
    } finally {
      if (mounted &&
          widget.ticketId == key.$2 &&
          ref.read(sessionStateProvider)?.userId == owner) {
        setState(() => _sending = false);
      }
    }
  }
}

class _FeedbackPage extends StatelessWidget {
  const _FeedbackPage({required this.title, required this.child, this.leading});
  final String title;
  final Widget child;
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final mobile = MediaQuery.sizeOf(context).width < 840;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: mobile
          ? null
          : AppBar(
              title: Text(title),
              leading: leading,
              backgroundColor: colors.paper,
              foregroundColor: colors.ink,
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.en, this.onTap});
  final FeedbackTicket ticket;
  final bool en;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Card(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.reference,
                      style: VnlfTypography.h3(colors.ink),
                    ),
                  ),
                  _StatusChip(status: ticket.status, en: en),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.detail,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: VnlfTypography.body(colors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                '${_date(ticket.createdAt, en)} · ${ticket.messageCount} ${_text(en, 'tin nhắn', 'messages')}${ticket.attachmentCount > 0 ? ' · ${ticket.attachmentCount} ${_text(en, 'tệp', 'files')}' : ''}',
                style: VnlfTypography.caption(colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketSummary extends StatelessWidget {
  const _TicketSummary({required this.ticket, required this.en});
  final FeedbackTicket ticket;
  final bool en;
  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Card(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.reference,
                    style: VnlfTypography.h3(colors.ink),
                  ),
                ),
                _StatusChip(status: ticket.status, en: en),
              ],
            ),
            const SizedBox(height: 8),
            Text(ticket.detail, style: VnlfTypography.body(colors.ink)),
            const SizedBox(height: 8),
            Text(
              '${_date(ticket.createdAt, en)} · ${ticket.pagePath}',
              style: VnlfTypography.caption(colors.muted),
            ),
            if (ticket.attachmentCount > 0)
              Text(
                '${ticket.attachmentCount} ${_text(en, 'tệp đính kèm', 'attachments')}',
                style: VnlfTypography.caption(colors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.en});
  final FeedbackMessage message;
  final bool en;
  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final name = message.mine
        ? _text(en, 'Bạn', 'You')
        : message.staff
        ? 'Đội VNLF'
        : (message.authorName ?? 'VNLF');
    return Card(
      color: message.mine ? colors.brandSoft : colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: VnlfTypography.h3(colors.ink)),
                ),
                Text(
                  _date(message.createdAt, en),
                  style: VnlfTypography.caption(colors.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(message.content, style: VnlfTypography.body(colors.ink)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.en});
  final FeedbackStatus status;
  final bool en;
  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final label = switch (status) {
      FeedbackStatus.open => _text(en, 'Đang mở', 'Open'),
      FeedbackStatus.inReview => _text(en, 'Đang xem xét', 'In review'),
      FeedbackStatus.resolved => _text(en, 'Đã giải quyết', 'Resolved'),
      FeedbackStatus.closed => _text(en, 'Đã đóng', 'Closed'),
      FeedbackStatus.deferred => _text(en, 'Để làm sau', 'Deferred'),
    };
    return Semantics(
      label: '${_text(en, 'Trạng thái', 'Status')}: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: colors.brandSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: VnlfTypography.caption(colors.brand)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    return _stateCard(
      context,
      Icons.cloud_off_outlined,
      feedbackFailureMessage(error, en),
      action: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(_text(en, 'Thử lại', 'Try again')),
      ),
    );
  }
}

Widget _stateCard(
  BuildContext context,
  IconData icon,
  String message, {
  Widget? action,
}) {
  final colors = VnlfColors.of(context);
  return Center(
    child: Card(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: colors.muted),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: VnlfTypography.body(colors.ink),
            ),
            ?action,
          ],
        ),
      ),
    ),
  );
}

String feedbackFailureMessage(Object failure, bool en) {
  if (failure is HttpFailure && failure.statusCode == 401) {
    return _text(
      en,
      'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.',
      'Your session expired. Please sign in again.',
    );
  }
  if (failure is HttpFailure && failure.statusCode == 404) {
    return _text(
      en,
      'Không tìm thấy góp ý này.',
      'This feedback ticket was not found.',
    );
  }
  if (failure is ParseFailure) {
    return _text(
      en,
      'Phản hồi từ máy chủ không hợp lệ. Hãy làm mới để thử lại.',
      'The server returned invalid data. Refresh to try again.',
    );
  }
  if (failure is TransportFailure) {
    return _text(
      en,
      'Chưa xác nhận được tin nhắn. Bản nháp được giữ lại để bạn thử lại.',
      'The message was not confirmed. Your draft is kept for a manual retry.',
    );
  }
  return _text(
    en,
    'Không tải được dữ liệu. Hãy thử lại sau.',
    'Could not load this data. Please try again.',
  );
}

String _text(bool en, String vi, String english) => en ? english : vi;
String _date(DateTime value, bool en) =>
    value.toLocal().toString().substring(0, 16).replaceFirst('T', ' ');
