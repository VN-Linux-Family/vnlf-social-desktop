import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../data/local_notification_service.dart';
import '../data/push_registration.dart';
import '../domain/push_distributor.dart';
import '../domain/push_subscriptions_repository.dart';
import 'push_message_presenter.dart';
import 'push_providers.dart';

/// What the website's `PushSettings` card tracks.
final class PushSettingsState {
  const PushSettingsState({
    this.supported = true,
    this.loading = true,
    this.loadFailed = false,
    this.config,
    this.enabled = false,
    this.busy = false,
    this.status,
  });

  /// False where the device has no push service.
  final bool supported;
  final bool loading;
  final bool loadFailed;
  final PushServerConfig? config;

  /// On only when this device's subscription is registered for this login
  /// session and was made with the server's current key.
  final bool enabled;
  final bool busy;

  /// The last result, shown under the buttons.
  final String? status;

  bool get canToggle =>
      supported &&
      !busy &&
      !loading &&
      !loadFailed &&
      (enabled || (config?.enabled ?? false));

  PushSettingsState settled({required bool enabled, String? status}) =>
      PushSettingsState(
        loading: false,
        config: config,
        enabled: enabled,
        status: status,
      );
}

final pushSettingsProvider =
    NotifierProvider.autoDispose<PushSettingsController, PushSettingsState>(
      PushSettingsController.new,
    );

/// Loads, turns on and off, and tests this device's push notifications the
/// way `push-settings.tsx` does. Writes are never retried: a failure shows
/// and the member can press again.
class PushSettingsController extends AutoDisposeNotifier<PushSettingsState> {
  int _generation = 0;

  @override
  PushSettingsState build() {
    ref.watch(sessionStateProvider.select((session) => session?.userId));
    final registration = ref.watch(pushRegistrationProvider);
    final generation = ++_generation;
    if (registration == null) {
      return const PushSettingsState(supported: false, loading: false);
    }
    unawaited(_load(generation));
    return const PushSettingsState();
  }

  Future<void> _load(int generation) async {
    final registration = ref.read(pushRegistrationProvider);
    if (registration == null) return;
    try {
      final loaded = await registration.load();
      if (generation != _generation) return;
      state = PushSettingsState(
        loading: false,
        config: loaded.config,
        enabled: loaded.enabled,
      );
    } on Object {
      if (generation != _generation) return;
      state = const PushSettingsState(loading: false, loadFailed: true);
    }
  }

  Future<void> toggle() => state.enabled ? _disable() : _enable();

  Future<void> _enable() async {
    final registration = ref.read(pushRegistrationProvider);
    final config = state.config;
    if (registration == null || config == null || !state.canToggle) return;
    final generation = _generation;
    final before = state;
    state = PushSettingsState(
      loading: false,
      config: config,
      enabled: before.enabled,
      busy: true,
    );
    final (enabled, status) = await _turnOn(registration, config);
    if (generation != _generation) return;
    state = before.settled(enabled: enabled, status: status);
  }

  /// Asks for permission, then registers; the result and what to say.
  Future<(bool, String)> _turnOn(
    PushRegistration registration,
    PushServerConfig config,
  ) async {
    if (!await ref.read(localNotificationServiceProvider).requestPermission()) {
      return (false, vi.app.chuaDuocPhepGuiThongBao);
    }
    try {
      await registration.enable(config);
      return (true, vi.app.notifications.daBatDay);
    } on PushDistributorUnavailable {
      return (false, vi.app.notifications.chuaCoUngDungNhanDay);
    } on PushRegistrationRefused {
      return (false, vi.app.notifications.ungDungNhanDayTuChoi);
    } on HttpFailure catch (failure) {
      return (
        false,
        switch (failure.code) {
          // Until the server accepts distributor endpoints
          // (docs/contracts/native-push.md).
          'PUSH_ENDPOINT_INVALID' =>
            vi.app.notifications.mayChuChuaNhanUnifiedPush,
          'PUSH_DEVICE_LIMIT' => vi.api.push.daDatGioiHan10,
          _ => vi.pushSettings.chuaBatDuocThongBao,
        },
      );
    } on Object {
      return (false, vi.pushSettings.chuaBatDuocThongBao);
    }
  }

  Future<void> _disable() async {
    final registration = ref.read(pushRegistrationProvider);
    if (registration == null || !state.canToggle) return;
    final generation = _generation;
    final before = state;
    state = PushSettingsState(
      loading: false,
      config: before.config,
      enabled: true,
      busy: true,
    );
    try {
      await registration.disable();
      if (generation != _generation) return;
      state = before.settled(
        enabled: false,
        status: vi.pushSettings.thongBaoThietBiDa,
      );
    } on Object {
      if (generation != _generation) return;
      state = before.settled(
        enabled: true,
        status: vi.pushSettings.chuaTatDuocThongBao,
      );
    }
  }

  /// "Gửi thông báo thử": a local notification, not one from the server.
  Future<void> test() async {
    if (!state.enabled || state.busy) return;
    final shown = await ref
        .read(localNotificationServiceProvider)
        .showNotification(
          id: pushNotificationId(
            'vnlf-test-${DateTime.now().millisecondsSinceEpoch}',
          ),
          title: vi.app.notifications.tieuDeThongBaoDay,
          body: vi.pushSettings.dayLaThongBaoThu,
        );
    state = state.settled(
      enabled: state.enabled,
      status: shown
          ? vi.app.notifications.daGuiThongBaoThu
          : vi.app.notifications.chuaHienThongBaoThu,
    );
  }
}
