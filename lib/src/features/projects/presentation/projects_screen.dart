import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../domain/project_directory.dart';
import 'project_detail_sheet.dart';
import 'project_directory_controller.dart';

// Retained for other consumers of the original first-page provider.
final projectsProvider = FutureProvider<ProjectsPage>(
  (ref) => ref.watch(projectsRepositoryProvider).getProjects(),
);

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final directory = ref.watch(projectDirectoryProvider);
    final controller = ref.read(projectDirectoryProvider.notifier);
    final filters = directory.filters;
    const typeLabels = {
      'APP': 'Ứng dụng',
      'TOOL': 'Công cụ',
      'LIBRARY': 'Thư viện',
      'DISTRO': 'Bản phân phối',
      'CUSTOMIZE': 'Tùy biến',
      'EXTENSION': 'Tiện ích',
      'VIETNAMESE': 'Tiếng Việt',
      'SYSTEM': 'Hệ thống',
      'SELFHOST': 'Tự lưu trữ',
      'GAME': 'Trò chơi',
      'LEARNING': 'Học tập',
      'OTHER': 'Khác',
    };
    const englishTypeLabels = {
      'APP': 'Apps',
      'TOOL': 'Tools',
      'LIBRARY': 'Libraries',
      'DISTRO': 'Distributions',
      'CUSTOMIZE': 'Customization',
      'EXTENSION': 'Extensions',
      'VIETNAMESE': 'Vietnamese',
      'SYSTEM': 'System',
      'SELFHOST': 'Self-hosted',
      'GAME': 'Games',
      'LEARNING': 'Learning',
      'OTHER': 'Other',
    };
    const englishSortLabels = {
      'featured': 'Featured',
      'new': 'Newest',
      'stars': 'Most stars',
      'rating': 'Rating',
      'updated': 'Recently updated',
      'trending': 'Trending',
    };
    const sortLabels = {
      'featured': 'Nổi bật',
      'new': 'Mới nhất',
      'stars': 'Nhiều sao',
      'rating': 'Đánh giá',
      'updated': 'Cập nhật',
      'trending': 'Đang lên',
    };
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await controller.load(refresh: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (MediaQuery.sizeOf(context).width > 840) ...[
            VnlfCenterPageHeader(
              title: english ? 'Projects' : 'Dự án',
              trailing: OutlinedButton.icon(
                onPressed: () {
                  final session =
                      ref.read(sessionStateProvider) ??
                      ref.read(sessionProvider).valueOrNull;
                  GoRouter.maybeOf(context)
                      ?.push(session == null ? '/login' : '/projects/submit');
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(english ? 'Submit project' : 'Giới thiệu dự án'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            maxLength: 80,
            onChanged: controller.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                key: const ValueKey('submit-project-mobile-button'),
                tooltip: english ? 'Submit project' : 'Giới thiệu dự án',
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: colors.brand,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final session =
                      ref.read(sessionStateProvider) ??
                      ref.read(sessionProvider).valueOrNull;
                  GoRouter.maybeOf(context)
                      ?.push(session == null ? '/login' : '/projects/submit');
                },
              ),
              labelText: english ? 'Search projects' : 'Tìm dự án',
              counterText: '',
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(240.0, constraints.maxWidth);
              return Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: width,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: filters.sort,
                      items: [
                        for (final sort in projectSorts)
                          DropdownMenuItem(
                            value: sort,
                            child: Text(
                              (english ? englishSortLabels : sortLabels)[sort]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.setFilters(filters.copyWith(sort: value));
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: filters.language,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(
                            english ? 'All languages' : 'Tất cả ngôn ngữ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final facet in directory.languages)
                          if (facet.name.isNotEmpty)
                            DropdownMenuItem(
                              value: facet.name,
                              child: Text(
                                '${facet.name} (${facet.count})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        if (filters.language.isNotEmpty &&
                            !directory.languages.any(
                              (f) => f.name == filters.language,
                            ))
                          DropdownMenuItem(
                            value: filters.language,
                            child: Text(
                              filters.language,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.setFilters(
                            filters.copyWith(language: value),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: math.min(300.0, constraints.maxWidth),
                    child: Row(
                      children: [
                        Checkbox(
                          value: filters.seeking,
                          onChanged: (value) => controller.setFilters(
                            filters.copyWith(seeking: value ?? false),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            english
                                ? 'Seeking contributors'
                                : 'Tìm người đóng góp',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selectedColor: colors.brandSoft,
                checkmarkColor: colors.brand,
                side: BorderSide(color: colors.line),
                labelStyle: VnlfTypography.control(colors.ink),
                label: Text(english ? 'All' : 'Tất cả'),
                selected: filters.type.isEmpty,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  controller.setFilters(filters.copyWith(type: ''));
                },
              ),
              for (final type in projectTypes)
                if (directory.types.any((f) => f.name == type) ||
                    filters.type == type)
                  ChoiceChip(
                    selectedColor: colors.brandSoft,
                    checkmarkColor: colors.brand,
                    side: BorderSide(color: colors.line),
                    labelStyle: VnlfTypography.control(colors.ink),
                    label: Text(
                      '${(english ? englishTypeLabels : typeLabels)[type]} (${directory.types.where((f) => f.name == type).fold<int>(0, (n, f) => n + f.count)})',
                    ),
                    selected: filters.type == type,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      controller.setFilters(
                        filters.copyWith(
                          type: filters.type == type ? '' : type,
                        ),
                      );
                    },
                  ),
            ],
          ),
          const SizedBox(height: 12),
          if (directory.loading && directory.items.isEmpty)
            const Center(child: CircularProgressIndicator()),
          if (!directory.loading &&
              directory.items.isEmpty &&
              directory.error == null)
            VnlfStateCard(
              icon: Icons.workspaces_outline,
              title: english
                  ? 'No matching projects'
                  : 'Không có dự án phù hợp',
              message: english ? 'Try another filter.' : 'Thử bộ lọc khác.',
            ),
          for (var index = 0; index < directory.items.length; index++) ...[
            if (filters.sort == 'featured' &&
                (index == 0 ||
                    directory.items[index - 1].tier !=
                        directory.items[index].tier))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(switch (directory.items[index].tier) {
                  'VNLF' => 'VNLF',
                  'PARTNER' => english ? 'Partners' : 'Đối tác',
                  _ => english ? 'Community' : 'Cộng đồng',
                }, style: Theme.of(context).textTheme.titleMedium),
              ),
            Builder(
              builder: (context) {
                final item = directory.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusMd,
                    ),
                    onTap: () {
                      if (item.slug.isEmpty) {
                        showProjectDetailSheet(context, item);
                      } else {
                        context.push(
                          '/projects/${Uri.encodeComponent(item.slug)}',
                        );
                      }
                    },
                    child: VnlfProjectPreviewCard(
                      project: ProjectShowcaseData(
                        id: item.id,
                        name: item.name,
                        description: item.tagline,
                        primaryLanguage:
                            item.repo?['language'] as String? ?? '',
                        tag: item.type,
                        stars: (item.repo?['stars'] as num?)?.toInt() ?? 0,
                        forks: (item.repo?['forks'] as num?)?.toInt() ?? 0,
                        rating:
                            (item.rating?['average'] as num?)?.toDouble() ?? 0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          if (directory.error != null)
            VnlfStateCard(
              icon: Icons.error_outline,
              title: english
                  ? 'Unable to load projects'
                  : 'Không tải được dự án',
              message: english ? 'Please try again.' : 'Vui lòng thử lại.',
              actionLabel: english ? 'Retry' : 'Thử lại',
              onAction: () => controller.load(
                more:
                    directory.items.isNotEmpty && directory.nextCursor != null,
                refresh: true,
              ),
            ),
          if (directory.nextCursor != null && directory.error == null)
            OutlinedButton(
              onPressed: directory.loading
                  ? null
                  : () => controller.load(more: true),
              child: Text(
                directory.loading
                    ? (english ? 'Loading…' : 'Đang tải…')
                    : (english ? 'Show more' : 'Xem thêm'),
              ),
            ),
        ],
      ),
    );
  }
}
