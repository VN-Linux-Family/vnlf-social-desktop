import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/domain/repositories.dart';
import 'package:vnlfsocialapp/src/features/discover/presentation/discover_screen.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/profile_relationship.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_relationship_controller.dart';
import 'package:vnlfsocialapp/src/features/projects/domain/project_directory.dart';
import 'package:vnlfsocialapp/src/features/projects/presentation/project_card.dart';
import 'package:vnlfsocialapp/src/features/projects/presentation/project_directory_controller.dart';

const _member = Session(
  userId: 'viewer',
  displayName: 'Người xem',
  username: 'nguoixem',
);

ProjectItem _project(
  String id, {
  String tier = 'COMMUNITY',
  int? comments,
  Map<String, dynamic>? repo,
}) => ProjectItem(
  id: id,
  name: 'Dự án $id',
  slug: id,
  tagline: 'Công cụ mã nguồn mở cho người dùng Linux',
  type: 'TOOL',
  tier: tier,
  relation: 'AUTHOR',
  seeking: true,
  accentColor: '#1872f7',
  owner: const Author(
    id: 'owner',
    username: 'chudan',
    displayName: 'Chủ Dự Án',
  ),
  repo:
      repo ??
      {
        'stars': 1234,
        'forks': 57,
        'language': 'Rust',
        'languageColor': '#dea584',
        'pushedAt': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
      },
  rating: const {'average': 4.6, 'count': 12},
  commentCount: comments,
);

