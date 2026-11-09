import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_message.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/push_message_presenter.dart';
import 'package:vnlfsocialapp/src/i18n/vi.dart';

PushMessage? decode(Object? json) =>
    PushMessage.decode(utf8.encode(jsonEncode(json)));

final website = Uri.parse('https://vietnamlinuxfamily.net');

void main() {
  group('PushMessage.decode', () {
    test('reads the push worker payload', () {
      final message = decode({
        'title': 'VNLF Social',
        'body': 'Bạn có tin nhắn riêng mới.',
        'url': '/messages/conv-1',
        'tag': 'dm:conv-1',
        'urgent': false,
        'requireInteraction': true,
      })!;
      expect(message.path, '/messages/conv-1');
      expect(message.tag, 'dm:conv-1');
      expect(message.body, 'Bạn có tin nhắn riêng mới.');
      expect(message.urgent, isFalse);
      expect(message.requireInteraction, isTrue);
    });

    test('falls back like the service worker', () {
      final message = decode({'url': 'https://example.com/a', 'body': 3})!;
      expect(message.path, '/notifications');
      expect(message.tag, 'vnlf-notification');
      expect(message.body, isNull);
      expect(decode({'url': '//example.com/a'})!.path, '/notifications');
    });

    test('drops what the service worker drops', () {
      expect(PushMessage.decode(utf8.encode('không phải JSON')), isNull);
      expect(PushMessage.decode([0xff, 0xfe]), isNull);
      expect(decode(['/a']), isNull);
      expect(decode({'url': r'/\example.com'}), isNull);
      expect(decode({'url': '/\t/example.com'}), isNull);
    });
  });

  group('PushMessagePresenter', () {
    late List<Map<String, Object?>> shown;
    var inFront = false;

    PushMessagePresenter presenter() {
      shown = [];
      return PushMessagePresenter(
        website: website,
        appInFront: () => inFront,
        show:
            ({
              required int id,
              required String title,
              required String body,
              String? payload,
              bool persistent = false,
            }) async => shown.add({
              'id': id,
              'title': title,
              'body': body,
              'payload': payload,
              'persistent': persistent,
            }),
      );
    }

    test('shows the message with an app route and a stable id', () async {
      inFront = false;
      final present = presenter();
      await present.present(
        decode({
          'body': 'Có người đã trả lời bạn.',
          'url': '/a/bai-viet?comment=c1',
          'tag': 'reply:n1',
          'requireInteraction': false,
        })!,
      );
      expect(shown.single, {
        'id': pushNotificationId('reply:n1'),
        'title': vi.app.notifications.tieuDeThongBaoDay,
        'body': 'Có người đã trả lời bạn.',
        'payload': '/thread/bai-viet',
        'persistent': false,
      });
      expect(pushNotificationId('reply:n1'), 1710221486);
    });

    test('opens pages the app lacks on the website', () async {
      inFront = false;
      final present = presenter();
      await present.present(decode({'url': '/help', 'urgent': true})!);
      expect(shown.single['payload'], 'https://vietnamlinuxfamily.net/help');
      expect(shown.single['body'], vi.app.notifications.banCoHoatDongMoiDay);
    });

    test('skips all but urgent messages while the app is in front', () async {
      inFront = true;
      final present = presenter();
      await present.present(decode({'url': '/messages/c', 'tag': 'dm:c'})!);
      expect(shown, isEmpty);
      await present.present(
        decode({
          'url': '/settings/security',
          'tag': 'account:u',
          'urgent': true,
          'requireInteraction': true,
        })!,
      );
      expect(shown.single['payload'], '/settings');
      expect(shown.single['persistent'], isTrue);
    });
  });
}
