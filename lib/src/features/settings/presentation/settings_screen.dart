import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';

const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final theme = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final language =
        locale?.languageCode ?? Localizations.localeOf(context).languageCode;
    return ListView(
      children: [
        FeatureHeader(
          title: english ? 'Settings' : 'Cài đặt',
          showSettings: false,
        ),
        const SizedBox(height: 12),
        FeatureSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                english ? 'Appearance' : 'Giao diện',
                style: VnlfTypography.h2(colors.ink),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in ThemeMode.values)
                    ChoiceChip(
                      selectedColor: colors.brandSoft,
                      checkmarkColor: colors.brand,
                      side: BorderSide(color: colors.line),
                      labelStyle: VnlfTypography.control(colors.ink),
                      label: Text(switch (mode) {
                        ThemeMode.light => english ? 'Light' : 'Sáng',
                        ThemeMode.dark => english ? 'Dark' : 'Tối',
                        ThemeMode.system => english ? 'System' : 'Tự động',
                      }),
                      selected: theme == mode,
                      onSelected: (_) =>
                          ref.read(themeModeProvider.notifier).state = mode,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                english ? 'Language' : 'Ngôn ngữ',
                style: VnlfTypography.h2(colors.ink),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in const {
                    'vi': 'Tiếng Việt',
                    'en': 'English',
                  }.entries)
                    ChoiceChip(
                      selectedColor: colors.brandSoft,
                      checkmarkColor: colors.brand,
                      side: BorderSide(color: colors.line),
                      labelStyle: VnlfTypography.control(colors.ink),
                      label: Text(item.value),
                      selected: language == item.key,
                      onSelected: (_) =>
                          ref.read(localeProvider.notifier).state = Locale(
                            item.key,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                english ? 'About the app' : 'Thông tin ứng dụng',
                style: VnlfTypography.h2(colors.ink),
              ),
              const SizedBox(height: 12),
              Text('VNLF Flutter v$appVersion (Bản thử nghiệm cộng đồng)'),
              const SizedBox(height: 16),
              Text(
                english ? 'Server mode' : 'Chế độ máy chủ',
                style: VnlfTypography.h3(colors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                offlineFeatures
                    ? 'Offline fixture'
                    : (english
                          ? 'Live server (https://vietnamlinuxfamily.net)'
                          : 'Máy chủ trực tuyến (https://vietnamlinuxfamily.net)'),
              ),
              const SizedBox(height: 8),
              Text(
                english
                    ? 'Appearance and language apply for this app session.'
                    : 'Giao diện và ngôn ngữ áp dụng trong phiên ứng dụng này.',
                style: VnlfTypography.meta(colors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
