import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/public_profile.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_card.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_data.dart';

const _author = Author(
  id: 'member-2',
  username: 'an',
  displayName: 'Nguyễn An',
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Session? session,
    String? page,
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget link(BuildContext context) => Center(
      child: VnlfProfilePreview.wrap(context, 'an', const Text('Nguyễn An')),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: page == null
                ? Builder(builder: link)
                : ProfilePageScope(
                    username: page,
                    child: Builder(builder: link),
                  ),
          ),
        ),
        GoRoute(
          path: '/profile/:id',
          builder: (context, state) =>
              Text('profile ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith((ref) => session),
          publicProfileRepositoryProvider.overrideWithValue(_Profiles()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => ProfileCardScope(child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<TestGesture> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('Nguyễn An')));
    return mouse;
  }

  testWidgets('a mouse resting 450 ms on a name opens the card', (
    tester,
  ) async {
    await pump(tester);
    final mouse = await hover(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Xem trang cá nhân'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Thẻ hồ sơ của @an'), findsOneWidget);
    expect(find.text('@an · Level 3'), findsOneWidget);
    expect(find.text('Dùng Arch hằng ngày.'), findsOneWidget);
    // A guest sees follow, which signs in first, but no message button.
    expect(find.text('Theo dõi'), findsOneWidget);
    expect(find.text('Nhắn tin'), findsNothing);

    await mouse.moveTo(const Offset(1, 1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Xem trang cá nhân'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Xem trang cá nhân'), findsNothing);
  });

  testWidgets('passing over a name does not open the card', (tester) async {
    await pump(tester);
    final mouse = await hover(tester);
    await tester.pump(const Duration(milliseconds: 200));
    await mouse.moveTo(const Offset(1, 1));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Xem trang cá nhân'), findsNothing);
  });

  testWidgets('the card links to the profile and closes', (tester) async {
    await pump(
      tester,
      session: const Session(userId: 'member-1', displayName: 'Lan'),
    );
    await hover(tester);
    await tester.pump(const Duration(milliseconds: 460));
    await tester.pumpAndSettle();
    expect(find.text('Nhắn tin'), findsOneWidget);
    await tester.tap(find.text('Xem trang cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('profile an'), findsOneWidget);
    expect(find.text('Xem trang cá nhân'), findsNothing);
  });

  testWidgets('a long press on touch opens the card as a sheet', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(find.text('Nguyễn An'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Đóng thẻ hồ sơ'), findsOneWidget);
    expect(find.text('profile an'), findsNothing);
    await tester.tap(find.byTooltip('Đóng thẻ hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Xem trang cá nhân'), findsNothing);
  });

  testWidgets('a profile page shows no card for its own member', (
    tester,
  ) async {
    await pump(tester, page: 'An');
    await hover(tester);
    await tester.pump(const Duration(milliseconds: 460));
    await tester.pumpAndSettle();
    expect(find.text('Xem trang cá nhân'), findsNothing);
  });
}

class _Profiles implements PublicProfileRepository {
  @override
  Future<PublicProfile?> getProfile(String username) async =>
      const PublicProfile(
        author: _author,
        level: 3,
        bio: 'Dùng   Arch\nhằng ngày.',
        followedByViewer: false,
        blockedByViewer: false,
        decor: ProfileDecor(themeId: 'arch'),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
