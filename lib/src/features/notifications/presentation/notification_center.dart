import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/vnlf_navigation_helper.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/notifications_repository.dart';
import 'notice_copy.dart';
import 'notifications_controller.dart';

/// The website's notification center (`notification-center.tsx`): the
/// /notifications page, or the [compact] list in the bell's popover.
class NotificationCenter extends ConsumerWidget {
  const NotificationCenter({super.key, this.compact = false, this.onClose});

  final bool compact;

  /// Closes the popover. The page has no close button.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final phone = MediaQuery.sizeOf(context).width < 841;
    final now = DateTime.now();

    void open(CommunityNotice notice) {
      final router = GoRouter.of(context);
      onClose?.call();
      if (notice.unread) unawaited(controller.markRead(notice.id));
      final href = Uri.tryParse(notice.href);
      final route = href == null ? null : resolveInAppVnlfRoute(href);
      if (route != null) {
        unawaited(router.push(route));
      } else if (href != null) {
        unawaited(
          launchUrl(
            Uri.parse('https://vietnamlinuxfamily.net').resolve(notice.href),
            mode: LaunchMode.externalApplication,
          ),
        );
      }
    }

    final stream = <Widget>[];
    if (state.failure != null) {
      stream.add(
        _TextAction(
          label: vi.notificationCenter.khongTaiDuocThuLai,
          phone: phone,
          onTap: controller.refresh,
        ),
      );
    }
    String? previousDay;
    for (final notice in state.items) {
      final day = noticeDay(notice.updatedAt, now);
      if (day != previousDay) {
        stream.add(_DayHeading(day));
        previousDay = day;
      }
      stream.add(
        _NoticeRow(
          notice: notice,
          age: noticeAge(notice.updatedAt, now),
          phone: phone,
          onTap: () => open(notice),
        ),
      );
    }
    if (state.loading && state.items.isEmpty) {
      stream.add(_State(phone: phone, child: Text(vi.common.dangTai)));
    } else if (state.items.isEmpty && state.failure == null) {
      stream.add(
        _State(
          phone: phone,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              VnlfIcon(
                VnlfLucide.bell,
                size: 24,
                color: VnlfColors.of(context).muted,
              ),
              Text(vi.notificationCenter.khongCoThongBao),
            ],
          ),
        ),
      );
    }
    if (state.nextCursor != null) {
      stream.add(
        _LoadMore(
          loading: state.loading,
          onVisible: controller.loadMore,
          key: ValueKey(state.nextCursor),
        ),
      );
    }

    final top = <Widget>[
      if (compact || !phone) _Header(onClose: onClose, phone: phone),
      _Filters(state: state, controller: controller, phone: phone),
      Align(
        alignment: compact
            ? Alignment.center
            : AlignmentDirectional.centerStart,
        child: _TextAction(
          label: vi.notificationCenter.danhDauTatCaDa,
          phone: phone,
          stretch: compact,
          onTap: controller.markAllRead,
        ),
      ),
    ];

    if (!compact) {
      // One lazy list, 720px wide at most and centred like the website's
      // section, so the strip that loads more is built only near the end.
      final rows = [...top, ...stream];
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: rows.length,
        itemBuilder: (context, index) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SizedBox(width: double.infinity, child: rows[index]),
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...top,
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: stream.length,
            itemBuilder: (context, index) => stream[index],
          ),
        ),
        _TextAction(
          label: vi.notificationCenter.xemTatCa,
          phone: phone,
          alignStart: true,
          stretch: true,
          onTap: () {
            final router = GoRouter.of(context);
            onClose?.call();
            unawaited(router.push('/notifications'));
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.phone});

  final VoidCallback? onClose;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final close = onClose;
    return Padding(
      padding: EdgeInsets.all(phone ? 10 : 16),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                vi.common.thongBao,
                style: VnlfTypography.plain(
                  colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (close != null)
            IconButton(
              tooltip: vi.notificationCenter.dongThongBao,
              onPressed: close,
              style: IconButton.styleFrom(
                minimumSize: Size.square(phone ? 48 : 37),
                fixedSize: Size.square(phone ? 48 : 37),
                padding: EdgeInsets.zero,
                shape: phone
                    ? const CircleBorder()
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                      ),
              ),
              icon: VnlfIcon(
                VnlfLucide.x,
                size: 24,
                color: phone ? colors.ink : colors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.state,
    required this.controller,
    required this.phone,
  });

  final NotificationsState state;
  final NotificationsController controller;
  final bool phone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(
          label: vi.common.tatCa,
          pressed: !state.unreadOnly,
          phone: phone,
          onTap: () {
            if (state.unreadOnly) controller.refresh(unreadOnly: false);
          },
        ),
        _Pill(
          label: vi.notificationCenter.chuaDoc,
          pressed: state.unreadOnly,
          phone: phone,
          onTap: () {
            if (!state.unreadOnly) controller.refresh(unreadOnly: true);
          },
        ),
        VnlfSelect<NotificationKind>(
          label: vi.notificationCenter.loaiThongBao,
          value: state.kind,
          options: [
            VnlfSelectOption(
              NotificationKind.all,
              vi.notificationCenter.moiLoai,
            ),
            VnlfSelectOption(
              NotificationKind.like,
              vi.notificationCenter.luotThich,
            ),
            VnlfSelectOption(NotificationKind.comment, vi.common.binhLuan),
            VnlfSelectOption(NotificationKind.follow, vi.common.theoDoi),
            VnlfSelectOption(
              NotificationKind.system,
              vi.notificationCenter.heThong,
            ),
          ],
          onChanged: (kind) => controller.refresh(kind: kind),
        ),
      ],
    ),
  );
}

