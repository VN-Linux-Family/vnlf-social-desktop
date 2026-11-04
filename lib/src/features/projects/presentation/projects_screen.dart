import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';

final projectsProvider = FutureProvider<ProjectsPage>(
  (ref) => ref.watch(projectsRepositoryProvider).getProjects(),
);

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final projects = ref.watch(projectsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VnlfCenterPageHeader(title: english ? 'Projects' : 'Dự án'),
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
            data: (page) => page.items.isEmpty
                ? ListView(
                    children: [
                      VnlfStateCard(
                        icon: Icons.workspaces_outline,
                        title: english ? 'No projects yet' : 'Chưa có dự án',
                        message: english
                            ? 'Community projects will appear here.'
                            : 'Dự án của cộng đồng sẽ xuất hiện tại đây.',
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: page.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = page.items[index];
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
                  ),
          ),
        ),
      ],
    );
  }
}
