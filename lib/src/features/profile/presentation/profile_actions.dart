import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../direct_messages/presentation/direct_message_feedback.dart';
import '../../direct_messages/presentation/direct_message_state.dart';
import '../domain/profile_relationship.dart';
import '../domain/public_profile.dart';
import 'profile_relationship_controller.dart';
import 'profile_relationship_copy.dart';

/// The website's `.profile-actions`: follow (edit for the owner, unblock
/// for someone the viewer blocked) and the "…" menu.
class ProfileActions extends ConsumerWidget {
  const ProfileActions({
    super.key,
    required this.profile,
    required this.profileKey,
  });
  final PublicProfile profile;

  /// The key `profileProvider` was opened with, which may be `self`.
  final String profileKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile.isSample) return const SizedBox.shrink();
    final copy = ProfileRelationshipCopy(name: profile.author.displayName);
    final session = ref.watch(sessionStateProvider);
    final targetId = profile.author.id;
    final owner =
        session != null &&
        (targetId == session.userId ||
            (session.username.isNotEmpty &&
                session.username.toLowerCase() ==
                    profile.author.username.toLowerCase()));
    if (session == null || owner) {
      return _ActionsRow(
        primary: owner
            ? ProfileOutlineButton(
                icon: VnlfLucide.penLine,
                label: vi.common.chinhSuaHoSo,
                onPressed: () => context.go('/settings'),
              )
            : ProfileOutlineButton(
                icon: VnlfLucide.userPlus,
                label: copy.follow,
                semanticLabel: copy.signInToFollow,
                onPressed: () => context.push('/login'),
              ),
        menu: [
          if (owner) ...[
            VnlfMenuAction(
              icon: VnlfLucide.bookOpen,
              label: vi.common.quanLyBaiViet,
              onSelected: () => context.push('/my/articles'),
            ),
            VnlfMenuAction(
              icon: VnlfLucide.settings,
              label: vi.accountViews.caiDatTaiKhoan,
              onSelected: () => context.go('/settings'),
            ),
          ],
          _activity(context),
        ],
      );
    }
    final repository = ref.watch(profileRelationshipRepositoryProvider);
    if (targetId.isEmpty ||
        repository == null ||
        profile.followedByViewer == null ||
        profile.blockedByViewer == null) {
      return _ActionsRow(menu: [_message(context, ref), _activity(context)]);
    }
    return _SignedInActions(
      key: ValueKey('${session.userId}:$targetId'),
      profile: profile,
      copy: copy,
      relationship: (
        viewerId: session.userId,
        targetId: targetId,
        username: profileKey,
      ),
      message: _message(context, ref),
      activity: _activity(context),
    );
  }

  VnlfMenuAction _activity(BuildContext context) => VnlfMenuAction(
    icon: VnlfLucide.trophy,
    label: vi.accountViews.xemDiemHoatDong,
    onSelected: () => context.push('/activity'),
  );

  VnlfMenuAction _message(BuildContext context, WidgetRef ref) =>
      VnlfMenuAction(
        icon: VnlfLucide.messageCircle,
        label: vi.accountViews.nhanTin,
        // As the website's "Nhắn tin" link, it opens the conversation with
        // this member, asking for one when there is none yet.
        onSelected: () async {
          final router = GoRouter.of(context);
          final id = await ref
              .read(dmInboxProvider.notifier)
              .openOrRequestConversation(profile.author.id);
          if (id != null) {
            router.go('/messages/$id');
            return;
          }
          if (!context.mounted) return;
          final failure = ref.read(dmInboxProvider).actionFailure;
          if (failure == null) return;
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(dmFailureMessage(context, failure))),
            );
        },
      );
}

