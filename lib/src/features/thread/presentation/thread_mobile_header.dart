import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';

class ThreadMobileHeader extends StatelessWidget {
  const ThreadMobileHeader({
    super.key,
    required this.onCompose,
    required this.onSearch,
    required this.onNotifications,
  });
  final VoidCallback onCompose;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              vi.common.baiViet,
              style: VnlfTypography.pageTitle(colors.ink),
            ),
          ),
          IconButton(
            tooltip: vi.socialChrome.taoBaiViet,
            onPressed: onCompose,
            icon: const Icon(Icons.add_box_outlined, size: 20),
          ),
          IconButton(
            tooltip: vi.common.timKiem,
            onPressed: onSearch,
            icon: const Icon(Icons.search, size: 22),
          ),
          IconButton(
            tooltip: vi.common.thongBao,
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_outlined, size: 22),
          ),
        ],
      ),
    );
  }
}
