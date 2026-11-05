import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';

final projectsProvider = FutureProvider<ProjectsPage>(
  (ref) => ref.watch(projectsRepositoryProvider).getProjects(),
);

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String? _language;

  void _showProjectDetail(BuildContext context, ProjectItem item) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final repoUrl = item.repo?['url'] as String?;
    final repoOwner = item.repo?['owner'] as String?;
    final repoName = item.repo?['name'] as String?;
    final String repoFullName = (repoOwner != null && repoName != null)
        ? '$repoOwner/$repoName'
        : item.name;
    final stars = (item.repo?['stars'] as num?)?.toInt() ?? 0;
    final forks = (item.repo?['forks'] as num?)?.toInt() ?? 0;
    final language = item.repo?['language'] as String? ?? '';
    final rating = (item.rating?['average'] as num?)?.toDouble() ?? 0;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VnlfDimensions.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.brandSoft,
                      borderRadius: BorderRadius.circular(
                        VnlfDimensions.radiusMd,
                      ),
                    ),
                    child: Icon(
                      Icons.folder_special_rounded,
                      color: colors.brand,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: VnlfTypography.h2(colors.ink)),
                        if (repoFullName.isNotEmpty)
                          Text(
                            repoFullName,
                            style: VnlfTypography.meta(colors.muted),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item.tagline as String? ?? '',
                style: VnlfTypography.body(colors.ink),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                  border: Border.all(color: colors.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      icon: Icons.star_rounded,
                      iconColor: colors.amber,
                      label: english ? 'Stars' : 'Sao',
                      value: '$stars',
                      colors: colors,
                    ),
                    _StatColumn(
                      icon: Icons.alt_route_rounded,
                      iconColor: colors.brand,
                      label: english ? 'Forks' : 'Forks',
                      value: '$forks',
                      colors: colors,
                    ),
                    if (language.isNotEmpty)
                      _StatColumn(
                        icon: Icons.code_rounded,
                        iconColor: colors.ink,
                        label: english ? 'Language' : 'Ngôn ngữ',
                        value: language,
                        colors: colors,
                      ),
                    if (rating > 0)
                      _StatColumn(
                        icon: Icons.recommend_rounded,
                        iconColor: colors.brand,
                        label: english ? 'Rating' : 'Đánh giá',
                        value: rating.toStringAsFixed(1),
                        colors: colors,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (repoUrl != null && repoUrl.isNotEmpty)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        VnlfDimensions.radiusMd,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    english ? 'Open Repository' : 'Mở kho mã nguồn (GitHub)',
                    style: VnlfTypography.control(
                      Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.tryParse(repoUrl);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final projects = ref.watch(projectsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width > 840;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop) ...[
          VnlfCenterPageHeader(title: english ? 'Projects' : 'Dự án'),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final language in <String?>[
              null,
              'Dart',
              'Rust',
              'Python',
              'Go',
              'C++',
              'Shell',
            ])
              ChoiceChip(
                selectedColor: colors.brandSoft,
                backgroundColor: colors.surface,
                checkmarkColor: colors.brand,
                side: BorderSide(color: colors.line),
                labelStyle: VnlfTypography.control(colors.ink),
                label: Text(language ?? (english ? 'All' : 'Tất cả')),
                selected: _language == language,
                onSelected: (_) => setState(() => _language = language),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: projects.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => ListView(
              padding: EdgeInsets.zero,
              children: [
                VnlfStateCard(
                  icon: Icons.error_outline,
                  title: english
                      ? 'Unable to load projects'
                      : 'Không tải được dự án',
                  message: english ? 'Please try again.' : 'Vui lòng thử lại.',
                  actionLabel: english ? 'Retry' : 'Thử lại',
                  onAction: () => ref.invalidate(projectsProvider),
                ),
              ],
            ),
            data: (page) {
              final items = page.items
                  .where(
                    (item) =>
                        _language == null ||
                        item.repo?['language'] == _language,
                  )
                  .toList();
              return items.isEmpty
                  ? ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        VnlfStateCard(
                          icon: Icons.workspaces_outline,
                          title: _language != null
                              ? (english
                                    ? 'No matching projects'
                                    : 'Không có dự án phù hợp')
                              : (english ? 'No projects yet' : 'Chưa có dự án'),
                          message: _language != null
                              ? (english
                                    ? 'Choose another language or show all projects.'
                                    : 'Chọn ngôn ngữ khác hoặc xem tất cả dự án.')
                              : english
                              ? 'Community projects will appear here.'
                              : 'Dự án của cộng đồng sẽ xuất hiện tại đây.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusMd,
                          ),
                          onTap: () => _showProjectDetail(context, item),
                          child: VnlfProjectPreviewCard(
                            project: ProjectShowcaseData(
                              id: item.id,
                              name: item.name,
                              description: item.tagline,
                              primaryLanguage:
                                  item.repo?['language'] as String? ?? '',
                              tag: item.type,
                              stars:
                                  (item.repo?['stars'] as num?)?.toInt() ?? 0,
                              forks:
                                  (item.repo?['forks'] as num?)?.toInt() ?? 0,
                              rating:
                                  (item.rating?['average'] as num?)
                                      ?.toDouble() ??
                                  0,
                            ),
                          ),
                        );
                      },
                    );
            },
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VnlfColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: VnlfTypography.control(
                colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: VnlfTypography.caption(colors.muted)),
      ],
    );
  }
}
