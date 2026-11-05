import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/live_notifications_repository.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/notifications_controller.dart';

void main() {
  test('live notifications map server records and only confirm read writes after success', () async {
    var rejectRead = true;
    final writes = <ApiRequest>[];
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        if (request.method == 'POST') {
          writes.add(request);
          return ApiResponse(
            statusCode: request.path.endsWith('/read') && rejectRead
                ? 403
                : 204,
            body: '',
          );
        }
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'items': [
              {
                'id': 'notification-1',
                'type': 'article-liked',
                'targetType': 'ARTICLE',
                'targetId': 'article-1',
                'href': '/a/example',
                'targetSummary': {'title': 'Tiếng Việt: ặ ữ ờ ẫ ệ'},
                'actors': [
                  {'username': 'synthetic', 'displayName': 'Thành viên thử'},
                ],
                'readAt': null,
              },
            ],
            'nextCursor': 'next + page',
            'unreadCount': 2,
            'unseenCount': 1,
          }),
        );
      },
    );
    final controller = NotificationsController(
      LiveNotificationsRepository(client),
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.state.items.single.title, 'Tiếng Việt: ặ ữ ờ ẫ ệ');
    expect(controller.state.items.single.unread, isTrue);
    expect(writes.single.path, '/api/v1/notifications/seen');
    await controller.markRead('notification-1');
    expect(controller.state.items.single.unread, isTrue);
    expect(controller.state.failure, isA<HttpFailure>());
    rejectRead = false;
    await controller.markRead('notification-1');
    expect(controller.state.items.single.unread, isFalse);
    expect(jsonDecode(writes.last.body!), {
      'ids': ['notification-1'],
    });
    await controller.loadMore();
    expect(controller.state.items, hasLength(1));
  });
  test(
    'failed list remains an error and never inserts a welcome notification',
    () async {
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (_) async => ApiResponse(statusCode: 403, body: '{}'),
      );
      final controller = NotificationsController(
        LiveNotificationsRepository(client),
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.state.items, isEmpty);
      expect(controller.state.failure, isA<HttpFailure>());
    },
  );
}
