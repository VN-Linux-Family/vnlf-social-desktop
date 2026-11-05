import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/io_api_transport.dart';
import '../core/preferences_storage.dart';
import '../core/session_storage.dart';
import '../data/fixture_repositories.dart';
import '../data/live_auth_repository.dart';
import '../data/live_post_repository.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

/// Null follows the system locale; set a locale to override it for this session.
final localeProvider = StateProvider<Locale?>((ref) => null);

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => const SecureSessionStorage(),
);

final sessionStorageFailureProvider = StateProvider<StorageFailure?>(
  (ref) => null,
);

final preferencesStorageProvider = Provider<PreferencesStorage>(
  (ref) => SharedPreferencesStorage(),
);

final themeStorageFailureProvider = StateProvider<StorageFailure?>(
  (ref) => null,
);

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) =>
      ThemeModeController(ref.watch(preferencesStorageProvider), (failure) {
        ref.read(themeStorageFailureProvider.notifier).state = failure;
      }),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._storage, this._onStorageFailure)
    : super(ThemeMode.system) {
    restored = _restore();
  }

  static const _storageKey = 'vnlf_theme_mode';
  final PreferencesStorage _storage;
  final void Function(StorageFailure?) _onStorageFailure;
  late final Future<void> restored;
  Future<void> _writes = Future.value();
  int _revision = 0;

  Future<void> _restore() async {
    final revision = _revision;
    try {
      final value = await _storage.read(_storageKey);
      if (!mounted || revision != _revision) return;
      state = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      if (mounted && revision == _revision) {
        _onStorageFailure(const StorageFailure());
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    final revision = ++_revision;
    state = mode;
    return _writes = _writes.then((_) async {
      try {
        await _storage.write(_storageKey, mode.name);
        if (mounted && revision == _revision) _onStorageFailure(null);
      } catch (_) {
        if (mounted && revision == _revision) {
          _onStorageFailure(const StorageFailure());
        }
      }
    });
  }
}

bool _isLiveDefault() {
  if (const bool.hasEnvironment('VNLF_LIVE')) {
    return const bool.fromEnvironment('VNLF_LIVE');
  }
  try {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
  } catch (_) {}
  return true;
}

/// Opt-in live HTTP transport with session cookie persistence.
final ioTransportProvider = Provider<IoApiTransport?>((ref) {
  if (!_isLiveDefault()) return null;
  final uri = Uri.parse('https://vietnamlinuxfamily.net');
  final storage = ref.watch(sessionStorageProvider);
  final transport = IoApiTransport(
    uri,
    storage: storage,
    onStorageFailure: (failure) {
      ref.read(sessionStorageFailureProvider.notifier).state = failure;
    },
  );
  ref.onDispose(transport.close);
  return transport;
});

/// Live requests to vietnamlinuxfamily.net are enabled by default for app execution.
final apiClientProvider = Provider<ApiClient>((ref) {
  final transport = ref.watch(ioTransportProvider);
  if (transport == null) {
    return ApiClient(
      transport: fixtureTransport,
      throttleInterval: Duration.zero,
      // A fixture client owns its queue, including the widget test clock.
      hostKey: Object(),
    );
  }
  return ApiClient(transport: transport.call);
});

final sessionStateProvider = StateProvider<Session?>((ref) => null);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!_isLiveDefault()) {
    return const FixtureAuthRepository();
  }
  final transport = ref.watch(ioTransportProvider);
  return LiveAuthRepository(
    ref.watch(apiClientProvider),
    onLogout: transport?.clearCookies,
  );
});

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FixtureFeedRepository(ref.watch(apiClientProvider)),
);
final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => const FixtureCommunityRepository(),
);
final channelsRepositoryProvider = Provider<ChannelsRepository>(
  (ref) => const FixtureCommunityRepository(),
);
final postRepositoryProvider = Provider<PostRepository>((ref) {
  final fallback = FixturePostRepository(ref.watch(feedRepositoryProvider));
  if (!_isLiveDefault()) return fallback;
  return LivePostRepository(ref.watch(apiClientProvider), fallback);
});
final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => FixtureDiscoverRepository(ref.watch(apiClientProvider)),
);
final leaderboardsRepositoryProvider = Provider<LeaderboardsRepository>(
  (ref) => FixtureLeaderboardsRepository(ref.watch(apiClientProvider)),
);

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => FixtureLeaderboardRepository(ref.watch(apiClientProvider)),
);
final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => FixtureProjectsRepository(ref.watch(apiClientProvider)),
);

class AuthController extends StateNotifier<AsyncValue<Session?>> {
  AuthController(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    unawaited(refreshSession());
  }

  final AuthRepository _repository;
  final Ref _ref;
  int _revision = 0;

  void _setSession(Session? session) {
    _ref.read(sessionStateProvider.notifier).state = session;
    state = AsyncValue.data(session);
  }

  Future<void> refreshSession() async {
    final revision = ++_revision;
    state = const AsyncValue.loading();
    try {
      final session = await _repository.currentSession();
      if (mounted && revision == _revision) _setSession(session);
    } catch (e, st) {
      if (mounted && revision == _revision) state = AsyncValue.error(e, st);
    }
  }

  Future<Session> login(String login, String password) async {
    final revision = ++_revision;
    state = const AsyncValue.loading();
    try {
      final session = await _repository.login(login, password);
      if (mounted && revision == _revision) _setSession(session);
      return session;
    } catch (e, st) {
      if (mounted && revision == _revision) state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Session> register(
    String email,
    String username,
    String password,
  ) async {
    final revision = ++_revision;
    state = const AsyncValue.loading();
    try {
      final session = await _repository.register(email, username, password);
      if (mounted && revision == _revision) _setSession(session);
      return session;
    } catch (e, st) {
      if (mounted && revision == _revision) state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    final revision = ++_revision;
    state = const AsyncValue.loading();
    try {
      await _repository.logout();
    } finally {
      if (mounted && revision == _revision) _setSession(null);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<Session?>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider), ref);
    });

final sessionProvider = Provider<AsyncValue<Session?>>(
  (ref) => ref.watch(authControllerProvider),
);
final feedProvider = FutureProvider.family<FeedPage, String?>(
  (ref, cursor) => ref.watch(feedRepositoryProvider).getFeed(cursor: cursor),
);
final communityChannelsProvider = FutureProvider<List<CommunityChannel>>(
  (ref) => ref.watch(communityRepositoryProvider).getChannels(),
);
