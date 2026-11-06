import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../search/presentation/search_providers.dart';
import '../../shared/presentation/author_mapper.dart';
import 'direct_message_feedback.dart';
import 'direct_message_state.dart';

class NewDmRecipientDialog extends ConsumerStatefulWidget {
  const NewDmRecipientDialog({super.key});

  @override
  ConsumerState<NewDmRecipientDialog> createState() =>
      _NewDmRecipientDialogState();
}

class _NewDmRecipientDialogState extends ConsumerState<NewDmRecipientDialog> {
  Timer? _debounce;
  String _query = '';
  String _inputQuery = '';
  bool _opening = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() {
      _inputQuery = query;
      _failure = null;
      if (query.length < 2) _query = '';
    });
    if (query.length < 2 || query == _query) return;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = query);
    });
  }

  Future<void> _open(Author member) async {
    final owner = ref.read(sessionStateProvider)?.userId;
    if (_opening || owner == null || member.id == owner) return;
    setState(() {
      _opening = true;
      _failure = null;
    });
    final id = await ref
        .read(dmInboxProvider.notifier)
        .openOrRequestConversation(member.id);
    if (!mounted || ref.read(sessionStateProvider)?.userId != owner) return;
    if (id != null) {
      final router = GoRouter.maybeOf(context);
      Navigator.pop(context);
      router?.go('/messages/$id');
    } else {
      setState(() {
        _opening = false;
        _failure =
            ref.read(dmInboxProvider).actionFailure ?? const TransportFailure();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final owner = ref.watch(sessionStateProvider)?.userId;
    ref.listen(sessionStateProvider, (before, after) {
      if (before?.userId != after?.userId && mounted) Navigator.pop(context);
    });
    final debouncing = _inputQuery.length >= 2 && _inputQuery != _query;
    final results = _query.isEmpty || debouncing
        ? null
        : ref.watch(searchResultsProvider(_query));
    final members = results?.valueOrNull?.users
        .where(
          (member) =>
              member.id.isNotEmpty &&
              member.id != owner &&
              member.username.isNotEmpty,
        )
        .toList();
    return PopScope(
      canPop: !_opening,
      child: AlertDialog(
        title: Text(
          dmText(context, 'Bắt đầu cuộc trò chuyện', 'Start a conversation'),
        ),
        content: SizedBox(
          width: 480,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('dm-member-search'),
                autofocus: true,
                enabled: !_opening,
                maxLength: 100,
                style: VnlfTypography.body(colors.ink),
                onChanged: _search,
                decoration: InputDecoration(
                  labelText: dmText(context, 'Tìm thành viên', 'Find a member'),
                  hintText: dmText(
                    context,
                    'Tên hoặc tên người dùng',
                    'Name or username',
                  ),
                  prefixIcon: const Icon(Icons.search),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              if (_opening) const LinearProgressIndicator(),
              if (_failure != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    dmFailureMessage(context, _failure),
                    style: TextStyle(color: colors.red),
                  ),
                ),
              Expanded(
                child: debouncing
                    ? const Center(child: CircularProgressIndicator())
                    : _query.isEmpty
                    ? Center(
                        child: Text(
                          dmText(
                            context,
                            'Nhập ít nhất 2 ký tự để tìm thành viên.',
                            'Enter at least 2 characters to find a member.',
                          ),
                        ),
                      )
                    : results!.hasError
                    ? Center(
                        child: TextButton(
                          onPressed: () =>
                              ref.invalidate(searchResultsProvider(_query)),
                          child: Text(
                            dmText(
                              context,
                              'Không tải được thành viên. Thử lại',
                              'Could not load members. Try again',
                            ),
                          ),
                        ),
                      )
                    : results.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : members!.isEmpty
                    ? Center(
                        child: Text(
                          dmText(
                            context,
                            'Không tìm thấy thành viên',
                            'No members found',
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return ListTile(
                            enabled: !_opening,
                            contentPadding: EdgeInsets.zero,
                            leading: VnlfAvatar(
                              author: presentAuthor(member),
                              size: 36,
                            ),
                            title: Text(
                              member.displayName,
                              style: VnlfTypography.body(colors.ink),
                            ),
                            subtitle: Text(
                              '@${member.username}',
                              style: VnlfTypography.meta(colors.muted),
                            ),
                            onTap: () => _open(member),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _opening ? null : () => Navigator.pop(context),
            child: Text(dmText(context, 'Hủy', 'Cancel')),
          ),
        ],
      ),
    );
  }
}
