import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/live_people_repository.dart';
import '../domain/people.dart';
import 'profile_actions.dart';
import 'profile_data.dart';
import 'profile_relationship_controller.dart';

/// Null in fixture mode, where the counts open nothing.
final peopleRepositoryProvider = Provider<PeopleRepository?>(
  (ref) => offlineFeatures
      ? null
      : LivePeopleRepository(ref.watch(apiClientProvider)),
);

/// The website's `PeopleDialog`: who follows [username] and whom they
/// follow, opened from the two counts on the profile.
Future<void> showPeopleDialog(
  BuildContext context, {
  required String username,
  required String name,
  required PeopleTab initial,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: vi.dialog.dongHopThoai,
  barrierColor: const Color(0x66101A14),
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 150),
  pageBuilder: (context, _, _) =>
      _PeopleDialog(username: username, name: name, initial: initial),
);

class _PeopleDialog extends ConsumerStatefulWidget {
  const _PeopleDialog({
    required this.username,
    required this.name,
    required this.initial,
  });

  final String username;
  final String name;
  final PeopleTab initial;

  @override
  ConsumerState<_PeopleDialog> createState() => _PeopleDialogState();
}

class _PeopleDialogState extends ConsumerState<_PeopleDialog> {
  late PeopleTab _tab = widget.initial;
  var _items = <PersonRow>[];
  String? _next;
  var _loading = true;
  var _failed = false;
  var _loadingMore = false;
  final _pending = <String>{};

  /// Bumped on every new list, so a late page of another tab is dropped.
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    final repository = ref.read(peopleRepositoryProvider);
    if (repository == null) return;
    final generation = more ? _generation : ++_generation;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _items = [];
        _next = null;
        _loading = true;
        _failed = false;
      }
    });
    try {
      final page = await repository.list(
        widget.username,
        _tab,
        cursor: more ? _next : null,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = [..._items, ...page.items];
        _next = page.nextCursor;
        _loading = false;
        _loadingMore = false;
      });
    } on AppFailure {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _failed = !more;
      });
    }
  }

  void _select(PeopleTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    _load();
  }

  Future<void> _toggle(PersonRow person) async {
    final repository = ref.read(profileRelationshipRepositoryProvider);
    final id = person.author.id;
    if (repository == null || id.isEmpty || !_pending.add(id)) return;
    setState(() {});
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await repository.setFollowing(id, following: !person.followedByViewer);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final item in _items)
            item.author.id == id
                ? item.following(!person.followedByViewer)
                : item,
        ];
      });
      // Counts and buttons on any open profile read the change again.
      ref.invalidate(profileProvider);
    } on AppFailure {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(vi.accountViews.chuaTheCapNhatTheo)),
        );
    } finally {
      if (mounted) setState(() => _pending.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final margin = size.width <= 520 ? 16.0 : 20.0;
    final title = format(vi.people.tieuDe, {'name': widget.name});
    final signedIn = ref.watch(sessionStateProvider) != null;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(margin),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: size.height - 40,
            ),
            child: Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
                side: BorderSide(color: colors.line),
              ),
              elevation: 0,
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: title,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: VnlfTypography.plain(
                                colors.ink,
                                fontWeight: FontWeight.w700,
                              ).copyWith(height: 1.4),
                            ),
                          ),
                          VnlfCloseButton(
                            size: 20,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tab in PeopleTab.values)
                            _TabPill(
                              label: tab == PeopleTab.followers
                                  ? vi.people.nguoiTheoDoi
                                  : vi.people.dangTheoDoi,
                              selected: tab == _tab,
                              onTap: () => _select(tab),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Flexible(child: _panel(colors, signedIn)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(VnlfColors colors, bool signedIn) {
    final muted = VnlfTypography.plain(colors.muted);
    if (_loading) {
      return Semantics(
        liveRegion: true,
        child: Text(vi.common.dangTai, style: muted),
      );
    }
    if (_failed) {
      return Row(
        spacing: 10,
        children: [
          Expanded(child: Text(vi.people.chuaTaiDuoc, style: muted)),
          ProfileOutlineButton(label: vi.common.thuLai, onPressed: _load),
        ],
      );
    }
    if (_items.isEmpty) {
      return Text(
        _tab == PeopleTab.followers
            ? vi.people.chuaCoNguoiTheoDoi
            : vi.people.chuaTheoDoiAi,
        style: muted,
      );
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final person in _items)
          _PersonTile(
            person: person,
            pending: _pending.contains(person.author.id),
            signedIn: signedIn,
            onToggle: () => _toggle(person),
          ),
        if (_next != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ProfileOutlineButton(
                label: _loadingMore ? vi.common.dangTai : vi.people.xemThem,
                onPressed: _loadingMore ? null : () => _load(more: true),
              ),
            ),
          ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final ink = selected ? colors.brand : colors.muted;
    final shape = StadiumBorder(
      side: BorderSide(color: selected ? colors.brand : colors.line),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? colors.brandSoft : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).width < 841 ? 48 : 36,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: VnlfTypography.plain(ink, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.pending,
    required this.signedIn,
    required this.onToggle,
  });

  final PersonRow person;
  final bool pending;
  final bool signedIn;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final author = presentAuthor(person.author);
    final phone = MediaQuery.sizeOf(context).width < 841;
    final router = GoRouter.of(context);
    void open() {
      Navigator.of(context).pop();
      router.push('/profile/${Uri.encodeComponent(person.author.username)}');
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: InkWell(
                onTap: open,
                child: Row(
                  spacing: 10,
                  children: [
                    VnlfAvatar(
                      author: author,
                      size: 31,
                      cornerRadius: VnlfDimensions.radiusMd,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VnlfAuthorNameRow(
                            author: author,
                            showHandleInline: false,
                            allowWrap: false,
                          ),
                          Text(
                            '@${person.author.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VnlfTypography.plain(colors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (person.isViewer)
              Text(
                vi.people.ban,
                style: VnlfTypography.plain(
                  colors.muted,
                  fontWeight: FontWeight.w700,
                ),
              )
            else if (signedIn)
              person.followedByViewer
                  ? ProfileOutlineButton(
                      label: vi.accountViews.dangTheoDoi,
                      toggled: true,
                      minHeight: phone ? 48 : 36,
                      onPressed: pending ? null : onToggle,
                    )
                  : _FollowPill(
                      minHeight: phone ? 48 : 36,
                      onPressed: pending ? null : onToggle,
                    ),
          ],
        ),
      ),
    );
  }
}

/// The website's green `.publish-button` "Theo dõi".
class _FollowPill extends StatelessWidget {
  const _FollowPill({required this.minHeight, required this.onPressed});

  final double minHeight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final radius = BorderRadius.circular(VnlfDimensions.radiusSm);
    return Semantics(
      button: true,
      toggled: false,
      label: vi.common.theoDoi,
      excludeSemantics: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? .42 : 1,
        child: Material(
          color: colors.brand,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    vi.common.theoDoi,
                    style: VnlfTypography.plain(
                      colors.isDark ? const Color(0xFF102116) : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
