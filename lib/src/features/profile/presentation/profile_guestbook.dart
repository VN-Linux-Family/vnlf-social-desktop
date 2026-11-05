import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/public_profile.dart';
import 'profile_data.dart';

class ProfileGuestbook extends ConsumerStatefulWidget {
  const ProfileGuestbook({super.key, required this.username});
  final String username;
  @override
  ConsumerState<ProfileGuestbook> createState() => _ProfileGuestbookState();
}

class _ProfileGuestbookState extends ConsumerState<ProfileGuestbook> {
  final _moreEntries = <GuestbookEntry>[];
  String? _nextCursor;
  bool _loading = false;
  bool _failed = false;
  bool _paged = false;

  Future<void> _loadMore(String cursor) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await ref
          .read(publicProfileRepositoryProvider)
          .getGuestbook(widget.username, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _moreEntries.addAll(page.items);
        _nextCursor = page.nextCursor;
        _paged = true;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    return ref
        .watch(profileGuestbookProvider(widget.username))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => FeatureLoadError(
            onRetry: () =>
                ref.invalidate(profileGuestbookProvider(widget.username)),
          ),
          data: (page) {
            final entries = {
              ...{for (final entry in page.items) entry.id: entry},
              ...{for (final entry in _moreEntries) entry.id: entry},
            }.values;
            final cursor = _paged ? _nextCursor : page.nextCursor;
            return FeatureSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    english ? 'Guestbook' : 'Sổ lưu bút',
                    style: VnlfTypography.h2(colors.ink),
                  ),
                  const SizedBox(height: 12),
                  if (!page.enabled)
                    Text(
                      english
                          ? 'This guestbook is disabled.'
                          : 'Sổ lưu bút đã tắt.',
                    )
                  else if (entries.isEmpty)
                    Text(english ? 'No messages yet' : 'Chưa có lời nhắn'),
                  for (final entry in entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => context.push(
                              '/profile/${Uri.encodeComponent(entry.author.username)}',
                            ),
                            child: VnlfAvatar(
                              author: presentAuthor(entry.author),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VnlfAuthorNameRow(
                                  author: presentAuthor(entry.author),
                                  showHandleInline: false,
                                ),
                                if (entry.createdAt != null)
                                  Text(
                                    DateFormat.yMd(english ? 'en' : 'vi')
                                        .format(entry.createdAt!.toLocal()),
                                    style: VnlfTypography.meta(colors.muted),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  entry.content,
                                  style: VnlfTypography.body(colors.ink),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (cursor != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _loading ? null : () => _loadMore(cursor),
                        child: Text(
                          _failed
                              ? (english ? 'Retry' : 'Thử lại')
                              : (english ? 'Load more' : 'Xem thêm'),
                        ),
                      ),
                    ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_failed)
                    Text(
                      english
                          ? 'Unable to load more messages.'
                          : 'Không tải được lời nhắn tiếp theo.',
                    ),
                ],
              ),
            );
          },
        );
  }
}
