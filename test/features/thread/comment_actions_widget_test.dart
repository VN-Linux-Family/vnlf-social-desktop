import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comments_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/comments_providers.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/thread_comments.dart';

void main() {
  testWidgets(
    'comment voting, editing and deletion require server confirmation',
    (tester) async {
      var content = 'Bình luận thử nghiệm';
      var deleted = false;
      var score = 0;
      var vote = 0;
      var failEdit = true;
      final requests = <ApiRequest>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final client = ApiClient(
        transport: (request) async {
          requests.add(request);
          if (request.method == 'PATCH') {
            if (failEdit) return ApiResponse(statusCode: 500, body: '{}');
            content = (jsonDecode(request.body!) as Map)['content'] as String;
          }
          if (request.method == 'DELETE') {
            deleted = true;
            return ApiResponse(statusCode: 200, body: '{"ok":true}');
          }
          if (request.path.endsWith('/vote')) {
            score = 2;
            vote = 1;
            return ApiResponse(
              statusCode: 200,
              body: '{"voteScore":2,"viewerVote":1}',
            );
          }
          final comment = {
            'id': 'mine',
            'content': content,
            'voteScore': score,
            'viewerVote': vote,
            'canEdit': true,
            'canDelete': true,
            'author': {'username': 'synthetic', 'displayName': 'Bạn'},
          };
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode(
              request.method == 'GET'
                  ? {
                      'items': deleted ? <Map<String, dynamic>>[] : [comment],
                    }
                  : comment,
            ),
          );
        },
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commentsRepositoryProvider.overrideWithValue(
              LiveCommentsRepository(client),
            ),
          ],
          child: MaterialApp(
            theme: VnlfTheme.light(),
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ThreadComments(focusNode: focus, postId: 'article'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final semantics = tester.ensureSemantics();
      try {
        await tester.tap(find.bySemanticsLabel('Upvote bình luận').last);
      } finally {
        semantics.dispose();
      }
      await tester.pumpAndSettle();
      expect(requests.where((r) => r.path.endsWith('/vote')), hasLength(1));
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('comment-edit-input')),
        'Đã sửa nội dung',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('comment-edit-input')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('comment-edit-input')))
            .controller!
            .text,
        'Đã sửa nội dung',
      );
      expect(
        find.text(
          'Chưa lưu được thay đổi. Bản nháp vẫn được giữ; vui lòng thử lại.',
        ),
        findsOneWidget,
      );
      failEdit = false;
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('comment-edit-input')), findsNothing);
      expect(find.text('Đã sửa nội dung'), findsOneWidget);
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa bình luận'));
      await tester.pumpAndSettle();
      expect(requests.where((r) => r.method == 'DELETE'), hasLength(1));
      expect(find.text('Đã sửa nội dung'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
