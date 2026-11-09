import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import 'project_accent.dart';

class ProjectStats extends StatelessWidget {
  const ProjectStats({super.key, required this.project, required this.accent});

  final ProjectItem project;
  final ProjectAccent accent;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final language = project.repo?['language'] as String? ?? '';
    final rating = (project.rating?['average'] as num?)?.toDouble() ?? 0;
    final iconColor = accent.onSurface(colors.surfaceSoft);
    final stats = [
      _StatColumn(
        icon: Icons.star_rounded,
        iconColor: colors.ratingStar,
        label: vi.app.projects.sao,
        value: '${(project.repo?['stars'] as num?)?.toInt() ?? 0}',
      ),
      _StatColumn(
        icon: Icons.alt_route_rounded,
        iconColor: iconColor,
        label: 'Forks',
        value: '${(project.repo?['forks'] as num?)?.toInt() ?? 0}',
      ),
      if (language.isNotEmpty)
        _StatColumn(
          icon: Icons.code_rounded,
          iconColor: colors.ink,
          label: vi.projects.ngonNgu,
          value: language,
        ),
      if (rating > 0)
        _StatColumn(
          icon: Icons.recommend_rounded,
          iconColor: iconColor,
          label: vi.projects.danhGia,
          value: rating.toStringAsFixed(1),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        border: Border.all(color: colors.line),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceAround,
        children: stats,
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: VnlfTypography.control(
                  colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: VnlfTypography.caption(colors.muted),
        ),
      ],
    );
  }
}
