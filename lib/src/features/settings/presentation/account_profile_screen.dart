import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utf16_length_formatter.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../domain/account_profile.dart';
import 'account_profile_controller.dart';
import 'account_profile_messages.dart';

class AccountProfileScreen extends ConsumerWidget {
  const AccountProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountProfileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(vi.common.chinhSuaHoSo)),
      body: SafeArea(
        child: switch (state) {
          AccountProfileLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          AccountProfileLoadFailed(:final failure) => _LoadError(
            message: profileFailureMessage(failure),
            onRetry: ref.read(accountProfileControllerProvider.notifier).load,
          ),
          AccountProfileEditing() => _ProfileForm(state: state),
        },
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(vi.common.thuLai)),
        ],
      ),
    ),
  );
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.state});
  final AccountProfileEditing state;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  static const _limits = {
    ProfileField.username: 30,
    ProfileField.displayName: 80,
    ProfileField.bio: 160,
    ProfileField.website: 500,
  };
  late final Map<ProfileField, TextEditingController> _controllers = {
    for (final field in ProfileField.values)
      field: TextEditingController(text: widget.state.profile.valueOf(field)),
  };
  AccountProfile? _synced;

  @override
  void initState() {
    super.initState();
    _synced = widget.state.profile;
  }

  @override
  void didUpdateWidget(_ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final profile = widget.state.profile;
    if (profile != _synced) {
      _synced = profile;
      for (final field in ProfileField.values) {
        _controllers[field]!.text = profile.valueOf(field);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AccountProfile get _draft => AccountProfile(
    username: _controllers[ProfileField.username]!.text,
    displayName: _controllers[ProfileField.displayName]!.text,
    bio: _controllers[ProfileField.bio]!.text,
    website: _controllers[ProfileField.website]!.text,
  );

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final state = widget.state;
    final controller = ref.read(accountProfileControllerProvider.notifier);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final field in ProfileField.values) ...[
              TextField(
                controller: _controllers[field],
                enabled: !state.saving,
                maxLines: field == ProfileField.bio ? 3 : 1,
                keyboardType: field == ProfileField.website
                    ? TextInputType.url
                    : TextInputType.text,
                autocorrect:
                    field != ProfileField.username &&
                    field != ProfileField.website,
                inputFormatters: [Utf16LengthFormatter(_limits[field]!)],
                decoration: InputDecoration(
                  labelText: profileFieldLabel(field),
                  prefixText: field == ProfileField.username ? '@' : null,
                  helperText: field == ProfileField.username
                      ? vi.app.settings.tenCuDuocGiu
                      : null,
                  errorText: state.errors[field] == null
                      ? null
                      : profileFieldError(field, state.errors[field]!),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (state.failure != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  profileFailureMessage(state.failure!),
                  style: VnlfTypography.meta(colors.red),
                ),
              ),
            if (state.saved)
              Semantics(
                liveRegion: true,
                child: Text(
                  vi.app.settings.daLuuHoSo,
                  style: VnlfTypography.meta(colors.brand),
                ),
              ),
            const SizedBox(height: 12),
            if (state.outcomeUnknown)
              OutlinedButton(
                onPressed: state.saving
                    ? null
                    : controller.verifyAfterUncertainWrite,
                child: Text(vi.app.settings.kiemTraDuLieu),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: state.saving
                    ? null
                    : () => controller.submit(_draft),
                child: Text(state.saving ? vi.common.dangLuu : vi.common.luu),
              ),
          ],
        ),
      ),
    );
  }
}
