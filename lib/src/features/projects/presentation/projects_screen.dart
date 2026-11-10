import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../profile/presentation/profile_actions.dart';
import '../../shared/presentation/page_header_actions.dart';
import '../domain/project_directory.dart';
import 'project_card.dart';
import 'project_directory_controller.dart';

// Retained for other consumers of the original first-page provider.
final projectsProvider = FutureProvider<ProjectsPage>(
  (ref) => ref.watch(projectsRepositoryProvider).getProjects(),
);

/// The website's "Dự án" page (`ProjectsView`, project-views.tsx): an intro
/// with "Đăng dự án", the search, sort, language and "Tìm người đóng góp"
/// filters, the type chips, then the projects in tier sections (or one
/// grid when sorted otherwise) and "Xem thêm".
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({
    super.key,
    this.initialFilters = const ProjectFilters(),
  });

  /// The filters a `/projects?…` link carries.
  final ProjectFilters initialFilters;

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  late final _search = TextEditingController(text: widget.initialFilters.query);

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != const ProjectFilters()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(projectDirectoryProvider.notifier)
            .setFilters(widget.initialFilters);
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(projectDirectoryProvider);
    final controller = ref.read(projectDirectoryProvider.notifier);
    final filters = directory.filters;
    final width = MediaQuery.sizeOf(context).width;
    final phone = VnlfViewportSize.fromWidth(width) == VnlfViewportSize.mobile;
    final items = directory.items;
    final List<Widget> results;
    if (directory.loading && items.isEmpty) {
      results = [
        VnlfSkeletonBox(
          width: double.infinity,
          height: math.min(360, MediaQuery.sizeOf(context).height * 0.52),
          borderRadius: VnlfDimensions.radiusLg,
          semanticLabel: vi.loading.dangTai,
        ),
      ];
    } else if (directory.error != null && items.isEmpty) {
      results = [_LoadError(onRetry: () => controller.load(refresh: true))];
    } else if (items.isEmpty) {
      results = [_Empty(filters: filters)];
    } else if (filters.sort == 'featured') {
      final groups = groupByTier(items);
      results = [
        for (var index = 0; index < groups.length; index++)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                _TierHeading(tier: groups[index].first.tier),
                ProjectGrid(items: groups[index]),
              ],
            ),
          ),
      ];
    } else {
      results = [
        ProjectGrid(items: items, trending: filters.sort == 'trending'),
      ];
    }
    final dimmed = directory.loading && items.isNotEmpty;
    final list = RefreshIndicator(
      onRefresh: () {
        HapticFeedback.lightImpact();
        return controller.load(refresh: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: phone
            ? EdgeInsets.fromLTRB(
                8,
                10,
                8,
                68 + MediaQuery.viewPaddingOf(context).bottom,
              )
            : const EdgeInsets.only(bottom: 40),
        children: [
          _Intro(
            onSubmit: () => context.push(
              ref.read(sessionStateProvider) == null
                  ? '/login'
                  : '/projects/submit',
            ),
          ),
          const SizedBox(height: 20),
          _Toolbar(
            search: _search,
            filters: filters,
            languages: directory.languages,
            onSearch: controller.search,
            onFilters: controller.setFilters,
          ),
          const SizedBox(height: 10),
          _TypeChips(
            filters: filters,
            types: directory.types,
            onFilters: controller.setFilters,
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: dimmed ? 0.65 : 1,
            duration: VnlfDimensions.resolveDuration(
              context,
              VnlfDimensions.motionFast,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: results,
            ),
          ),
          if (directory.nextCursor != null && items.isNotEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: ProfileOutlineButton(
                label: directory.loadingMore
                    ? vi.common.dangTai
                    : vi.projects.xemThem,
                onPressed: directory.loadingMore
                    ? null
                    : () => controller.load(more: true),
                minHeight: phone ? 48 : null,
              ),
            ),
          ],
        ],
      ),
    );
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!phone)
          VnlfCenterPageHeader(
            title: vi.projects.tieuDe,
            trailing: const PageHeaderActions(),
          ),
        Expanded(child: list),
      ],
    );
    if (phone) return page;
    // A wide page on the website: up to 1104px, so the grid can show four.
    // The shell leaves this column's padding to the page.
    final tablet = VnlfViewportSize.fromWidth(width) == VnlfViewportSize.tablet;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1104 + (tablet ? 40 : 76)),
        child: Padding(
          padding: tablet
              ? const EdgeInsets.fromLTRB(20, 16, 20, 0)
              : const EdgeInsets.fromLTRB(38, 34, 38, 0),
          child: page,
        ),
      ),
    );
  }
}

