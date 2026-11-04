import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final projects = ref.watch(projectsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VnlfCenterPageHeader(title: english ? 'Projects' : 'Dự án'),
        const SizedBox(height: 12),
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
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return VnlfProjectPreviewCard(
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
                                (item.rating?['average'] as num?)?.toDouble() ??
                                0,
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
