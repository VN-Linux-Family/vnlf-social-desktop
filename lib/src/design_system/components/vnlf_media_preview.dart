import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Renders an authentic Debian 13 + XFCE desktop & terminal neofetch preview
/// matching Post 1 in `reference_feed_desktop.png` with zero network calls.
class VnlfLinuxDesktopPreview extends StatelessWidget {
  const VnlfLinuxDesktopPreview({super.key, required this.attachment});

  final LinuxDesktopAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        final previewHeight = isCompact ? 236.0 : 326.0;

        return Container(
          width: double.infinity,
          height: previewHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF282D33),
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            border: Border.all(color: colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: Stack(
              children: [
                // Subtle dark Debian wallpaper gradient
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2D3339),
                          Color(0xFF23282D),
                          Color(0xFF1E2227),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Debian 13 watermark header & right power buttons
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '🌀 ${attachment.distroHeader}',
                      style: const TextStyle(
                        fontFamily: VnlfTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF566573),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _DesktopShortcutIcon(
                        icon: Icons.power_settings_new_rounded,
                        color: Color(0xFFEA580C),
                        label: 'Tắt Máy',
                      ),
                      SizedBox(width: 10),
                      _DesktopShortcutIcon(
                        icon: Icons.restart_alt_rounded,
                        color: Color(0xFF16A34A),
                        label: 'Khởi Động Lại',
                      ),
                    ],
                  ),
                ),

                // Left desktop icon grid
                Positioned(
                  top: 10,
                  left: 10,
                  bottom: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _DesktopShortcutIcon(
                            icon: Icons.computer_rounded,
                            color: Color(0xFF38BDF8),
                            label: 'This PC',
                          ),
                          _DesktopShortcutIcon(
                            icon: Icons.delete_outline_rounded,
                            color: Color(0xFF4ADE80),
                            label: 'Trash',
                          ),
                          _DesktopShortcutIcon(
                            icon: Icons.table_chart_rounded,
                            color: Color(0xFF22C55E),
                            label: 'LibreOffice\nCalc',
                          ),
                          _DesktopShortcutIcon(
                            icon: Icons.description_rounded,
                            color: Color(0xFF3B82F6),
                            label: 'LibreOffice\nWriter',
                          ),
                          _DesktopShortcutIcon(
                            icon: Icons.public_rounded,
                            color: Color(0xFF60A5FA),
                            label: 'Google\nChrome',
                          ),
                          _DesktopShortcutIcon(
                            icon: Icons.chat_bubble_rounded,
                            color: Color(0xFF0284C7),
                            label: 'Zalo',
                          ),
                        ],
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 10),
                        Column(
                          children: const [
                            _DesktopShortcutIcon(
                              icon: Icons.keyboard_alt_rounded,
                              color: Color(0xFFEAB308),
                              label: 'Fcitx 5',
                            ),
                            SizedBox(height: 12),
                            _DesktopShortcutIcon(
                              icon: Icons.settings_applications_rounded,
                              color: Color(0xFF94A3B8),
                              label: 'Fcitx5-Lotek\nSettings',
                            ),
                            SizedBox(height: 12),
                            _DesktopShortcutIcon(
                              icon: Icons.folder_rounded,
                              color: Color(0xFFFBBF24),
                              label: 'HKD',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Center XFCE Terminal Window
                Positioned(
                  top: 36,
                  left: isCompact ? 54 : 96,
                  right: 8,
                  bottom: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // XFCE Window Titlebar
                        Container(
                          height: 15,
                          color: const Color(0xFFE2E8F0),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.terminal_rounded,
                                size: 10,
                                color: Color(0xFF334155),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    attachment.terminalTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: VnlfTypography.fontFamily,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                '—  □  ×',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Menu bar
                        Container(
                          height: 12,
                          color: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'File   Edit   View   Terminal   Tabs   Help',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 6.5,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        // Black terminal content with ASCII swirl + system specs
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ASCII Debian swirl
                                SizedBox(
                                  width: isCompact ? 62 : 94,
                                  child: Text(
                                    '       _,met\$\$\$\$\$gg.\n'
                                    '    ,g\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$P.\n'
                                    '  ,g\$\$P"        """Y\$\$.\n'
                                    ' ,\$\$P\'              `\$\$\$.\n'
                                    ',\$\$P       ,ggs.     `\$\$b:\n'
                                    '`d\$\$'
                                    '     ,\$P"\'   .    \$\$\$\n'
                                    ' \$\$P      d\$\'     ,    \$\$P\n'
                                    ' \$\$:      \$\$.   -    ,d\$\$\'\n'
                                    ' \$\$;      Y\$b._   _,d\$P\'\n'
                                    ' Y\$\$.    `.`"Y\$\$\$\$P"\'\n'
                                    ' `\$\$b      "-.__\n'
                                    '  `Y\$\$b\n'
                                    '   `Y\$\$.\n'
                                    '     `\$\$b.\n'
                                    '       `Y\$\$b.\n'
                                    '          `"Y\$b._',
                                    style: TextStyle(
                                      fontFamily: VnlfTypography.monoFontFamily,
                                      fontSize: isCompact ? 4.8 : 6.4,
                                      height: 1.12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // System Specs Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attachment.userHost,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily:
                                              VnlfTypography.monoFontFamily,
                                          fontSize: 6.8,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFF87171),
                                        ),
                                      ),
                                      const Text(
                                        '-------------',
                                        style: TextStyle(
                                          fontFamily:
                                              VnlfTypography.monoFontFamily,
                                          fontSize: 6.2,
                                          height: 1.0,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      _NeofetchLine('OS', attachment.osLine),
                                      _NeofetchLine(
                                        'Kernel',
                                        attachment.kernelLine,
                                      ),
                                      _NeofetchLine(
                                        'Uptime',
                                        attachment.uptimeLine,
                                      ),
                                      _NeofetchLine(
                                        'Packages',
                                        attachment.packagesLine,
                                      ),
                                      _NeofetchLine(
                                        'Shell',
                                        attachment.shellLine,
                                      ),
                                      _NeofetchLine('DE', attachment.deLine),
                                      _NeofetchLine('WM', attachment.wmLine),
                                      _NeofetchLine('CPU', attachment.cpuLine),
                                      _NeofetchLine(
                                        'Memory',
                                        attachment.memoryLine,
                                      ),
                                      const Spacer(),
                                      // ANSI Color Blocks
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 72,
                                        ),
                                        child: Row(
                                          children: const [
                                            Expanded(
                                              child: _AnsiBlock(
                                                Color(0xFF1E293B),
                                              ),
                                            ),
                                            Expanded(
                                              child: _AnsiBlock(
                                                Color(0xFFEF4444),
                                              ),
                                            ),
                                            Expanded(
                                              child: _AnsiBlock(
                                                Color(0xFF22C55E),
                                              ),
                                            ),
                                            Expanded(
                                              child: _AnsiBlock(
                                                Color(0xFFEAB308),
                                              ),
                                            ),
                                            Expanded(
                                              child: _AnsiBlock(
                                                Color(0xFF3B82F6),
                                              ),
                                            ),
                                            Expanded(
                                              child: _AnsiBlock(
                                                Color(0xFFA855F7),
                                              ),
                                            ),
                                            Expanded(
                                              child: _AnsiBlock(
                                                Color(0xFF06B6D4),
                                              ),
                                            ),
                                            Expanded(
                                              child: _AnsiBlock(
                                                Color(0xFFF1F5F9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bottom prompt line inside terminal
                        Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 3),
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: VnlfTypography.monoFontFamily,
                                fontSize: 6.8,
                              ),
                              children: [
                                TextSpan(
                                  text: '${attachment.userHost}:~\$ ',
                                  style: const TextStyle(
                                    color: Color(0xFF4ADE80),
                                  ),
                                ),
                                const TextSpan(
                                  text: '█',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom XFCE Panel Taskbar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 18,
                  child: Container(
                    color: const Color(0xFFE2E8F0),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.album_rounded,
                          size: 11,
                          color: Color(0xFF0284C7),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.folder_copy_rounded,
                          size: 10,
                          color: Color(0xFF475569),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.terminal_rounded,
                          size: 10,
                          color: Color(0xFF1E293B),
                        ),
                        Spacer(),
                        Icon(
                          Icons.wifi_rounded,
                          size: 10,
                          color: Color(0xFF334155),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.volume_up_rounded,
                          size: 10,
                          color: Color(0xFF334155),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '13:00',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Embedded project showcase card for posts and profile showcases.
class VnlfProjectPreviewCard extends StatelessWidget {
  const VnlfProjectPreviewCard({super.key, required this.project});

  final ProjectShowcaseData project;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal_rounded, size: 16, color: colors.brand),
              const SizedBox(width: 6),
              Expanded(
                child: Text(project.name, style: VnlfTypography.h3(colors.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
                ),
                child: Text(
                  project.category,
                  style: VnlfTypography.caption(
                    colors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(project.summary, style: VnlfTypography.body(colors.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    project.language,
                    style: VnlfTypography.meta(colors.ink),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 15, color: colors.ratingStar),
                  const SizedBox(width: 3),
                  Text(
                    '${project.stars}',
                    style: VnlfTypography.meta(
                      colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_split_rounded, size: 14, color: colors.muted),
                  const SizedBox(width: 3),
                  Text(
                    '${project.forks}',
                    style: VnlfTypography.meta(colors.muted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopShortcutIcon extends StatelessWidget {
  const _DesktopShortcutIcon({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(height: 1),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: VnlfTypography.fontFamily,
            fontSize: 5.8,
            height: 1.05,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _NeofetchLine extends StatelessWidget {
  const _NeofetchLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.2),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(
            fontFamily: VnlfTypography.monoFontFamily,
            fontSize: 6.4,
            height: 1.15,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFFF87171),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Color(0xFFE2E8F0)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnsiBlock extends StatelessWidget {
  const _AnsiBlock(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 7, color: color);
  }
}
