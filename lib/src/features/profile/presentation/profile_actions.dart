import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../domain/profile_relationship.dart';
import '../domain/public_profile.dart';
import 'profile_relationship_controller.dart';
import 'profile_relationship_copy.dart';

/// Follow and block controls for a member profile.
///
/// Guests get a sign-in path, owners and sample profiles get nothing, and a
/// member the viewer blocked can only be unblocked.
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
    if (session == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _FollowButton(
          label: copy.follow,
          semanticLabel: copy.signInToFollow,
          onPressed: () => context.push('/login'),
        ),
      );
    }
    final targetId = profile.author.id;
    final isOwner =
        targetId == session.userId ||
        (session.username.isNotEmpty &&
            session.username.toLowerCase() ==
                profile.author.username.toLowerCase());
    final repository = ref.watch(profileRelationshipRepositoryProvider);
    if (isOwner ||
        targetId.isEmpty ||
        repository == null ||
        profile.followedByViewer == null ||
        profile.blockedByViewer == null) {
      return const SizedBox.shrink();
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
    );
  }
}

class _SignedInActions extends ConsumerWidget {
  const _SignedInActions({
    super.key,
    required this.profile,
    required this.copy,
    required this.relationship,
  });
  final PublicProfile profile;
  final ProfileRelationshipCopy copy;
  final ProfileRelationshipKey relationship;

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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(copy.blockTitle),
          content: Text(copy.blockExplanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(copy.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(copy.confirmBlock),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await controller.perform(ProfileRelationshipAction.block, profile);
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (blocked)
          _FollowButton(
            label: busy ? copy.updating : copy.unblock,
            semanticLabel: copy.unblockLabel,
            icon: Icons.block,
            onPressed: busy
                ? null
                : () => controller.perform(
                    ProfileRelationshipAction.unblock,
                    profile,
                  ),
          )
        else
          _FollowButton(
            label: busy
                ? copy.updating
                : followed
                ? copy.following
                : copy.follow,
            semanticLabel: copy.followToggleLabel(followed),
            toggled: followed,
            icon: followed
                ? Icons.check_rounded
                : Icons.person_add_alt_1_rounded,
            onPressed: busy
                ? null
                : () => controller.perform(
                    followed
                        ? ProfileRelationshipAction.unfollow
                        : ProfileRelationshipAction.follow,
                    profile,
                  ),
          ),
        if (blocked) Text(copy.blockedHint),
        if (!blocked)
          PopupMenuButton<void>(
            tooltip: copy.moreOptions,
            enabled: !busy,
            icon: const Icon(Icons.more_horiz_rounded),
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                onTap: block,
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(copy.block),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.icon,
    this.toggled,
  });
  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(minimumSize: const Size(48, 48));
    return Semantics(
      button: true,
      toggled: toggled,
      label: semanticLabel,
      excludeSemantics: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: icon == null
          ? OutlinedButton(
              style: style,
              onPressed: onPressed,
              child: Text(label),
            )
          : OutlinedButton.icon(
              style: style,
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
            ),
    );
  }
}
