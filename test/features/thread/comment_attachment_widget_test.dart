import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comment_media_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comments_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/domain/comment_upload.dart';
import 'package:vnlfsocialapp/src/features/thread/mention/mention_candidates.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/comment_attachment_picker.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/comments_providers.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/thread_comments.dart';

void main() {
  testWidgets('comment composer inserts a selected member mention', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final candidates = _Candidates();
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) async =>
          ApiResponse(statusCode: 200, body: '{"items":[]}'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          sessionStorageProvider.overrideWithValue(_Storage()),
          sessionStateProvider.overrideWith(
            (_) => const Session(userId: 'owner', displayName: 'Owner'),
          ),
          mentionCandidatesRepositoryProvider.overrideWithValue(candidates),
          mentionSuggestionsEnabledProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ThreadComments(focusNode: focus, postId: 'article'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comment-input')));
    await tester.enterText(find.byKey(const ValueKey('comment-input')), '@du');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(candidates.queries, ['du']);
    await tester.tap(find.text('Dũng Lê'));
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('comment-input')),
    );
    expect(field.controller!.text, '@dung ');
    await tester.enterText(find.byKey(const ValueKey('comment-input')), '@du');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(field.controller!.text, '@dung ');
  });

  testWidgets('photo-only comment retains its photo and identity on failure', (
    tester,
  ) async {
    final bodies = <Map<String, dynamic>>[];
    var completionAttempts = 0;
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (r) async {
        if (r.method == 'GET') {
          return ApiResponse(statusCode: 200, body: '{"items":[]}');
        }
        if (r.path.endsWith('/presign')) {
          return ApiResponse(
            statusCode: 200,
            body:
                '{"assetId":"asset","uploadUrl":"https://storage.example/put"}',
          );
        }
        if (r.path.endsWith('/complete')) {
          completionAttempts++;
          return ApiResponse(
            statusCode: completionAttempts == 1 ? 500 : 200,
            body: completionAttempts == 1
                ? '{}'
                : '{"assetId":"asset","status":"READY"}',
          );
        }
        bodies.add(jsonDecode(r.body!) as Map<String, dynamic>);
        return ApiResponse(
          statusCode: bodies.length == 1 ? 500 : 200,
          body: bodies.length == 1 ? '{}' : '{"id":"new","content":"","attachments":[{"id":"asset"}],"author":{}}',
        );
      },
    );
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        sessionStorageProvider.overrideWithValue(_Storage()),
        commentsRepositoryProvider.overrideWithValue(
          LiveCommentsRepository(client),
        ),
        commentMediaRepositoryProvider.overrideWithValue(
          CommentMediaRepository(client, upload: (_, _, _) async {}),
        ),
        commentAttachmentPickerProvider.overrideWithValue(
          () async => [
            CommentUploadFile(
              name: 'anh.png',
              mime: 'image/png',
              length: 1,
              openRead: () => Stream.value([1]),
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionStateProvider.notifier).state = const Session(
      userId: 'owner',
      username: 'owner',
      displayName: 'Owner',
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
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
    const disclosure =
        'Ảnh được tải lên và công khai ngay khi chọn, có thể giữ siêu dữ liệu và vẫn lưu trên máy chủ sau khi xóa khỏi bản nháp.';
    expect(find.text(disclosure), findsNothing);
    await tester.tap(find.byKey(const ValueKey('comment-add-photos')));
    await tester.pumpAndSettle();
    expect(find.text('anh.png'), findsOneWidget);
    expect(find.text(disclosure), findsOneWidget);
    // Like the website, a failed upload offers "Thử lại" on the photo.
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('comment-send')));
    await tester.pumpAndSettle();
    expect(find.text('anh.png'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('comment-send')));
    await tester.pumpAndSettle();
    expect(bodies, hasLength(2));
    expect(bodies.first['clientCommentId'], bodies.last['clientCommentId']);
    expect(bodies.last['attachmentIds'], ['asset']);
    expect(find.byKey(const ValueKey('comment-confirmed')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('comment-send')))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('comment-confirmation-dismiss')),
    );
    await tester.tap(
      find.byKey(const ValueKey('comment-confirmation-dismiss')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('comment-confirmed')), findsNothing);
    expect(find.text('anh.png'), findsNothing);
  });
}

final class _Candidates implements MentionCandidatesRepository {
  final queries = <String>[];
  @override
  Future<List<MentionCandidate>> search(String articleId, String query) async {
    queries.add(query);
    return [
      const MentionCandidate(
        id: 'member',
        username: 'dung',
        displayName: 'Dũng Lê',
      ),
    ];
  }
}

final class _Storage implements SessionStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
