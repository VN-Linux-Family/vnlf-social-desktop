import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import 'project_accent.dart';
import 'project_stats.dart';

Future<void> showProjectDetailSheet(BuildContext context, ProjectItem project) {
  final colors = VnlfColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: colors.paper,
    barrierColor: Colors.black.withValues(alpha: 0.54),
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxWidth: 640,
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(VnlfDimensions.radiusLg),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => _ProjectDetailSheet(project: project),
  );
}

class _ProjectDetailSheet extends StatelessWidget {
  const _ProjectDetailSheet({required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final accent = ProjectAccent(project.accentColor, colors);
    final repoOwner = project.repo?['owner'] as String?;
    final repoName = project.repo?['name'] as String?;
    final repoFullName = repoOwner != null && repoName != null
        ? '$repoOwner/$repoName'
        : project.name;
    final repoUrl = project.repo?['url'] as String?;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
                    color: accent.soft,
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusMd,
                    ),
                  ),
                  child: Icon(
                    Icons.folder_special_rounded,
                    color: accent.onSurface(accent.soft),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name, style: VnlfTypography.h2(colors.ink)),
                      if (repoFullName.isNotEmpty)
                        Text(
                          repoFullName,
                          style: VnlfTypography.meta(colors.muted),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: english ? 'Close' : 'Đóng',
                  color: colors.ink,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (project.tagline.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(project.tagline, style: VnlfTypography.body(colors.ink)),
            ],
            const SizedBox(height: 16),
            ProjectStats(project: project, accent: accent),
            if (repoUrl != null && repoUrl.isNotEmpty) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accent.color,
                  foregroundColor: accent.onColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusMd,
                    ),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(
                  english ? 'Open Repository' : 'Mở kho mã nguồn (GitHub)',
                  textAlign: TextAlign.center,
                  style: VnlfTypography.control(
                    accent.onColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () async {
                  final uri = Uri.tryParse(repoUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
