import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_widgets.dart';

class ProfileWardrobe extends StatelessWidget {
  const ProfileWardrobe({super.key, required this.author});

  final Author author;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final style = author.style;
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            english ? 'Wardrobe & Badges' : 'Tủ đồ & Huy hiệu',
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 16),
          VnlfAvatar(author: presentAuthor(author), size: 64),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.account_circle_outlined,
              color: presentAuthor(author).style.frameColor ?? colors.muted,
            ),
            title: Text(english ? 'Avatar frame' : 'Khung ảnh đại diện'),
            subtitle: Text(
              style?.frame?['id'] as String? ??
                  (english ? 'Default' : 'Mặc định'),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.verified_outlined),
            title: Text(
              english ? 'Distribution badge' : 'Huy hiệu bản phân phối',
            ),
            subtitle: Text(
              style?.distroBadge ?? (english ? 'None' : 'Chưa có'),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.badge_outlined),
            title: Text(english ? 'Nameplate' : 'Bảng tên'),
            subtitle: Text(
              style?.nameplate?['id'] as String? ??
                  (english ? 'Default' : 'Mặc định'),
            ),
          ),
        ],
      ),
    );
  }
}
