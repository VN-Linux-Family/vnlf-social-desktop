import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';

/// One tab of the profile: its label, an optional icon and the count shown
/// muted after it once known.
typedef ProfileTab = ({String label, VnlfLucide? icon, int? count});

/// The website's `.profile-tabs`: plain labels, the chosen one bold with a
/// 2px bar in the profile's accent along the card's bottom edge.
class ProfileTabs extends StatelessWidget {
  const ProfileTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    required this.accent,
  });

  final List<ProfileTab> tabs;
  final int selected;
  final ValueChanged<int> onSelected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 841;
    return Semantics(
      container: true,
      label: vi.accountViews.noiDungHoSo,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: phone ? 6 : 20),
        child: Row(
          spacing: 23,
          children: [
            for (var index = 0; index < tabs.length; index++)
              _TabButton(
                tab: tabs[index],
                selected: index == selected,
                accent: accent,
                // Phones keep 48dp targets; the website's are 40.
                minHeight: phone ? 48 : 36,
                onTap: () => onSelected(index),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.accent,
    required this.minHeight,
    required this.onTap,
  });

  final ProfileTab tab;
  final bool selected;
  final Color accent;
  final double minHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final ink = selected ? colors.ink : colors.muted;
    final count = tab.count;
    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? tab.label : '${tab.label} $count',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(1, 10, 1, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.icon case final icon?) ...[
                    VnlfIcon(icon, size: 14, color: ink),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    tab.label,
                    style: VnlfTypography.plain(
                      ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  if (count != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Text(
                        ' $count',
                        style: VnlfTypography.plain(colors.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
