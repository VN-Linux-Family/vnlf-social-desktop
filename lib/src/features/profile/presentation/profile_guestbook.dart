import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../moderation/presentation/report_dialog.dart';
import '../../direct_messages/presentation/direct_message_state.dart';
import '../../feed/presentation/feed_notifier.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../data/live_guestbook_actions.dart';
import '../domain/public_profile.dart';
import 'profile_data.dart';

final guestbookActionsEnabledProvider = Provider<bool>((ref) => !offlineFeatures);

class ProfileGuestbook extends ConsumerStatefulWidget {
  const ProfileGuestbook({super.key, required this.username, required this.ownerId});
  final String username;
  final String ownerId;
  @override
  ConsumerState<ProfileGuestbook> createState() => _ProfileGuestbookState();
}

class _ProfileGuestbookState extends ConsumerState<ProfileGuestbook> {
  final _draft = TextEditingController();
  final _more = <GuestbookEntry>[];
  String? _cursor;
  String? _error;
  bool _paged = false;
  bool _busy = false;
  int _generation = 0;

  @override
  void dispose() {
    _generation++;
    _draft.dispose();
    super.dispose();
  }

  bool _current(int generation, String? viewer) => mounted && generation == _generation && ref.read(sessionStateProvider)?.userId == viewer;

  void _refreshAfterBlock() {
    ref.read(apiClientProvider).clearCache();
    ref.invalidate(feedProvider);
    ref.invalidate(feedNotifierProvider);
    ref.invalidate(profileProvider(widget.username));
    if (ref.exists(dmInboxProvider)) {
      unawaited(ref.read(dmInboxProvider.notifier).load(refresh: true));
    }
  }

  Future<void> _refresh(int generation, String? viewer) async {
    ref.read(apiClientProvider).clearCache();
    await ref.refresh(profileGuestbookProvider(widget.username).future);
    if (_current(generation, viewer)) setState(() { _more.clear(); _paged = false; _cursor = null; });
  }

  Future<void> _loadMore(String cursor) async {
    if (_busy) return;
    final viewer = ref.read(sessionStateProvider)?.userId;
    final generation = ++_generation;
    setState(() { _busy = true; _error = null; });
    try {
      final page = await ref.read(publicProfileRepositoryProvider).getGuestbook(widget.username, cursor: cursor);
      if (!_current(generation, viewer)) return;
      setState(() { _more.addAll(page.items); _cursor = page.nextCursor; _paged = true; });
    } catch (_) {
      if (_current(generation, viewer)) setState(() => _error = Localizations.localeOf(context).languageCode == 'en' ? 'Could not load more messages.' : 'Không tải được lời nhắn tiếp theo.');
    } finally {
      if (_current(generation, viewer)) setState(() => _busy = false);
    }
  }

