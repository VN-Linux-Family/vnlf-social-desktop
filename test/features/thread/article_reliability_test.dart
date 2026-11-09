import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/data/live_post_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/thread_comments.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/comments_providers.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comments_repository.dart';

ApiClient clientFor(ApiTransport transport) => ApiClient(
  transport: transport,
  throttleInterval: Duration.zero,
  hostKey: Object(),
);

const article = <String, dynamic>{
  'id': 'test-article',
  'author': {'username': 'synthetic', 'displayName': 'Thành viên thử'},
  'excerpt': 'Tóm tắt',
  'contentText': 'Nội dung đầy đủ',
  'contentJson': {
    'type': 'doc',
    'content': [
      {
        'type': 'heading',
        'attrs': {'level': 2},
        'content': [
          {'type': 'text', 'text': 'Tiêu đề'},
        ],
      },
    ],
  },
  'attachments': [
    {
      'id': 'image',
      'url': 'https://example.invalid/image.webp',
      'mime': 'image/webp',
    },
    {
      'id': 'video',
      'url': 'https://example.invalid/video.mp4',
      'mime': 'video/mp4',
    },
  ],
  'viewerVote': 1,
  'voteScore': 4,
  'viewerBookmarked': true,
  'publishedAt': '2026-11-05T00:00:00Z',
};

void main() {
  test('article detail retains the complete server projection', () async {
    final client = clientFor(
      (_) async => ApiResponse(statusCode: 200, body: jsonEncode(article)),
    );
    final post = await LivePostRepository(client).getPost('test-article');
    expect(post!.contentText, 'Nội dung đầy đủ');
    expect(post.contentJson?['type'], 'doc');
    expect(post.attachments.map((a) => a.mime), ['image/webp', 'video/mp4']);
    expect(post.viewerVote, 1);
    expect(post.viewerBookmarked, isTrue);
    expect(post.publishedAt, DateTime.utc(2026, 11, 5));
  });

  test(
    'article errors remain visible instead of returning feed excerpts',
    () async {
      final client = clientFor(
        (_) async => ApiResponse(statusCode: 403, body: '{}'),
      );
      final repository = LivePostRepository(client);
      await expectLater(
        repository.getPost('test-article'),
        throwsA(isA<HttpFailure>()),
      );
    },
  );

  testWidgets(
    'root comment omits parentId and renders one confirmed server record',
    (tester) async {
      final saved = <Map<String, dynamic>>[];
      Map<String, dynamic>? submitted;
      final client = clientFor((request) async {
        if (request.method == 'POST') {
          submitted = jsonDecode(request.body!) as Map<String, dynamic>;
          saved.add({
            'id': 'server-comment',
            'content': submitted!['content'],
            'author': {
              'username': 'synthetic',
              'displayName': 'Thành viên thử',
            },
          });
          return ApiResponse(statusCode: 200, body: jsonEncode(saved.single));
        }
        return ApiResponse(statusCode: 200, body: jsonEncode({'items': saved}));
      });
      await pumpComments(tester, client);
      await tester.enterText(
        find.byKey(const ValueKey('comment-input')),
        'Bình luận bền vững',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('comment-send')));
      await tester.pumpAndSettle();
      expect(submitted!['content'], 'Bình luận bền vững');
      expect(submitted, isNot(contains('parentId')));
      expect(
        submitted!['clientCommentId'],
        matches(RegExp(r'^[a-f0-9-]{36}$')),
      );
      expect(find.text('Bình luận bền vững'), findsOneWidget);
      expect(find.text('Thành viên thử'), findsOneWidget);
    },
  );

  testWidgets('reply to a reply targets the root and mentions the recipient', (
    tester,
  ) async {
    Map<String, dynamic>? submitted;
    final client = clientFor((request) async {
      if (request.method == 'POST') {
        submitted = jsonDecode(request.body!) as Map<String, dynamic>;
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'id': 'confirmed',
            ...submitted!,
            'author': {'username': 'me'},
          }),
        );
      }
      return ApiResponse(
        statusCode: 200,
        body: jsonEncode({
          'items': [
            {
              'id': 'root',
              'content': 'Root',
              'author': {'username': 'rootuser'},
            },
            {
              'id': 'child',
              'parentId': 'root',
              'content': 'Child',
              'author': {'username': 'childuser'},
            },
          ],
        }),
      );
    });
    await pumpComments(tester, client);
    await tester.ensureVisible(find.text('Trả lời').last);
    await tester.tap(find.text('Trả lời').last);
    await tester.pump();
    final input = find.byKey(const ValueKey('comment-input'));
    expect(tester.widget<TextField>(input).controller!.text, '@childuser ');
    await tester.enterText(input, '@childuser Trả lời bằng tiếng Việt');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('comment-send')));
    await tester.tap(find.byKey(const ValueKey('comment-send')));
    await tester.pumpAndSettle();
    expect(submitted!['parentId'], 'root');
  });

  testWidgets('uncertain comment retries keep the draft and identity', (
    tester,
  ) async {
    final bodies = <Map<String, dynamic>>[];
    final client = clientFor((request) async {
      if (request.method == 'POST') {
        bodies.add(jsonDecode(request.body!) as Map<String, dynamic>);
        return ApiResponse(statusCode: 503, body: '{}');
      }
      return ApiResponse(statusCode: 200, body: '{"items":[]}');
    });
    await pumpComments(tester, client);
    final input = find.byKey(const ValueKey('comment-input'));
    await tester.enterText(input, 'Bản nháp không đổi');
    await tester.pump();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('comment-send')));
      await tester.pumpAndSettle();
    }
    expect(bodies, hasLength(2));
    expect(bodies.first['clientCommentId'], isNotNull);
    expect(bodies.first['clientCommentId'], bodies.last['clientCommentId']);
    expect(tester.widget<TextField>(input).readOnly, isTrue);
    expect(
      tester.widget<TextField>(input).controller!.text,
      'Bản nháp không đổi',
    );
    await tester.tap(find.byKey(const ValueKey('comment-send')));
    await tester.pumpAndSettle();
    expect(bodies, hasLength(3));
    expect(bodies.last['clientCommentId'], bodies.first['clientCommentId']);
    expect(bodies.last['content'], bodies.first['content']);
  });

  testWidgets('failed submission retains the draft and shows a failure', (
    tester,
  ) async {
    final client = clientFor(
      (request) async => request.method == 'POST'
          ? ApiResponse(statusCode: 422, body: '{"code":"INPUT_INVALID"}')
          : ApiResponse(statusCode: 200, body: '{"items":[]}'),
    );
    await pumpComments(tester, client);
    await tester.enterText(
      find.byKey(const ValueKey('comment-input')),
      'Giữ lại bản nháp',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('comment-send')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Giữ lại bản nháp',
    );
    expect(find.textContaining('Chưa gửi được bình luận'), findsOneWidget);
  });

  testWidgets(
    'failed comments read offers retry instead of an empty discussion',
    (tester) async {
      final client = clientFor(
        (_) async => ApiResponse(statusCode: 403, body: '{}'),
      );
      await pumpComments(tester, client);
      expect(find.text('Chưa tải được bình luận'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );
}

Future<void> pumpComments(WidgetTester tester, ApiClient client) async {
  final focus = FocusNode();
  addTearDown(focus.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        commentsRepositoryProvider.overrideWithValue(
          LiveCommentsRepository(client),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ThreadComments(postId: 'test-article', focusNode: focus),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
