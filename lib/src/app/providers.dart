import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/io_api_transport.dart';
import '../core/session_storage.dart';
import '../data/fixture_repositories.dart';
import '../data/live_auth_repository.dart';
import '../data/live_post_repository.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

/// Null follows the system locale; set a locale to override it for this session.
final localeProvider = StateProvider<Locale?>((ref) => null);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => const SecureSessionStorage(),
);

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
  final transport = IoApiTransport(uri, storage: storage);
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
    onSessionChanged: (session) {
      ref.read(sessionStateProvider.notifier).state = session;
    },
    onLogout: () {
      transport?.clearCookies();
      ref.read(sessionStateProvider.notifier).state = null;
    },
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
    refreshSession();
  }

  final AuthRepository _repository;
  final Ref _ref;

  Future<void> refreshSession() async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.currentSession();
      _ref.read(sessionStateProvider.notifier).state = session;
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Session> login(String login, String password) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.login(login, password);
      _ref.read(sessionStateProvider.notifier).state = session;
      state = AsyncValue.data(session);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Session> register(
    String email,
    String username,
    String password,
  ) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.register(email, username, password);
      _ref.read(sessionStateProvider.notifier).state = session;
      state = AsyncValue.data(session);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _ref.read(sessionStateProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<Session?>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider), ref);
    });

final sessionProvider = FutureProvider<Session?>((ref) async {
  final cached = ref.watch(sessionStateProvider);
  if (cached != null) return cached;
  final session = await ref.watch(authRepositoryProvider).currentSession();
  ref.read(sessionStateProvider.notifier).state = session;
  return session;
});
final feedProvider = FutureProvider.family<FeedPage, String?>(
  (ref, cursor) => ref.watch(feedRepositoryProvider).getFeed(cursor: cursor),
);
final communityChannelsProvider = FutureProvider<List<CommunityChannel>>(
  (ref) => ref.watch(communityRepositoryProvider).getChannels(),
);