/// `.projects-intro`: what the page is for, and "Đăng dự án".
class _Intro extends StatelessWidget {
  const _Intro({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final text = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Text(
        vi.projects.moTaTrang,
        style: VnlfTypography.body(colors.ink),
      ),
    );
    final button = _PublishButton(
      label: vi.projects.dangDuAn,
      onPressed: onSubmit,
      expand: width <= 640 && width > 520,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: VnlfCssGradient(
          angle: 135,
          colors: [colors.brandSoft, colors.surface, colors.surface],
          stops: const [0, 0.7, 1],
        ),
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: width <= 640
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                text,
                if (width > 520)
                  button
                else
                  Align(alignment: Alignment.centerRight, child: button),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 16,
              children: [
                Flexible(child: text),
                button,
              ],
            ),
    );
  }
}

/// The website's `.publish-button`: white on brand, in both themes.
class _PublishButton extends StatelessWidget {
  const _PublishButton({
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final radius = BorderRadius.circular(VnlfDimensions.radiusSm);
    return Material(
      color: colors.brand,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: phone ? 48 : 34),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                const VnlfIcon(VnlfLucide.plus, size: 16, color: Colors.white),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: VnlfTypography.control(
                      Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.projects-toolbar`: the search grows; sort, language and "Tìm người
/// đóng góp" keep their width and wrap below on narrow screens.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.search,
    required this.filters,
    required this.languages,
    required this.onSearch,
    required this.onFilters,
  });

  final TextEditingController search;
  final ProjectFilters filters;
  final List<ProjectFacet> languages;
  final ValueChanged<String> onSearch;
  final ValueChanged<ProjectFilters> onFilters;

  @override
  Widget build(BuildContext context) {
    final sort = VnlfSelect<String>(
      label: vi.projects.sapXepLabel,
      value: filters.sort,
      options: [
        for (final value in projectSorts)
          VnlfSelectOption(value, vi.projects.sapXep[value] ?? value),
      ],
      onChanged: (value) => onFilters(filters.copyWith(sort: value)),
    );
    final language = VnlfSelect<String>(
      label: vi.projects.ngonNgu,
      value: filters.language,
      options: [
        VnlfSelectOption('', vi.projects.tatCaNgonNgu),
        for (final facet in languages)
          VnlfSelectOption(
            facet.name,
            format(vi.projects.demTheLoai, {
              'label': facet.name,
              'count': facet.count,
            }),
          ),
        if (filters.language.isNotEmpty &&
            !languages.any((facet) => facet.name == filters.language))
          VnlfSelectOption(filters.language, filters.language),
      ],
      onChanged: (value) => onFilters(filters.copyWith(language: value)),
    );
    final seeking = _CheckField(
      label: vi.projects.timNguoiDongGop,
      value: filters.seeking,
      onChanged: (value) => onFilters(filters.copyWith(seeking: value)),
    );
    final box = _SearchBox(controller: search, onChanged: onSearch);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 683) {
          return Row(
            spacing: 12,
            children: [
              Expanded(child: box),
              sort,
              language,
              seeking,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            box,
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [sort, language, seeking],
            ),
          ],
        );
      },
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    return Container(
      // 40px on the website; phones keep a 48dp touch target.
      height: phone ? 48 : 40,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      child: Row(
        spacing: 8,
        children: [
          VnlfIcon(VnlfLucide.search, size: 16, color: colors.muted),
          Expanded(
            child: Semantics(
              label: vi.projects.timKiem,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                style: VnlfTypography.plain(colors.ink),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: vi.projects.timKiemGoiY,
                  hintStyle: VnlfTypography.plain(colors.muted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The website's `.check-field`: an 18px box and its label.
class _CheckField extends StatelessWidget {
  const _CheckField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    return Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: phone ? 48 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: value ? colors.brand : colors.surface,
                  border: Border.all(
                    color: value ? colors.brand : colors.muted,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: value
                    ? VnlfIcon(
                        VnlfLucide.check,
                        size: 14,
                        color: colors.isDark ? colors.bg : Colors.white,
                      )
                    : null,
              ),
              // One line on the website; it wraps only at large text sizes.
              Flexible(
                child: Text(label, style: VnlfTypography.body(colors.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.projects-types`: "Mọi thể loại", then each type with projects, in one
/// row that scrolls sideways.
class _TypeChips extends StatelessWidget {
  const _TypeChips({
    required this.filters,
    required this.types,
    required this.onFilters,
  });

  final ProjectFilters filters;
  final List<ProjectFacet> types;
  final ValueChanged<ProjectFilters> onFilters;

  @override
  Widget build(BuildContext context) {
    final counts = {for (final facet in types) facet.name: facet.count};
    return Semantics(
      container: true,
      label: vi.projects.theLoai,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          spacing: 6,
          children: [
            _TypeChip(
              label: vi.projects.tatCaTheLoai,
              selected: filters.type.isEmpty,
              onTap: () => onFilters(filters.copyWith(type: '')),
            ),
            for (final type in projectTypes)
              if ((counts[type] ?? 0) > 0 || filters.type == type)
                _TypeChip(
                  label: format(vi.projects.demTheLoai, {
                    'label': vi.projects.loai[type] ?? type,
                    'count': counts[type] ?? 0,
                  }),
                  selected: filters.type == type,
                  onTap: () => onFilters(
                    filters.copyWith(type: filters.type == type ? '' : type),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
      side: BorderSide(color: selected ? colors.brand : colors.line),
    );
    return Semantics(
      button: true,
      toggled: selected,
      child: Material(
        color: selected ? colors.brandSoft : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: phone ? 48 : 34),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: VnlfTypography.control(
                    selected ? colors.brand : colors.muted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

/// `.projects-tier-head`: the tier's mark, title and one line about it.
class _TierHeading extends StatelessWidget {
  const _TierHeading({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    Color mix(Color color, double amount, [Color? base]) =>
        Color.lerp(base ?? colors.surface, color, amount)!;
    final (border, gradient, markBackground, ring, mark) = switch (tier) {
      'VNLF' => (
        mix(colors.brand, 0.35, colors.line),
        VnlfCssGradient(
          angle: 110,
          colors: [colors.brandSoft, colors.surface],
          stops: const [0, 0.72],
        ),
        colors.surface,
        colors.brand,
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: BrandAssets.logo(size: 26),
        ) as Widget,
      ),
      'PARTNER' => (
        mix(colors.tierPartner, 0.35, colors.line),
        VnlfCssGradient(
          angle: 110,
          colors: [mix(colors.tierPartner, 0.12), colors.surface],
          stops: const [0, 0.72],
        ),
        mix(colors.tierPartner, 0.15),
        colors.tierPartner.withValues(alpha: 0.55),
        VnlfIcon(VnlfLucide.handshake, size: 18, color: colors.tierPartner),
      ),
      _ => (
        colors.line,
        null,
        mix(colors.blue, 0.12),
        null,
        VnlfIcon(VnlfLucide.users, size: 18, color: colors.blue),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: gradient == null ? colors.surface : null,
        gradient: gradient,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: markBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (ring != null) BoxShadow(color: ring, spreadRadius: 2),
              ],
            ),
            child: mark,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    vi.projects.tierTieuDe[tier] ?? tier,
                    style: VnlfTypography.h2(colors.ink),
                  ),
                ),
                Text(
                  vi.projects.tierMoTa[tier] ?? '',
                  style: VnlfTypography.meta(colors.muted)
                      .copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          spacing: 10,
          children: [
            Text(
              vi.projects.chuaTaiDuoc,
              textAlign: TextAlign.center,
              style: VnlfTypography.body(colors.muted),
            ),
            ProfileOutlineButton(label: vi.common.thuLai, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filters});

  final ProjectFilters filters;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 190),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 7,
          children: [
            VnlfIcon(VnlfLucide.folderGit2, size: 20, color: colors.muted),
            Text(
              filters.filtered
                  ? vi.projects.trongLoc
                  : filters.sort == 'trending'
                  ? vi.projects.trongDangLen
                  : vi.projects.trong,
              textAlign: TextAlign.center,
              style: VnlfTypography.control(
                colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
