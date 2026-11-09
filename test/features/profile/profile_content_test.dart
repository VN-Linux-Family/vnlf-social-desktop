import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/main.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/public_profile.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_data.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_header.dart';

void main() {
  for (final scale in [1.0, 1.6]) {
    testWidgets(
      'profile identity clears its overlapping avatar at scale $scale',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pump(tester, _Profiles());
        final header = find.byType(ProfileHeader);
        final avatar = find.descendant(
          of: header,
          matching: find.byType(VnlfAvatar),
        );
        final name = find.descendant(
          of: header,
          matching: find.text('Nguyễn An'),
        );
        expect(
          tester.getTopLeft(name).dy,
          greaterThanOrEqualTo(tester.getBottomRight(avatar).dy + 12),
        );
      },
    );
  }

  testWidgets('opening a profile requests only its visible content section', (
    tester,
  ) async {
    final repository = _Profiles();
    await _pump(tester, repository);
    expect(repository.requested, ['profile', 'posts']);
    await _select(tester, 'Bình luận');
    expect(repository.requested, ['profile', 'posts', 'comments']);
  });
  testWidgets('guestbook link opens the guestbook tab directly', (
    tester,
  ) async {
    final repository = _Profiles();
    await _pump(tester, repository, route: '/profile/fixture?tab=guestbook');
    expect(repository.requested, ['profile', 'guestbook']);
    expect(find.text('Lời nhắn đầu'), findsOneWidget);
  });
  testWidgets(
    'public tabs display scoped data and guestbook pages without wardrobe controls',
    (tester) async {
      final repository = _Profiles();
      String? copiedLink;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedLink =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _pump(tester, repository);
      expect(find.text('271'), findsOneWidget);
      expect(find.text('Level 4'), findsOneWidget);
      expect(find.text('đang theo dõi'), findsOneWidget);
      expect(find.text('người theo dõi'), findsOneWidget);
      expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsOneWidget);
      expect(find.text('Karma'), findsNothing);
      expect(find.text('Tủ đồ & Huy hiệu'), findsNothing);
      expect(find.text('Bài viết'), findsOneWidget);
      expect(find.text('Bài viết trong hồ sơ'), findsOneWidget);
      final share = find.bySemanticsLabel('Chia sẻ bài').first;
      await tester.ensureVisible(share);
      await tester.tap(share);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sao chép').last);
      await tester.pumpAndSettle();
      expect(copiedLink, 'https://vietnamlinuxfamily.net/a/profile-post');
      expect(find.text('Đã sao chép liên kết'), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng hộp thoại'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await _select(tester, 'Bình luận');
      expect(find.text('Bình luận trong hồ sơ'), findsOneWidget);
      await _select(tester, 'Dự án');
      expect(find.text('Công cụ Linux'), findsOneWidget);
      await _select(tester, 'Sổ lưu bút');
      expect(find.text('Lời nhắn đầu'), findsOneWidget);
      final more = find.text('Xem thêm');
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(repository.cursor, 'page-2');
      expect(find.text('Lời nhắn tiếp'), findsOneWidget);
      expect(find.text('Xem thêm'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a failed profile section has its own working retry', (
    tester,
  ) async {
    final repository = _Profiles()..postsUnavailable = true;
    await _pump(tester, repository);
    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text('Không tải được nội dung'), findsOneWidget);
    repository.postsUnavailable = false;
    final retry = find.text('Thử lại');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('Bài viết trong hồ sơ'), findsOneWidget);
    expect(find.text('Không tải được nội dung'), findsNothing);
  });
}

Future<void> _select(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(VnlfFeedTabBar),
    matching: find.text(label),
  );
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  _Profiles repository, {
  String route = '/profile/fixture',
}) async {
  tester.platformDispatcher.localesTestValue = const [Locale('vi')];
  tester.view.physicalSize = const Size(390, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        publicProfileRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MainApp(),
    ),
  );
  await tester.pumpAndSettle();
  final router =
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
          as GoRouter;
  router.go(route);
  await tester.pumpAndSettle();
}

class _Profiles implements PublicProfileRepository {
  final requested = <String>[];
  bool postsUnavailable = false;
  String? cursor;
  static const author = Author(username: 'fixture', displayName: 'Nguyễn An');
  @override
  Future<PublicProfile?> getProfile(String username) async {
    requested.add('profile');
    return const PublicProfile(
      author: author,
      totalPoints: 271,
      level: 4,
      currentStreak: 7,
      followingCount: 9,
      followerCount: 12,
      bio: 'Tiếng Việt: ặ ữ ờ ẫ ệ',
    );
  }

  @override
  Future<FeedPage> getPosts(String username) async {
    requested.add('posts');
    if (postsUnavailable) throw const TransportFailure();
    return FeedPage(
      items: const [
        FeedPost(
          id: 'profile-post',
          slug: 'profile-post',
          author: author,
          excerpt: 'Bài viết trong hồ sơ',
          voteScore: 1,
          commentCount: 0,
        ),
      ],
    );
  }

  @override
  Future<ProfileCommentsPage> getComments(String username) async {
    requested.add('comments');
    return ProfileCommentsPage(
      items: const [
        ProfileComment(
          id: 'comment-1',
          articleId: 'profile-post',
          articleSlug: 'profile-post',
          content: 'Bình luận trong hồ sơ',
        ),
      ],
    );
  }

  @override
  Future<ProjectsPage> getProjects(String username) async {
    requested.add('projects');
    return ProjectsPage(
      items: const [ProjectItem(id: 'project-1', name: 'Công cụ Linux')],
    );
  }

  @override
  Future<GuestbookPage> getGuestbook(String username, {String? cursor}) async {
    requested.add('guestbook');
    this.cursor = cursor;
    return GuestbookPage(
      enabled: true,
      total: 2,
      nextCursor: cursor == null ? 'page-2' : null,
      items: [
        GuestbookEntry(
          id: cursor ?? 'first',
          author: author,
          content: cursor == null ? 'Lời nhắn đầu' : 'Lời nhắn tiếp',
        ),
      ],
    );
  }
}