  Future<void> _act(String action, {GuestbookEntry? entry}) async {
    final viewer = ref.read(sessionStateProvider)?.userId;
    if (_busy || viewer == null || !ref.read(guestbookActionsEnabledProvider)) return;
    final text = _draft.text.trim();
    if (action == 'write' && (text.isEmpty || text.length > 200 || viewer == widget.ownerId)) return;
    final english = Localizations.localeOf(context).languageCode == 'en';
    final scope = ref.read(apiClientProvider).captureSession();
    if (action == 'delete') {
      final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text(english ? 'Delete this message?' : 'Xóa lời nhắn?'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(english ? 'Cancel' : 'Hủy')), TextButton(onPressed: () => Navigator.pop(context, true), child: Text(english ? 'Delete' : 'Xóa'))],
      ));
      if (confirm != true || !mounted || ref.read(sessionStateProvider)?.userId != viewer || _busy) return;
    }
    try { scope.ensureCurrent(); } catch (_) { return; }
    final generation = ++_generation;
    setState(() { _busy = true; _error = null; });
    final actions = LiveGuestbookActions(ref.read(apiClientProvider));
    var acknowledged = false;
    try {
      switch (action) {
        case 'write':
          await actions.write(widget.username, text);
        case 'hide':
          await actions.status(entry!.id, GuestbookStatus.hidden);
        case 'show':
          await actions.status(entry!.id, GuestbookStatus.visible);
        case 'delete':
          await actions.delete(entry!.id);
        case 'block':
          await actions.block(entry!.author.id);
      }
      acknowledged = true;
      if (!_current(generation, viewer)) return;
      if (action == 'write' && _draft.text.trim() == text) _draft.clear();
      if (action == 'block') _refreshAfterBlock();
      await _refresh(generation, viewer);
    } catch (_) {
      if (!_current(generation, viewer)) return;
      if (!acknowledged) {
        if (action == 'block') _refreshAfterBlock();
        try { await _refresh(generation, viewer); } catch (_) { /* Keep the original uncertainty visible. */ }
      }
      if (_current(generation, viewer)) setState(() => _error = acknowledged
          ? (english ? 'Action confirmed, but the guestbook could not be refreshed.' : 'Đã xác nhận thao tác, nhưng không tải lại được sổ lưu bút.')
          : (english ? 'Could not confirm this action. Check the guestbook before trying again.' : 'Chưa xác nhận được thao tác. Vui lòng kiểm tra lại trước khi thử lại.'));
    } finally {
      if (_current(generation, viewer)) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionStateProvider.select((session) => session?.userId), (previous, next) {
      if (previous != next) {
        _generation++;
        _draft.clear();
        setState(() { _busy = false; _error = null; _more.clear(); _cursor = null; _paged = false; });
      }
    });
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final viewer = ref.watch(sessionStateProvider)?.userId;
    final owner = viewer != null && viewer == widget.ownerId;
    return ref.watch(profileGuestbookProvider(widget.username)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) Text(_error!, style: TextStyle(color: colors.red)),
        if (_draft.text.isNotEmpty) TextField(controller: _draft, readOnly: true, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: english ? 'Saved draft' : 'Bản nháp đã giữ')),
        FeatureLoadError(onRetry: () => ref.invalidate(profileGuestbookProvider(widget.username))),
      ]),
      data: (page) {
        final entries = {...{for (final e in page.items) e.id: e}, ...{for (final e in _more) e.id: e}}.values;
        final cursor = _paged ? _cursor : page.nextCursor;
        final reason = page.blockedReason;
        return FeatureSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(english ? 'Guestbook' : 'Sổ lưu bút', style: VnlfTypography.h2(colors.ink)),
          const SizedBox(height: 12),
          Text(english ? '${page.total} messages' : '${page.total} lời nhắn'),
          if (reason == null && viewer != null && !owner && page.enabled && ref.watch(guestbookActionsEnabledProvider)) ...[
            TextField(controller: _draft, maxLength: 200, minLines: 2, maxLines: 4, enabled: !_busy, decoration: InputDecoration(labelText: english ? 'Write a message' : 'Viết lời nhắn')),
            Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _busy ? null : () => _act('write'), child: Text(english ? 'Send' : 'Gửi lời nhắn'))),
          ] else if (reason != null) ...[
            Text(switch (reason) {
              'SIGN_IN' => english ? 'Sign in to write.' : 'Đăng nhập để viết lời nhắn.',
              'GUESTBOOK_DISABLED' => english ? 'This guestbook is disabled.' : 'Sổ lưu bút đã tắt.',
              'GUESTBOOK_DAILY_LIMIT' => english ? 'You have already written today (Vietnam time).' : 'Bạn đã viết hôm nay (giờ Việt Nam).',
              'GUESTBOOK_BLOCKED' => english ? 'You cannot write here.' : 'Bạn không thể viết vào sổ này.',
              'GUESTBOOK_OWN' => english ? 'This is your guestbook.' : 'Đây là sổ lưu bút của bạn.',
              _ => english ? 'Writing is unavailable.' : 'Hiện không thể viết lời nhắn.',
            }),
            if (reason == 'SIGN_IN') TextButton(onPressed: () => context.push('/login'), child: Text(english ? 'Sign in' : 'Đăng nhập')),
          ],
          if (reason != null && _draft.text.isNotEmpty) TextField(controller: _draft, readOnly: true, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: english ? 'Saved draft' : 'Bản nháp đã giữ')),
          if (_error != null) Text(_error!, style: TextStyle(color: colors.red)),
          if (entries.isEmpty) Text(english ? 'No messages yet' : 'Chưa có lời nhắn'),
          for (final entry in entries) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(onTap: () => context.push('/profile/${Uri.encodeComponent(entry.author.username)}'), child: VnlfAvatar(author: presentAuthor(entry.author), size: 32)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VnlfAuthorNameRow(author: presentAuthor(entry.author), showHandleInline: false),
              if (entry.createdAt != null) Text(DateFormat.yMd(english ? 'en' : 'vi').format(entry.createdAt!.toLocal()), style: VnlfTypography.meta(colors.muted)),
              if (entry.status == GuestbookStatus.hidden) Text(english ? 'Hidden' : 'Đang ẩn'),
              const SizedBox(height: 6), Text(entry.content, style: VnlfTypography.body(colors.ink)),
            ])),
            if (viewer != null && ref.watch(guestbookActionsEnabledProvider) && (owner || entry.mine || viewer != entry.author.id)) PopupMenuButton<String>(
              enabled: !_busy,
              onSelected: (action) {
                if (action == 'report') {
                  showDialog<void>(context: context, builder: (_) => ReportDialog(targetId: entry.id, targetType: 'GUESTBOOK_ENTRY'));
                } else { _act(action, entry: entry); }
              },
              itemBuilder: (_) => [
                if (owner) PopupMenuItem(value: entry.status == GuestbookStatus.hidden ? 'show' : 'hide', child: Text(entry.status == GuestbookStatus.hidden ? (english ? 'Show' : 'Hiện lại') : (english ? 'Hide' : 'Ẩn'))),
                if (owner || entry.mine) PopupMenuItem(value: 'delete', child: Text(english ? 'Delete' : 'Xóa')),
                if (owner && !entry.mine) PopupMenuItem(value: 'block', child: Text(english ? 'Block this person' : 'Chặn người này')),
                if (!entry.mine && viewer != entry.author.id) PopupMenuItem(value: 'report', child: Text(english ? 'Report message' : 'Báo cáo lời nhắn')),
              ],
            ),
          ])),
          if (cursor != null) Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: _busy ? null : () => _loadMore(cursor), child: Text(english ? 'Load more' : 'Xem thêm'))),
          if (_busy) const LinearProgressIndicator(),
        ]));
      },
    );
  }
}
