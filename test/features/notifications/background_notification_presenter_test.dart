import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/notifications_repository.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/background_notification_presenter.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_event.dart';

const _comment = CommunityNotice(
  id: 'notice-1',
  type: 'comment-created',
  targetId: 'article-1',
  targetType: 'ARTICLE',
  href: '/a/cai-arch-linux',
  title: 'Cài Arch Linux trên Btrfs',
  excerpt: 'Dùng snapper để chụp lại trước khi cập nhật.',
  summarized: true,
  actors: [
    Author(id: 'peer-1', username: 'hoangnam', displayName: 'Hoàng Nam'),
  ],
  actorCount: 1,
);

CommunityEvent _event(String type, Object? data, {String eventId = 'e-1'}) =>
    CommunityEvent(
      type: type,
      eventId: eventId,
      occurredAt: DateTime.utc(2026, 11, 9),
      data: data,
    );

void main() {
  late List<({int id, String title, String body, String payload})> shown;
  late List<CommunityNotice> notices;
  late AppFailure? loadFailure;
  late int loads;

  setUp(() {
    shown = [];
    notices = [_comment];
    loadFailure = null;
    loads = 0;
  });

  BackgroundNotificationPresenter presenter() =>
      BackgroundNotificationPresenter(
        show:
            ({
              required id,
              required title,
              required body,
              required payload,
            }) async =>
                shown.add((id: id, title: title, body: body, payload: payload)),
        loadLatestNotices: () async {
          loads++;
          if (loadFailure case final failure?) throw failure;
          return NotificationsPage(items: notices, unreadCount: 1);
        },
        currentUserId: 'member-1',
        channelSlug: (id) => id == 'channel-1' ? 'linux-viet' : null,
      );

  group('activity notifications', () {
    test('describe the notice the way the notifications list does', () async {
      await presenter().present(
        _event('notification:created', {'id': 'notice-1'}),
      );

      expect(loads, 1);
      expect(shown.single, (
        id: 'notice-1'.hashCode,
        title: 'Hoàng Nam',
        body:
            'đã bình luận về bài viết của bạn: '
            'Dùng snapper để chụp lại trước khi cập nhật.',
        payload: '/thread/article-1',
      ));
    });

    test('an aggregated update replaces the earlier notification', () async {
      final subject = presenter();
      await subject.present(_event('notification:created', {'id': 'notice-1'}));
      await subject.present(
        _event('notification:updated', {'id': 'notice-1'}, eventId: 'e-2'),
      );

      expect(shown.map((item) => item.id).toSet(), {'notice-1'.hashCode});
    });

    test('skip a notice already read on another device', () async {
      notices = [_comment.read()];

      await presenter().present(
        _event('notification:updated', {'id': 'notice-1'}),
      );

      expect(shown, isEmpty);
    });

    test('fall back to generic copy when the notice cannot load', () async {
      loadFailure = const TransportFailure();

      await presenter().present(
        _event('notification:created', {'id': 'notice-1'}),
      );

      expect(shown.single, (
        id: 'notice-1'.hashCode,
        title: 'Vietnam Linux Family',
        body: 'Bạn có hoạt động mới trên Vietnam Linux Family.',
        payload: '/',
      ));
    });

    test('fall back when the notice is not on the newest page', () async {
      notices = [];

      await presenter().present(
        _event('notification:created', {'id': 'notice-1'}),
      );

      expect(
        shown.single.body,
        'Bạn có hoạt động mới trên Vietnam Linux Family.',
      );
      expect(shown.single.payload, '/');
    });

    test('open the feed for a notice without an in-app route', () async {
      notices = [
        const CommunityNotice(
          id: 'notice-2',
          type: 'system-announcement',
          targetId: '',
          targetType: 'SYSTEM',
          href: 'https://vietnamlinuxfamily.net/help',
        ),
      ];

      await presenter().present(
        _event('notification:created', {'id': 'notice-2'}),
      );

      expect(shown.single.title, 'Vietnam Linux Family');
      expect(shown.single.body, 'có cập nhật mới');
      expect(shown.single.payload, '/');
    });
  });

  group('messages', () {
    Map<String, Object?> message({
      String authorId = 'peer-1',
      String content = 'Tiếng Việt: ặ ữ ờ ẫ ệ',
    }) => {
      'id': 'message-1',
      'conversationId': 'conversation-1',
      'channelId': 'channel-1',
      'authorId': authorId,
      'author': {'id': authorId, 'username': 'lan', 'displayName': 'Lan'},
      'content': content,
    };

    test('a direct message shows its author and text', () async {
      await presenter().present(_event('dm:message-created', message()));

      expect(shown.single, (
        id: 'message-1'.hashCode,
        title: 'Lan',
        body: 'Tiếng Việt: ặ ữ ờ ẫ ệ',
        payload: '/messages/conversation-1',
      ));
      expect(loads, 0);
    });

    test('a message without text uses the localized fallback', () async {
      await presenter().present(
        _event('dm:message-created', message(content: '')),
      );

      expect(shown.single.body, 'Bạn có tin nhắn mới');
    });

    test('the member\'s own messages are not announced', () async {
      await presenter().present(
        _event('dm:message-created', message(authorId: 'member-1')),
      );
      await presenter().present(
        _event('message:created', message(authorId: 'member-1')),
      );

      expect(shown, isEmpty);
    });

    test('a channel message opens the channel by its slug', () async {
      await presenter().present(_event('message:created', message()));

      expect(shown.single.payload, '/channels/linux-viet');
    });

    test('an unknown channel opens the channel directory', () async {
      await presenter().present(
        _event('message:created', {...message(), 'channelId': 'channel-9'}),
      );

      expect(shown.single.payload, '/channels');
    });
  });

  test('other events are not announced', () async {
    await presenter().present(_event('presence:changed', {'userId': 'peer-1'}));

    expect(shown, isEmpty);
    expect(loads, 0);
  });
}