class _SignedInActions extends ConsumerWidget {
  const _SignedInActions({
    super.key,
    required this.profile,
    required this.copy,
    required this.relationship,
    required this.message,
    required this.activity,
  });
  final PublicProfile profile;
  final ProfileRelationshipCopy copy;
  final ProfileRelationshipKey relationship;
  final VnlfMenuAction message;
  final VnlfMenuAction activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(profileRelationshipProvider(relationship), (before, after) {
      if (before?.revision == after.revision) return;
      final failure = after.failure;
      final completed = after.completed;
      final message = failure != null
          ? copy.failure(failure, after.attempted)
          : completed != null
          ? copy.done(completed)
          : null;
      if (message == null) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
    final state = ref.watch(profileRelationshipProvider(relationship));
    final controller = ref.read(
      profileRelationshipProvider(relationship).notifier,
    );
    final busy = state.pending != null;
    final blocked = profile.blockedByViewer == true;
    final followed = profile.followedByViewer == true;

    Future<void> block() async {
      final confirmed = await showVnlfConfirm(
        context,
        title: copy.blockTitle,
        description: copy.blockExplanation,
        confirmLabel: copy.confirmBlock,
      );
      if (confirmed) {
        await controller.perform(ProfileRelationshipAction.block, profile);
      }
    }

    void unblock() =>
        controller.perform(ProfileRelationshipAction.unblock, profile);

    return _ActionsRow(
      primary: blocked
          ? ProfileOutlineButton(
              icon: VnlfLucide.ban,
              label: busy ? copy.updating : copy.unblock,
              semanticLabel: copy.unblockLabel,
              tooltip: copy.blockedHint,
              onPressed: busy ? null : unblock,
            )
          : ProfileOutlineButton(
              // The website keeps user-plus in both states.
              icon: VnlfLucide.userPlus,
              label: busy
                  ? copy.updating
                  : followed
                  ? copy.following
                  : copy.follow,
              semanticLabel: copy.followToggleLabel(followed),
              toggled: followed,
              onPressed: busy
                  ? null
                  : () => controller.perform(
                      followed
                          ? ProfileRelationshipAction.unfollow
                          : ProfileRelationshipAction.follow,
                      profile,
                    ),
            ),
      menu: [
        message,
        activity,
        VnlfMenuAction(
          icon: VnlfLucide.ban,
          label: blocked ? copy.unblock : copy.block,
          danger: true,
          enabled: !busy,
          onSelected: blocked ? unblock : block,
        ),
      ],
    );
  }
}

/// The main button and the menu, side by side.
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({this.primary, required this.menu});

  final Widget? primary;
  final List<VnlfMenuAction> menu;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        if (primary case final primary?) Flexible(child: primary),
        _MenuButton(actions: menu),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.actions});

  final List<VnlfMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final size = MediaQuery.sizeOf(context).width < 841 ? 48.0 : 37.0;
    return Tooltip(
      message: vi.accountViews.moTuyChonHoSo,
      child: Semantics(
        button: true,
        label: vi.accountViews.moTuyChonHoSo,
        excludeSemantics: true,
        onTap: () => _open(context),
        child: InkWell(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
          onTap: () => _open(context),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: VnlfIcon(
                VnlfLucide.ellipsis,
                size: 18,
                color: colors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    showVnlfActionMenu(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      actions: actions,
      label: vi.accountViews.moTuyChonHoSo,
      dense: true,
    );
  }
}

/// The website's `.button-outline`: a bordered surface button with a 15px
/// icon. Phones keep 48dp targets where the website's is 34px tall.
class ProfileOutlineButton extends StatelessWidget {
  const ProfileOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.tooltip,
    this.toggled,
    this.minHeight,
  });

  final VnlfLucide? icon;

  /// 34 by default (48 on phones).
  final double? minHeight;
  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final radius = BorderRadius.circular(VnlfDimensions.radiusMd);
    final phone = MediaQuery.sizeOf(context).width < 841;
    final button = Semantics(
      button: true,
      toggled: toggled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? .42 : 1,
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: colors.line),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight ?? (phone ? 48 : 34),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    if (icon case final icon?)
                      VnlfIcon(icon, size: 15, color: colors.ink),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VnlfTypography.plain(colors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
