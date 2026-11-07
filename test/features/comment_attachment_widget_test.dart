import 'dart:convert';

import 'package:flutter/material.dart';
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
import 'package:vnlfsocialapp/src/features/thread/presentation/comment_attachment_picker.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/comments_providers.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/thread_comments.dart';

void main() {
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
    expect(
      find.text(
        'Ảnh được tải lên và công khai ngay khi chọn, có thể giữ siêu dữ liệu và vẫn lưu trên máy chủ sau khi xóa khỏi bản nháp.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('comment-add-photos')));
    await tester.pumpAndSettle();
    expect(find.text('anh.png'), findsOneWidget);
    expect(find.text('Xác nhận thất bại.'), findsOneWidget);
    await tester.tap(find.byTooltip('Thử xác nhận lại'));
    await tester.pumpAndSettle();
    expect(find.text('Sẵn sàng'), findsOneWidget);
    await tester.tap(find.text('Thêm bình luận'));
    await tester.pumpAndSettle();
    expect(find.text('anh.png'), findsOneWidget);
    await tester.tap(find.text('Thêm bình luận'));
    await tester.pumpAndSettle();
    expect(bodies, hasLength(2));
    expect(bodies.first['clientCommentId'], bodies.last['clientCommentId']);
    expect(bodies.last['attachmentIds'], ['asset']);
    expect(find.text('anh.png'), findsNothing);
  });
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
