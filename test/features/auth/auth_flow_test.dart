import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/data/live_auth_repository.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/domain/repositories.dart';
import 'package:vnlfsocialapp/src/features/auth/domain/password_reset.dart';
import 'package:vnlfsocialapp/src/features/auth/presentation/login_screen.dart';

Widget _buildTestApp({required GoRouter router, ProviderContainer? container}) {
  final app = MaterialApp.router(
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: router,
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

void main() {
  group('LiveAuthRepository', () {
    test('currentSession returns Session when 200 OK', () async {
      final client = ApiClient(
        transport: (req) async => ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'user': {
              'id': 'user-123',
              'username': 'linuxtester',
              'displayName': 'Linux Tester',
              'email': 'tester@vnlf.net',
            },
          }),
        ),
      );

      final repo = LiveAuthRepository(client);
      final session = await repo.currentSession();

      expect(session, isNotNull);
      expect(session!.userId, 'user-123');
      expect(session.username, 'linuxtester');
      expect(session.displayName, 'Linux Tester');
      expect(session.email, 'tester@vnlf.net');
    });

    test('currentSession returns null when 401 Unauthorized', () async {
      final client = ApiClient(
        transport: (req) async => ApiResponse(
          statusCode: 401,
          body: '{"code":"AUTH_REQUIRED","message":"Bạn cần đăng nhập."}',
        ),
      );

      final repo = LiveAuthRepository(client);
      final session = await repo.currentSession();

      expect(session, isNull);
    });

    test('login returns Session when credentials are valid', () async {
      final client = ApiClient(
        transport: (req) async {
          expect(req.method, 'POST');
          expect(req.path, '/api/v1/auth/login');
          final body = jsonDecode(req.body!) as Map<String, dynamic>;
          expect(body['login'], 'linuxtester');
          expect(body['password'], 'secret123');
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'id': 'user-123',
              'username': 'linuxtester',
              'displayName': 'Linux Tester',
            }),
          );
        },
      );

      final repo = LiveAuthRepository(client);
      final session = await repo.login('linuxtester', 'secret123');

      expect(session.userId, 'user-123');
      expect(session.username, 'linuxtester');
    });

    test('register returns Session when valid', () async {
      final client = ApiClient(
        transport: (req) async {
          expect(req.method, 'POST');
          expect(req.path, '/api/v1/auth/register');
          final body = jsonDecode(req.body!) as Map<String, dynamic>;
          expect(body['email'], 'newuser@vnlf.net');
          expect(body['username'], 'newuser');
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'user': {
                'id': 'new-user-1',
                'username': 'newuser',
                'displayName': 'New User',
                'email': 'newuser@vnlf.net',
              },
            }),
          );
        },
      );

      final repo = LiveAuthRepository(client);
      final session = await repo.register(
        'newuser@vnlf.net',
        'newuser',
        'secret123',
      );

      expect(session.userId, 'new-user-1');
      expect(session.username, 'newuser');
    });
  });

  group('LoginScreen UI', () {
    testWidgets('the website sign-in page switches to registration', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        ],
      );
      await tester.pumpWidget(_buildTestApp(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Nơi cộng đồng cùng xây dựng.'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsWidgets);
      expect(find.text('Đăng ký'), findsWidgets);
      expect(find.text('Email hoặc username'), findsOneWidget);
      expect(find.text('Vào VNLF Social'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);

      await tester.tap(find.text('Đăng ký').first);
      await tester.pumpAndSettle();

      expect(find.text('Email của bạn'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Nhập lại mật khẩu'), findsOneWidget);
      expect(find.text('Tạo tài khoản'), findsOneWidget);
    });

    testWidgets('invalid input shows the website messages and blocks submit', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/register',
            builder: (_, _) =>
                const LoginScreen(initialMode: AuthMode.register),
          ),
        ],
      );
      await tester.pumpWidget(_buildTestApp(router: router));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('reg-email-field')), 'abc');
      await tester.enterText(
        find.byKey(const Key('reg-password-field')),
        'ngan',
      );
      await tester.pump();
      expect(find.text('Email chưa đúng.'), findsOneWidget);
      expect(find.text('Mật khẩu cần ít nhất 10 ký tự.'), findsOneWidget);
    });

    testWidgets('successful login returns to the app', (tester) async {
      final fakeAuth = _FakeSuccessAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuth)],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home Page')),
          ),
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(router: router, container: container),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login-id-field')),
        'myusername',
      );
      await tester.enterText(
        find.byKey(const Key('login-password-field')),
        'supersecret',
      );
      await tester.pump();
      await tester.tap(find.text('Vào VNLF Social'));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('forgot password sends the link once and counts down', (
      tester,
    ) async {
      final resets = <String>[];
      final container = ProviderContainer(
        overrides: [
          passwordResetRepositoryProvider.overrideWithValue(
            _RecordingReset(resets),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        ],
      );
      await tester.pumpWidget(
        _buildTestApp(router: router, container: container),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();
      expect(find.text('Đặt lại mật khẩu.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('reg-email-field')),
        'ban@example.com',
      );
      await tester.pump();
      await tester.tap(find.text('Gửi link đặt lại'));
      await tester.pump();
      await tester.pump();

      expect(resets, ['ban@example.com']);
      expect(find.text('Kiểm tra hộp thư'), findsOneWidget);
      expect(find.text('Gửi lại sau 60s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Gửi lại sau 58s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Gửi lại'));
      await tester.pump();
      await tester.pump();
      expect(resets, hasLength(2));
      await tester.pump(const Duration(seconds: 61));
    });
  });
}

class _RecordingReset implements PasswordResetRepository {
  _RecordingReset(this.calls);
  final List<String> calls;

  @override
  Future<void> requestReset(String email) async => calls.add(email);
}

class _FakeSuccessAuthRepository implements AuthRepository {
  @override
  Future<Session?> currentSession() async => null;

  @override
  Future<Session> login(String login, String password) async {
    return Session(
      userId: 'test-user-id',
      displayName: 'Test User',
      username: login,
    );
  }

  @override
  Future<Session> register(
    String email,
    String username,
    String password,
  ) async {
    return Session(
      userId: 'new-user-id',
      displayName: username,
      username: username,
      email: email,
    );
  }

  @override
  Future<void> logout() async {}
}
