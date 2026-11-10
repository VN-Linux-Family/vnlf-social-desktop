import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../direct_messages/presentation/direct_message_feedback.dart';
import '../../direct_messages/presentation/direct_message_state.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/profile_relationship.dart';
import '../domain/public_profile.dart';
import 'profile_actions.dart';
import 'profile_data.dart';
import 'profile_links_row.dart';
import 'profile_palette.dart';
import 'profile_relationship_controller.dart';
import 'profile_relationship_copy.dart';

/// Marks the page of [username], whose own links show no card, as the
/// website skips links to the profile being viewed.
class ProfilePageScope extends InheritedWidget {
  const ProfilePageScope({
    super.key,
    required this.username,
    required super.child,
  });

  final String username;

  static String? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfilePageScope>()?.username;

  @override
  bool updateShouldNotify(ProfilePageScope oldWidget) =>
      username != oldWidget.username;
}

/// Gives every link to a profile the website's card (`profile-card.tsx`):
/// with a mouse it opens after 450 ms over the link and closes 250 ms after
/// the pointer leaves both; on touch a 500 ms press opens it as a sheet.
class ProfileCardScope extends StatefulWidget {
  const ProfileCardScope({super.key, required this.child});

  final Widget child;

  @override
  State<ProfileCardScope> createState() => _ProfileCardScopeState();
}

class _ProfileCardScopeState extends State<ProfileCardScope> {
  final _host = _CardHost();

  @override
  void dispose() {
    _host.close();
    super.dispose();
  }

  Widget _trigger(BuildContext context, String username, Widget child) =>
      _ProfileCardTrigger(host: _host, username: username, child: child);

  @override
  Widget build(BuildContext context) =>
      VnlfProfilePreview(builder: _trigger, child: widget.child);
}

/// The one hover card on screen.
final class _CardHost {
  OverlayEntry? _entry;
  Object? _owner;
  Timer? _hide;

  bool shows(Object owner) => _entry != null && identical(_owner, owner);

  void show(OverlayState overlay, Object owner, String username, Rect anchor) {
    close();
    _owner = owner;
    final entry = OverlayEntry(
      builder: (context) => CustomSingleChildLayout(
        delegate: _CardLayout(anchor),
        child: MouseRegion(
          onEnter: (_) => keep(),
          onExit: (_) => release(),
          child: ProfileCard(username: username, onClose: close),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  void keep() => _hide?.cancel();

  void release() {
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 250), close);
  }

  /// Closes the card, or only [owner]'s card when given.
  void close([Object? owner]) {
    if (owner != null && !identical(owner, _owner)) return;
    _hide?.cancel();
    _hide = null;
    _entry?.remove();
    _entry = null;
    _owner = null;
  }
}

/// Below the link when the card fits, otherwise above it, and never closer
/// than 8px to the window's edges.
class _CardLayout extends SingleChildLayoutDelegate {
  const _CardLayout(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final below = anchor.bottom + 8 + childSize.height <= size.height;
    final top = below
        ? anchor.bottom + 8
        : math.max(8.0, anchor.top - childSize.height - 8);
    final left = math.max(
      8.0,
      math.min(size.width - childSize.width - 8, anchor.left),
    );
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_CardLayout oldDelegate) => oldDelegate.anchor != anchor;
}

class _ProfileCardTrigger extends StatefulWidget {
  const _ProfileCardTrigger({
    required this.host,
    required this.username,
    required this.child,
  });

  final _CardHost host;
  final String username;
  final Widget child;

  @override
  State<_ProfileCardTrigger> createState() => _ProfileCardTriggerState();
}

class _ProfileCardTriggerState extends State<_ProfileCardTrigger> {
  Timer? _show;
  var _hovered = false;

  bool get _wanted =>
      ProfilePageScope.of(context)?.toLowerCase() !=
      widget.username.toLowerCase();

  void _enter(PointerEnterEvent event) {
    if (event.kind != PointerDeviceKind.mouse || !_wanted) return;
    _hovered = true;
    widget.host.keep();
    _show?.cancel();
    _show = Timer(const Duration(milliseconds: 450), _open);
  }

  void _exit(PointerExitEvent event) {
    _hovered = false;
    _show?.cancel();
    if (widget.host.shows(this)) widget.host.release();
  }

  void _open() {
    if (!mounted || !_hovered) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final origin = overlay.context.findRenderObject();
    final anchor =
        box.localToGlobal(
          Offset.zero,
          ancestor: origin is RenderBox ? origin : null,
        ) &
        box.size;
    widget.host.show(overlay, this, widget.username, anchor);
  }

  Future<void> _openSheet() async {
    if (!_wanted) return;
    widget.host.close();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x730C0E0D),
      builder: (sheet) => ProfileCard(
        username: widget.username,
        sheet: true,
        onClose: () => Navigator.of(sheet).pop(),
      ),
    );
  }

