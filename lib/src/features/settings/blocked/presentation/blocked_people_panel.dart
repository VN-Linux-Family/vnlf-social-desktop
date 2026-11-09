import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../../domain/models.dart';
import '../../../../i18n/vi.dart';
import '../../../shared/presentation/author_mapper.dart';
import '../../../shared/presentation/feature_widgets.dart';
import '../domain/blocked_people.dart';
import 'blocked_people_controller.dart';

class BlockedPeoplePanel extends ConsumerWidget {
  const BlockedPeoplePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final state = ref.watch(blockedPeopleControllerProvider);
    final controller = ref.read(blockedPeopleControllerProvider.notifier);
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            vi.app.settings.nguoiDaChan,
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            vi.app.settings.nhungNguoiBanDa,
            style: VnlfTypography.meta(colors.muted),
          ),
          if (state.loading)
            Semantics(
              label: vi.loading.dangTai,
              liveRegion: true,
              child: const LinearProgressIndicator(),
            ),
          if (state.confirmedName != null)
            Semantics(
              liveRegion: true,
              child: Text(
                format(vi.app.settings.daBoChan, {
                  'confirmedName': state.confirmedName,
                }),
              ),
            ),
          if (state.failed)
            Semantics(
              liveRegion: true,
              child: Text(
                state.uncertain && state.confirmedName != null
                    ? vi.app.settings.daXacNhanBo
                    : state.uncertain
                    ? vi.app.settings.chuaTheXacNhan
                    : vi.app.settings.chuaTaiDuocDanh,
                style: VnlfTypography.meta(colors.red),
              ),
            ),
          if (!state.loading && state.items != null && state.items!.isEmpty)
            Text(vi.people.chuaChanAi),
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
                child: Text(vi.people.boChan),
              ),
            ),
          TextButton(
            onPressed: state.loading ? null : controller.refresh,
            child: Text(vi.app.common.lamMoi),
          ),
        ],
      ),
    );
  }
}
