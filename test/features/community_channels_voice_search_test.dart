import 'package:vnlfsocialapp/src/features/projects/domain/project_directory.dart';
import 'package:vnlfsocialapp/src/features/projects/presentation/project_directory_controller.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';

import 'channels/live_channels_test.dart' show channelJson, messageJson;

import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';

void main() {
  testWidgets('desktop feed search button opens global search', (tester) async {
    final router = await _pump(tester, '/', width: 1440);
    await tester.tap(find.byTooltip('Tìm kiếm'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.state.matchedLocation, '/search');
    expect(find.byKey(const Key('search-input')), findsOneWidget);
  });

  testWidgets(
    'channel routes isolate history and retain acknowledged server sends',
    (tester) async {
      const owner = Session(userId: 'me', displayName: 'Một', role: 'MEMBER');
      final saved = <Map<String, dynamic>>[];
      var sends = 0;
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        cacheDuration: Duration.zero,
        transport: (request) async {
          Object data = {'items': <Object?>[], 'nextCursor': null};
          if (request.path == '/api/v1/channels') {
            data = {
              'items': [
                {
                  ...channelJson,
                  'id': 'channel-1',
                  'slug': 'chung',
                  'name': 'Chung',
                  'minRoleToPost': 'MEMBER',
                },
                {
                  ...channelJson,
                  'id': 'channel-2',
                  'slug': 'hoi-dap-linux',
                  'name': 'Hỏi đáp Linux',
                  'minRoleToPost': 'MEMBER',
                },
              ],
            };
          } else if (request.path == '/api/v1/channels/channel-2/messages') {
            if (request.method == 'POST') {
              sends++;
              final body = jsonDecode(request.body!) as Map<String, dynamic>;
              saved.add({
                ...messageJson,
                'id': 'created-1',
                'content': body['content'],
                'clientMessageId': body['clientMessageId'],
              });
              data = saved.last;
            } else {
              data = {'items': saved, 'nextCursor': null};
            }
          }
          return ApiResponse(statusCode: 200, body: jsonEncode(data));
        },
      );
      final router = await _pump(
        tester,
        '/channels',
        overrides: [
          sessionStateProvider.overrideWith((ref) => owner),
          sessionProvider.overrideWithValue(const AsyncData(owner)),
          apiClientProvider.overrideWithValue(client),
        ],
      );
      await tester.tap(
        find.byKey(const Key('communication-channel-channel-2')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('chat-input')),
        'Tiếng Việt: ặ ữ ờ ẫ ệ',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(sends, 1);
      expect(saved.single['content'], 'Tiếng Việt: ặ ữ ờ ẫ ệ');
      expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-input')))
            .controller!
            .text,
        isEmpty,
      );
      router.go('/channels/chung');
      await tester.pumpAndSettle();
      expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsNothing);
      router.go('/channels/hoi-dap-linux');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Làm mới tin nhắn'));
      await tester.pumpAndSettle();
      expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsOneWidget);
      expect(sends, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('voice join enables mute, deafen, share and leave controls', (
    tester,
  ) async {
    await _pump(tester, '/voice');
    expect(
      tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.byTooltip('Bật mic'),
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Tham gia phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Rời phòng'), findsOneWidget);
    expect(find.text('Bạn'), findsOneWidget);
    await tester.tap(find.byTooltip('Bật mic'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tắt mic'), findsOneWidget);
    await tester.tap(find.byTooltip('Tắt âm thanh'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Bật âm thanh'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.byTooltip('Bật mic'),
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Bật âm thanh'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chia sẻ màn hình'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Dừng chia sẻ'), findsOneWidget);
    await tester.tap(find.text('Rời phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn'), findsNothing);
    expect(find.text('Tham gia phòng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search query, scope, popular tags and clear filter real results',
    (tester) async {
      await _pump(tester, '/search');
      await tester.enterText(
        find.byKey(const Key('search-input')),
        '  VNLF-CLI  ',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('vnlf-cli'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Bài viết'));
      await tester.pumpAndSettle();
      expect(find.text('vnlf-cli'), findsNothing);
      expect(find.text('Không tìm thấy kết quả'), findsOneWidget);
      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Wayland'));
      await tester.pumpAndSettle();
      expect(find.text('Trải nghiệm Arch Linux và Wayland'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Thành viên'));
      await tester.enterText(find.byKey(const Key('search-input')), 'hoangnam');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Hoàng Nam'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('feed vote and bookmark survive a visit to thread and back', (
    tester,
  ) async {
    final router = await _pump(tester, '/');
    PostData post() =>
        tester.widget<VnlfPostCard>(find.byType(VnlfPostCard)).post!;
    Finder postAction(String label) => find.descendant(
      of: find.byType(VnlfPostCard),
      matching: find.bySemanticsLabel(label),
    );
    expect(post().voteScore, 3);
    await tester.tap(postAction('Ủng hộ'));
    await tester.pumpAndSettle();
    expect(post().voteScore, 2);
    expect(post().viewerVote, VoteState.neutral);
    await tester.tap(postAction('Phản đối'));
    await tester.pumpAndSettle();
    expect(post().voteScore, 1);
    await tester.tap(postAction('Ủng hộ'));
    await tester.pumpAndSettle();
    expect(post().voteScore, 3);
    await tester.tap(postAction('Lưu bài viết'));
    await tester.pumpAndSettle();
    expect(post().isBookmarked, isTrue);
    router.go('/thread/fixture-post-1');
    await tester.pumpAndSettle();
    expect(post().voteScore, 3);
    expect(post().isBookmarked, isTrue);
    await tester.tap(postAction('Phản đối'));
    await tester.pumpAndSettle();
    expect(post().voteScore, 1);
    router.go('/');
    await tester.pumpAndSettle();
    expect(post().voteScore, 1);
    expect(post().isBookmarked, isTrue);
  });

  testWidgets(
    'project language filter excludes other languages and can reset',
    (tester) async {
      await _pump(
        tester,
        '/projects',
        overrides: [
          projectDirectoryRepositoryProvider.overrideWithValue(
            _FilteringProjectRepository(),
          ),
        ],
      );
      expect(find.byType(VnlfProjectPreviewCard), findsNWidgets(2));
      await tester.tap(find.byType(DropdownButton<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rust (1)').last);
      await tester.pumpAndSettle();
      expect(find.text('Rust Tool'), findsOneWidget);
      expect(find.text('Dart Tool'), findsNothing);
      await tester.tap(find.byType(DropdownButton<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Python (1)').last);
      await tester.pumpAndSettle();
      expect(find.text('Không có dự án phù hợp'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả ngôn ngữ').last);
      await tester.pumpAndSettle();
      expect(find.byType(VnlfProjectPreviewCard), findsNWidgets(2));
    },
  );

  testWidgets('leaderboard weekly archive can return to current rankings', (
    tester,
  ) async {
    await _pump(tester, '/leaderboard');
    expect(find.text('450'), findsOneWidget);
    await tester.tap(find.byTooltip('Tuần trước'));
    await tester.pumpAndSettle();
    expect(find.text('450'), findsNothing);
    expect(find.text('Chưa có xếp hạng'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Tuần này'));
    await tester.pumpAndSettle();
    expect(find.text('450'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNull,
    );
  });

  for (final width in [390.0, 900.0, 1440.0]) {
    for (final route in ['/channels', '/voice', '/search']) {
      testWidgets('$route fits width $width with scaled text', (tester) async {
        await _pump(tester, route, width: width, scale: 1.3);
        expect(find.text('Màn hình này chưa có nội dung.'), findsNothing);
        expect(tester.takeException(), isNull);
        if (route == '/channels' && width == 1440) {
          expect(find.text('Đăng nhập để xem kênh cộng đồng'), findsOneWidget);
        }
      });
    }
  }
}

Future<GoRouter> _pump(
  WidgetTester tester,
  String route, {
  double width = 390,
  double scale = 1,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = createMainRouter()..go(route);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: VnlfTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _FilteringProjectRepository implements ProjectDirectoryRepository {
  @override
  Future<ProjectDirectoryPage> fetch(
    ProjectFilters filters, {
    String? cursor,
    bool refresh = false,
  }) async {
    const all = [
      ProjectItem(id: 'dart', name: 'Dart Tool', repo: {'language': 'Dart'}),
      ProjectItem(id: 'rust', name: 'Rust Tool', repo: {'language': 'Rust'}),
    ];
    return ProjectDirectoryPage(
      page: ProjectsPage(
        items: all
            .where(
              (p) =>
                  filters.language.isEmpty ||
                  p.repo?['language'] == filters.language,
            )
            .toList(),
      ),
      types: const [],
      languages: const [
        ProjectFacet('Dart', 1),
        ProjectFacet('Rust', 1),
        ProjectFacet('Python', 1),
      ],
    );
  }
}
