import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../../domain/models.dart';
import '../../../shared/presentation/author_mapper.dart';
import '../../../shared/presentation/feature_widgets.dart';
import '../domain/blocked_people.dart';
import 'blocked_people_controller.dart';

class BlockedPeoplePanel extends ConsumerWidget {
  const BlockedPeoplePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final state = ref.watch(blockedPeopleControllerProvider);
    final controller = ref.read(blockedPeopleControllerProvider.notifier);
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            en ? 'Blocked people' : 'Người đã chặn',
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            en ? 'People you have blocked.' : 'Những người bạn đã chặn.',
            style: VnlfTypography.meta(colors.muted),
          ),
          if (state.loading)
            Semantics(
              label: en ? 'Loading' : 'Đang tải',
              liveRegion: true,
              child: const LinearProgressIndicator(),
            ),
          if (state.confirmedName != null)
            Semantics(
              liveRegion: true,
              child: Text(
                en
                    ? 'Unblocked ${state.confirmedName}.'
                    : 'Đã bỏ chặn ${state.confirmedName}.',
              ),
            ),
          if (state.failed)
            Semantics(
              liveRegion: true,
              child: Text(
                state.uncertain && state.confirmedName != null
                    ? (en
                          ? 'Unblock was confirmed, but the list could not be refreshed.'
                          : 'Đã xác nhận bỏ chặn, nhưng chưa tải lại được danh sách.')
                    : state.uncertain
                    ? (en
                          ? 'The result could not be confirmed. Refresh before trying again.'
                          : 'Chưa thể xác nhận kết quả. Hãy làm mới trước khi thử lại.')
                    : (en
                          ? 'Could not load blocked people.'
                          : 'Chưa tải được danh sách người đã chặn.'),
                style: VnlfTypography.meta(colors.red),
              ),
            ),
          if (!state.loading && state.items != null && state.items!.isEmpty)
            Text(en ? 'You have not blocked anyone.' : 'Bạn chưa chặn ai.'),
          for (final person in state.items ?? const <BlockedPerson>[])
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: person.username.isEmpty
                  ? null
                  : () => context.push(
                      '/profile/${Uri.encodeComponent(person.username)}',
                    ),
              leading: VnlfAvatar(
                author: presentAuthor(
                  Author(
                    id: person.id,
                    username: person.username,
                    displayName: person.displayName,
                    avatarUrl: person.avatarUrl ?? '',
                  ),
                ),
                size: 40,
              ),
              title: Text(
                person.displayName.isEmpty
                    ? person.username
                    : person.displayName,
              ),
              subtitle: Text(
                '@${person.username}${person.bio.isEmpty ? '' : '\n${person.bio}'}',
              ),
              trailing: TextButton(
                onPressed: state.loading || state.uncertain
                    ? null
                    : () => controller.unblock(person),
                child: Text(en ? 'Unblock' : 'Bỏ chặn'),
              ),
            ),
          TextButton(
            onPressed: state.loading ? null : controller.refresh,
            child: Text(en ? 'Refresh' : 'Làm mới'),
          ),
        ],
      ),
    );
  }
}