  @override
  void dispose() {
    _show?.cancel();
    widget.host.close(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: _enter,
    onExit: _exit,
    // Opening the link closes the card and any card about to open.
    child: Listener(
      onPointerDown: (_) {
        _show?.cancel();
        widget.host.close();
      },
      child: GestureDetector(
        supportedDevices: const {
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
        },
        onLongPress: _openSheet,
        child: widget.child,
      ),
    ),
  );
}

/// The card itself: the cover, the avatar over its edge, name, handle and
/// level, status, bio, links, then follow, message and the profile link.
/// [sheet] is the phone's version, full width at the bottom of the screen.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({
    super.key,
    required this.username,
    required this.onClose,
    this.sheet = false,
  });

  final String username;
  final VoidCallback onClose;
  final bool sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final media = MediaQuery.of(context);
    final phone = media.size.width < 841;
    final profile = ref.watch(profileProvider(username)).valueOrNull;
    final palette = ProfilePalette.of(
      context,
      profile?.decor ?? const ProfileDecor(),
    );
    final author = presentAuthor(
      profile?.author ?? Author(username: username, displayName: username),
    );
    final cover = profile?.decor.coverSmallUrl ?? profile?.coverUrl;
    final muted = VnlfTypography.plain(colors.muted);
    final level = profile?.level;
    final bio = profile?.bio?.trim().replaceAll(RegExp(r'\s+'), ' ');
    final status = profile?.decor.status;
    final width = sheet ? media.size.width : 300.0;
    final radius = sheet
        ? const BorderRadius.vertical(top: Radius.circular(14))
        : BorderRadius.circular(14);
    final card = Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: sheet ? null : Border.all(color: colors.line),
        boxShadow: sheet ? null : vnlfHardShadow(colors),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      gradient: cover == null
                          ? palette.cover(Size(width, 84))
                          : null,
                    ),
                  ),
                  if (cover != null)
                    Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                  if (sheet)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _CloseButton(
                        size: phone ? 48 : 40,
                        onPressed: onClose,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                0,
                14,
                14 + (sheet ? media.padding.bottom : 0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The avatar takes 30px of the column and rises 30px over
                  // the cover, the website's `margin-top: -30px`.
                  SizedBox(
                    height: 30,
                    child: OverflowBox(
                      alignment: Alignment.bottomLeft,
                      minHeight: 60,
                      maxHeight: 60,
                      child: Container(
                        width: 60,
                        height: 60,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: VnlfAvatar(
                          author: author,
                          size: 52,
                          cornerRadius: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (profile == null)
                    Text(
                      username,
                      style: VnlfTypography.plain(
                        colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    VnlfAuthorNameRow(author: author, showHandleInline: false),
                  const SizedBox(height: 4),
                  Text(
                    level == null
                        ? '@$username'
                        : '@$username · '
                              '${format(vi.decor.levelSo, {'level': '$level'})}',
                    style: muted,
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          '${status.emoji} ${status.text}',
                          style: VnlfTypography.plain(colors.ink)
                              .copyWith(height: 1.45),
                        ),
                      ),
                    ),
                  ],
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: VnlfTypography.plain(colors.ink)
                          .copyWith(height: 1.5),
                    ),
                  ],
                  if (profile != null &&
                      ProfileLinksRow.shows(profile.decor)) ...[
                    const SizedBox(height: 8),
                    ProfileLinksRow(
                      decor: profile.decor,
                      name: author.displayName,
                      accent: palette.accent,
                      compact: true,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _CardActions(
                    username: username,
                    profile: profile,
                    palette: palette,
                    sheet: sheet,
                    minHeight: sheet || phone ? 48 : 36,
                    onClose: onClose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: format(vi.decor.theHoSo, {'username': username}),
      child: card,
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.size, required this.onPressed});

  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: vi.decor.dongTheHoSo,
    child: Semantics(
      button: true,
      label: vi.decor.dongTheHoSo,
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: const Color(0x8C0C0E0D),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: const Center(
              child: VnlfIcon(VnlfLucide.x, size: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CardActions extends ConsumerWidget {
  const _CardActions({
    required this.username,
    required this.profile,
    required this.palette,
    required this.sheet,
    required this.minHeight,
    required this.onClose,
  });

  final String username;
  final PublicProfile? profile;
  final ProfilePalette palette;
  final bool sheet;
  final double minHeight;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);
    final router = GoRouter.of(context);
    final buttons = <Widget>[
      // Follow and message only once loaded, and never on one's own card.
      if (profile case final shown?
          when session?.userId != shown.author.id) ...[
        if (shown.blockedByViewer != true)
          _CardFollow(
            profile: shown,
            profileKey: username,
            palette: palette,
            minHeight: minHeight,
          ),
        if (session != null)
          ProfileOutlineButton(
            icon: VnlfLucide.messageCircle,
            label: vi.accountViews.nhanTin,
            minHeight: minHeight,
            onPressed: () async {
              onClose();
              final id = await ref
                  .read(dmInboxProvider.notifier)
                  .openOrRequestConversation(shown.author.id);
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
          ),
      ],
      ProfileOutlineButton(
        label: vi.decor.xemTrangCaNhan,
        minHeight: minHeight,
        onPressed: () {
          onClose();
          router.push('/profile/${Uri.encodeComponent(username)}');
        },
      ),
    ];
    if (!sheet) return Wrap(spacing: 6, runSpacing: 6, children: buttons);
    // The sheet's buttons share each line, as `flex: 1 1 auto` does.
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final button in buttons)
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth:
                    (constraints.maxWidth - 6 * (buttons.length - 1)) /
                    buttons.length,
              ),
              child: button,
            ),
        ],
      ),
    );
  }
}

