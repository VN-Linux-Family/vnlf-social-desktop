import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_client.dart';
import '../data/live_account_profile_repository.dart';
import '../domain/account_profile.dart';
import '../domain/account_profile_repository.dart';

sealed class AccountProfileState {
  const AccountProfileState();
}

final class AccountProfileLoading extends AccountProfileState {
  const AccountProfileLoading();
}

final class AccountProfileLoadFailed extends AccountProfileState {
  const AccountProfileLoadFailed(this.failure);
  final AppFailure failure;
}

final class AccountProfileEditing extends AccountProfileState {
  const AccountProfileEditing({
    required this.profile,
    this.errors = const {},
    this.saving = false,
    this.failure,
    this.outcomeUnknown = false,
    this.saved = false,
  });

  /// Last values known to be on the server.
  final AccountProfile profile;
  final Map<ProfileField, ProfileFieldError> errors;
  final bool saving;
  final AppFailure? failure;

  /// The write may or may not have been applied; it must not be resent blindly.
  final bool outcomeUnknown;
  final bool saved;
}

class AccountProfileController extends StateNotifier<AccountProfileState> {
  AccountProfileController(
    this._repository,
    this._username, {
    this.onSaved,
  }) : super(const AccountProfileLoading()) {
    unawaited(load());
  }

  final AccountProfileRepository _repository;
  final String _username;
  final void Function()? onSaved;
  ProfilePatch? _pending;

  Future<void> load() async {
    if (_username.isEmpty) {
      state = const AccountProfileLoadFailed(HttpFailure(401));
      return;
    }
    state = const AccountProfileLoading();
    try {
      final profile = await _repository.load(_username);
      if (mounted) state = AccountProfileEditing(profile: profile);
    } on AppFailure catch (failure) {
      if (mounted) state = AccountProfileLoadFailed(failure);
    }
  }

  /// Validates and sends one PATCH. A second call while saving is ignored.
  Future<void> submit(AccountProfile draft) async {
    final current = state;
    if (current is! AccountProfileEditing || current.saving) return;
    final check = checkProfileDraft(current.profile, draft);
    if (!check.isValid) {
      state = AccountProfileEditing(profile: current.profile, errors: check.errors);
      return;
    }
    if (check.patch.isEmpty) {
      state = AccountProfileEditing(profile: current.profile);
      return;
    }
    state = AccountProfileEditing(profile: current.profile, saving: true);
    try {
      await _repository.save(check.patch);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      final unknown = _mayHaveReachedServer(failure);
      if (unknown) _pending = check.patch;
      state = AccountProfileEditing(
        profile: current.profile,
        failure: failure,
        outcomeUnknown: unknown,
      );
      return;
    }
    if (!mounted) return;
    final applied = current.profile.apply(check.patch);
    state = AccountProfileEditing(profile: applied, saved: true);
    onSaved?.call();
    await _confirm(applied.username);
  }

  /// After an unclear write, reads the server's profile instead of resending.
  Future<void> verifyAfterUncertainWrite() async {
    final current = state;
    if (current is! AccountProfileEditing || !current.outcomeUnknown) return;
    state = AccountProfileEditing(profile: current.profile, saving: true);
    final wanted = _pending?.fields[ProfileField.username];
    final candidates = <String>[
      if (wanted != null && wanted != current.profile.username) wanted,
      current.profile.username,
    ];
    for (final name in candidates) {
      try {
        final profile = await _repository.load(name);
        if (!mounted) return;
        final applied = _pending == null
            ? false
            : checkProfileDraft(profile, current.profile.apply(_pending!))
                  .patch
                  .isEmpty;
        _pending = null;
        state = AccountProfileEditing(profile: profile, saved: applied);
        if (applied) onSaved?.call();
        return;
      } on HttpFailure catch (failure) {
        if (failure.statusCode == 404 && name != current.profile.username) {
          continue;
        }
        if (!mounted) return;
        state = AccountProfileEditing(
          profile: current.profile,
          failure: failure,
          outcomeUnknown: true,
        );
        return;
      } on AppFailure catch (failure) {
        if (!mounted) return;
        state = AccountProfileEditing(
          profile: current.profile,
          failure: failure,
          outcomeUnknown: true,
        );
        return;
      }
    }
  }

  Future<void> _confirm(String username) async {
    try {
      final fresh = await _repository.load(username);
      if (mounted) state = AccountProfileEditing(profile: fresh, saved: true);
    } on AppFailure {
      // The write was acknowledged; keep the locally applied values.
    }
  }

  bool _mayHaveReachedServer(AppFailure failure) => switch (failure) {
    TransportFailure() || ParseFailure() => true,
    HttpFailure(:final statusCode) => statusCode >= 500,
    _ => false,
  };
}

final accountProfileRepositoryProvider =
    Provider.autoDispose<AccountProfileRepository>((ref) {
      ref.watch(sessionStateProvider.select((session) => session?.userId));
      return LiveAccountProfileRepository(ref.watch(apiClientProvider));
    });

/// Rebuilt (and the old controller discarded) whenever the signed-in account
/// changes, so a late response can never land on another account's form.
final accountProfileControllerProvider =
    StateNotifierProvider.autoDispose<
      AccountProfileController,
      AccountProfileState
    >((ref) {
      ref.watch(sessionStateProvider.select((session) => session?.userId));
      final username = ref.read(sessionStateProvider)?.username ?? '';
      return AccountProfileController(
        ref.watch(accountProfileRepositoryProvider),
        username,
        onSaved: () =>
            unawaited(ref.read(authControllerProvider.notifier).refreshSession()),
      );
    });