void main() {
  late _Discover discover;
  late _Projects projects;
  late _Relationships relationships;

  setUp(() {
    discover = _Discover();
    projects = _Projects();
    relationships = _Relationships();
  });

  Future<GoRouter> pump(
    WidgetTester tester, {
    Session? session,
    Size size = const Size(1440, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/discover',
      routes: [
        GoRoute(
          path: '/discover',
          builder: (context, state) => const Scaffold(body: DiscoverScreen()),
        ),
        for (final path in [
          '/search',
          '/t/:slug',
          '/login',
          '/compose',
          '/projects',
          '/projects/:slug',
          '/profile/:id',
        ])
          GoRoute(
            path: path,
            builder: (context, state) => Text('route ${state.uri}'),
          ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith((ref) => session),
          discoverRepositoryProvider.overrideWithValue(discover),
          projectDirectoryRepositoryProvider.overrideWithValue(projects),
          profileRelationshipRepositoryProvider.overrideWithValue(
            relationships,
          ),
        ],
        child: MaterialApp.router(
          theme: VnlfTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('shows the website sections and no vote counts', (tester) async {
    await pump(tester);
    expect(find.text('Khám phá cộng đồng'), findsOneWidget);
    expect(find.text('Góc nhìn mới, mỗi ngày.'), findsOneWidget);
    for (final tag in ['Arch Linux', 'Wayland', 'CachyOS']) {
      expect(find.text(tag), findsOneWidget);
    }
    // Only the first three topics and people, as on the website.
    expect(find.text('Debian'), findsNothing);
    expect(find.text('Chủ đề cộng đồng'), findsNWidgets(3));
    expect(find.text('Dự án nổi bật'), findsOneWidget);
    expect(find.byType(ProjectCard), findsNWidgets(3));
    expect(find.text('Người viết nên theo dõi'), findsOneWidget);
    expect(find.text('@lan'), findsOneWidget);
    expect(find.text('@ba'), findsNothing);
    // /api/v1/discover articles carry no counts, so none are drawn.
    expect(find.byType(VnlfVoteCapsule), findsNothing);
  });

  testWidgets('the search box opens search, a topic its page', (tester) async {
    final router = await pump(tester);
    await tester.enterText(find.byType(TextField), 'wayland');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('route /search?q=wayland'), findsOneWidget);

    router.go('/discover');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arch Linux'));
    await tester.pumpAndSettle();
    expect(find.text('route /t/arch-linux'), findsOneWidget);
  });

  testWidgets('a guest who follows is sent to sign in', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Theo dõi').first);
    await tester.pumpAndSettle();
    expect(find.text('route /login'), findsOneWidget);
    expect(relationships.calls, isEmpty);
  });

  testWidgets('a member follows and unfollows from a card', (tester) async {
    await pump(tester, session: _member);
    // Nobody is offered a button to follow themselves.
    expect(find.text('Theo dõi'), findsOneWidget);
    expect(find.text('Đang theo dõi'), findsOneWidget);
    await tester.tap(find.text('Theo dõi').first);
    await tester.pumpAndSettle();
    expect(relationships.calls, ['follow:lan']);
    expect(find.text('Đang theo dõi'), findsNWidgets(2));
    await tester.tap(find.text('Đang theo dõi').first);
    await tester.pumpAndSettle();
    expect(relationships.calls, ['follow:lan', 'unfollow:lan']);
  });

  testWidgets('phones stack the sections in one column', (tester) async {
    await pump(tester, size: const Size(390, 2600));
    expect(tester.takeException(), isNull);
    final first = tester.getTopLeft(find.text('Arch Linux'));
    final second = tester.getTopLeft(find.text('Wayland'));
    expect(second.dx, first.dx);
    expect(second.dy, greaterThan(first.dy));
    expect(find.text('Khám phá cộng đồng'), findsNothing);
  });

  testWidgets('a project card follows its tier and the repository', (
    tester,
  ) async {
    Future<void> card(ProjectItem project) => tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        home: Scaffold(
          body: SizedBox(width: 380, child: ProjectCard(project: project)),
        ),
      ),
    );

    await card(_project('vnlf', tier: 'VNLF'));
    expect(find.text('VNLF'), findsOneWidget);
    expect(find.text('Vietnam Linux Family'), findsOneWidget);
    expect(find.text('Chủ Dự Án'), findsNothing);
    expect(find.text('Tìm người đóng góp'), findsOneWidget);
    expect(find.text('1,2k'), findsOneWidget);
    expect(find.text('4,6'), findsOneWidget);
    expect(find.text('(12)'), findsOneWidget);
    expect(find.text('Cập nhật 3 giờ trước'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('4,6 trên 5 điểm, 12 đánh giá')),
      findsOneWidget,
    );
    // No count when the server sends none.
    expect(find.bySemanticsLabel(RegExp('bình luận')), findsNothing);

    await card(_project('lotus', tier: 'PARTNER', comments: 4));
    expect(find.text('Đối tác'), findsOneWidget);
    expect(find.text('Chủ Dự Án'), findsOneWidget);
    expect(find.text('Tác giả'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('4 bình luận')), findsOneWidget);

    await card(_project('kin', repo: const {'stars': null}));
    expect(find.text('Đang lấy số liệu từ GitHub…'), findsOneWidget);
  });

  test('counts shorten like the website', () {
    expect(compactCount(999), '999');
    expect(compactCount(1000), '1k');
    expect(compactCount(1234), '1,2k');
    expect(compactCount(123456), '123k');
  });
}

class _Discover implements DiscoverRepository {
  @override
  Future<DiscoverData> getDiscoverData() async => DiscoverData(
    tags: [
      for (final (slug, name) in const [
        ('arch-linux', 'Arch Linux'),
        ('wayland', 'Wayland'),
        ('cachyos', 'CachyOS'),
        ('debian', 'Debian'),
      ])
        DiscoverTag(id: slug, slug: slug, name: name),
    ],
    users: const [
      DiscoverUser(
        author: Author(id: 'lan', username: 'lan', displayName: 'Trần Lan'),
        bio: 'Viết về Wayland và Hyprland.',
      ),
      DiscoverUser(
        author: Author(id: 'minh', username: 'minh', displayName: 'Lê Minh'),
        followedByViewer: true,
      ),
      DiscoverUser(
        author: Author(
          id: 'viewer',
          username: 'nguoixem',
          displayName: 'Người xem',
        ),
      ),
      DiscoverUser(
        author: Author(id: 'ba', username: 'ba', displayName: 'Phạm Ba'),
      ),
    ],
  );
}

class _Projects implements ProjectDirectoryRepository {
  @override
  Future<ProjectDirectoryPage> fetch(
    ProjectFilters filters, {
    String? cursor,
    bool refresh = false,
  }) async => ProjectDirectoryPage(
    page: ProjectsPage(
      items: [
        _project('mot', tier: 'VNLF'),
        _project('hai', tier: 'PARTNER', comments: 2),
        _project('ba'),
        _project('bon'),
      ],
    ),
    types: const [],
    languages: const [],
  );
}

class _Relationships implements ProfileRelationshipRepository {
  final calls = <String>[];

  @override
  Future<void> setFollowing(String userId, {required bool following}) async =>
      calls.add('${following ? 'follow' : 'unfollow'}:$userId');

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) async =>
      calls.add('${blocked ? 'block' : 'unblock'}:$userId');
}