class _CardFollow extends ConsumerWidget {
  const _CardFollow({
    required this.profile,
    required this.profileKey,
    required this.palette,
    required this.minHeight,
  });

  final PublicProfile profile;
  final String profileKey;
  final ProfilePalette palette;
  final double minHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ProfileRelationshipCopy(name: profile.author.displayName);
    final session = ref.watch(sessionStateProvider);
    if (session == null) {
      return _AccentButton(
        label: copy.follow,
        semanticLabel: copy.signInToFollow,
        palette: palette,
        minHeight: minHeight,
        onPressed: () => GoRouter.of(context).push('/login'),
      );
    }
    final repository = ref.watch(profileRelationshipRepositoryProvider);
    if (repository == null ||
        profile.followedByViewer == null ||
        profile.author.id.isEmpty) {
      return const SizedBox.shrink();
    }
    final key = (
      viewerId: session.userId,
      targetId: profile.author.id,
      username: profileKey,
    );
    ref.listen(profileRelationshipProvider(key), (before, after) {
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
    final busy = ref.watch(profileRelationshipProvider(key)).pending != null;
    final followed = profile.followedByViewer == true;
    void toggle() => ref
        .read(profileRelationshipProvider(key).notifier)
        .perform(
          followed
              ? ProfileRelationshipAction.unfollow
              : ProfileRelationshipAction.follow,
          profile,
        );
    final label = busy
        ? copy.updating
        : followed
        ? copy.following
        : copy.follow;
    if (followed) {
      return ProfileOutlineButton(
        icon: VnlfLucide.userCheck,
        label: label,
        semanticLabel: copy.followToggleLabel(true),
        toggled: true,
        minHeight: minHeight,
        onPressed: busy ? null : toggle,
      );
    }
    return _AccentButton(
      label: label,
      semanticLabel: copy.followToggleLabel(false),
      palette: palette,
      minHeight: minHeight,
      onPressed: busy ? null : toggle,
    );
  }
}

/// The website's `.publish-button` in the profile's accent.
class _AccentButton extends StatelessWidget {
  const _AccentButton({
    required this.label,
    required this.semanticLabel,
    required this.palette,
    required this.minHeight,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final ProfilePalette palette;
  final double minHeight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(VnlfDimensions.radiusSm);
    return Semantics(
      button: true,
      toggled: false,
      label: semanticLabel,
      excludeSemantics: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? .42 : 1,
        child: Material(
          color: palette.accent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: [
                    VnlfIcon(
                      VnlfLucide.userPlus,
                      size: 15,
                      color: palette.accentInk,
                    ),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VnlfTypography.plain(
                          palette.accentInk,
                          fontWeight: FontWeight.w700,
                        ),
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
  }
}