/// "Tất cả" and "Chưa đọc": round pills, tinted while pressed. On phones the
/// touch area grows to 48px around the 34px pill.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.pressed,
    required this.phone,
    required this.onTap,
  });

  final String label;
  final bool pressed;
  final bool phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final pill = DecoratedBox(
      decoration: BoxDecoration(
        color: pressed ? colors.brandSoft : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          label,
          style: VnlfTypography.plain(
            pressed ? colors.brand : colors.ink,
            fontWeight: pressed ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      toggled: pressed,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        hoverColor: Colors.transparent,
        child: phone
            ? ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(widthFactor: 1, child: pill),
              )
            : pill,
      ),
    );
  }
}

/// A plain brand-coloured text button: "Đánh dấu tất cả đã đọc", "Xem tất
/// cả", and the retry after a failed load.
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.phone,
    required this.onTap,
    this.stretch = false,
    this.alignStart = false,
  });

  final String label;
  final bool phone;
  final VoidCallback onTap;

  /// Full width, as a block in the popover's column.
  final bool stretch;

  /// Keeps the label at the start of a full-width button.
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final text = Text(
      label,
      textAlign: stretch && !alignStart ? TextAlign.center : TextAlign.start,
      style: VnlfTypography.plain(colors.brand),
    );
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: phone ? 48 : 0,
          minWidth: stretch ? double.infinity : 0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: stretch ? text : Align(widthFactor: 1, child: text),
        ),
      ),
    );
  }
}

class _DayHeading extends StatelessWidget {
  const _DayHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
    child: Semantics(
      header: true,
      child: Text(
        label,
        style: VnlfTypography.plain(
          VnlfColors.of(context).ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.notice,
    required this.age,
    required this.phone,
    required this.onTap,
  });

  final CommunityNotice notice;
  final String age;
  final bool phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final copy = TextStyle(
      fontFamily: VnlfTypography.fontFamily,
      fontSize: VnlfTypography.baseSize,
      height: 1.55,
      leadingDistribution: TextLeadingDistribution.even,
      color: colors.ink,
    );
    final actors = noticeActors(notice);
    final snippet = notificationSnippet(notice);
    final radius = BorderRadius.circular(VnlfDimensions.radiusMd);
    return Material(
      color: notice.unread ? colors.brandSoft : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        // Unread rows keep their tint under the pointer.
        hoverColor: notice.unread ? Colors.transparent : colors.surfaceSoft,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: phone ? 68 : 0),
          child: Padding(
            padding: phone
                ? const EdgeInsets.all(10)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              spacing: phone ? 9 : 14,
              children: [
                _NoticeAvatar(notice: notice),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: copy,
                          children: [
                            if (actors.shown.isEmpty)
                              const TextSpan(
                                text: 'VNLF',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            for (final (index, actor) in actors.shown.indexed)
                              ..._name(actor, first: index == 0, style: copy),
                            if (actors.more.isNotEmpty)
                              TextSpan(
                                text: actors.more,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            TextSpan(
                              text:
                                  ' ${notificationAction(notice.type, notice.payload)}',
                            ),
                          ],
                        ),
                      ),
                      Text(
                        snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: copy.copyWith(color: colors.muted),
                      ),
                      Text(
                        age,
                        style: copy.copyWith(
                          color: notice.unread ? colors.brand : colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notice.unread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A name as the website draws it everywhere, colour and effects included,
  /// after " và " for the second one.
  List<InlineSpan> _name(
    Author actor, {
    required bool first,
    required TextStyle style,
  }) => [
    if (!first) TextSpan(text: vi.notificationCenter.va),
    WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: VnlfAuthorNameRow(
        author: presentAuthor(actor),
        showHandleInline: false,
        fontWeight: FontWeight.w600,
      ),
    ),
  ];
}

class _NoticeAvatar extends StatelessWidget {
  const _NoticeAvatar({required this.notice});

  final CommunityNotice notice;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final actor = notice.actors.firstOrNull;
    final kind = noticeKind(notice.type);
    return SizedBox.square(
      dimension: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          VnlfAvatar(
            author: actor == null
                ? const AuthorData(id: '', username: '', displayName: 'VNLF')
                : presentAuthor(actor),
            size: 48,
          ),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: switch (kind) {
                  NoticeKind.like => colors.red,
                  NoticeKind.follow => colors.brand,
                  NoticeKind.points => colors.orange,
                  NoticeKind.comment || NoticeKind.system => colors.blue,
                },
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
              ),
              alignment: Alignment.center,
              child: VnlfIcon(
                noticeIcon(notice.type),
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _State extends StatelessWidget {
  const _State({required this.phone, required this.child});

  final bool phone;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: phone ? 10 : 16, vertical: 24),
    child: DefaultTextStyle.merge(
      style: VnlfTypography.plain(VnlfColors.of(context).muted),
      child: Semantics(liveRegion: true, child: child),
    ),
  );
}

/// The strip at the end of the list that loads the next page once it comes
/// into view, like the website's IntersectionObserver.
class _LoadMore extends StatefulWidget {
  const _LoadMore({super.key, required this.loading, required this.onVisible});

  final bool loading;
  final Future<void> Function() onVisible;

  @override
  State<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<_LoadMore> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.onVisible());
    });
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 32),
    child: Center(
      child: Text(
        widget.loading ? vi.notificationCenter.dangTaiThem : '',
        style: VnlfTypography.plain(VnlfColors.of(context).muted),
      ),
    ),
  );
}
