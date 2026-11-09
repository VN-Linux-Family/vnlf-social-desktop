import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/community_sounds.dart';

void main() {
  late List<CommunityChime> rung;
  late DateTime now;

  setUp(() {
    rung = [];
    now = DateTime.utc(2026, 11, 10, 8);
  });

  CommunitySounds sounds() =>
      CommunitySounds((chime) async => rung.add(chime), now: () => now);

  group('chimes follow the website rules', () {
    test('an event rings once', () {
      final subject = sounds();

      expect(subject.play(CommunitySound.dm, 'm1', enabled: true), isTrue);
      now = now.add(const Duration(seconds: 2));
      expect(subject.play(CommunitySound.dm, 'm1', enabled: true), isFalse);
      expect(rung, [CommunityChime.message]);
    });

    test('a muted event stays silent when sounds come back on', () {
      final subject = sounds();

      expect(subject.play(CommunitySound.dm, 'm1', enabled: false), isFalse);
      expect(subject.play(CommunitySound.dm, 'm1', enabled: true), isFalse);
      expect(rung, isEmpty);
    });

    test('a burst rings once every 750 ms per chime', () {
      final subject = sounds();

      expect(subject.play(CommunitySound.dm, 'm1', enabled: true), isTrue);
      expect(
        subject.play(CommunitySound.channel, 'm2', enabled: true),
        isFalse,
      );
      expect(
        subject.play(CommunitySound.voiceJoin, 'room:a', enabled: true),
        isTrue,
      );
      now = now.add(const Duration(milliseconds: 750));
      expect(subject.play(CommunitySound.mention, 'm3', enabled: true), isTrue);
      expect(rung, [
        CommunityChime.message,
        CommunityChime.voiceJoin,
        CommunityChime.message,
      ]);
    });

    test('it remembers the last thousand events', () {
      final subject = sounds();
      for (var index = 0; index <= 1000; index++) {
        subject.play(CommunitySound.channel, 'm$index', enabled: false);
      }

      expect(subject.play(CommunitySound.channel, 'm0', enabled: true), isTrue);
      now = now.add(const Duration(seconds: 1));
      expect(
        subject.play(CommunitySound.channel, 'm1000', enabled: true),
        isFalse,
      );
    });
  });

  group('the chime for a realtime event', () {
    Map<String, Object?> message({
      String author = 'peer-1',
      List<String>? attention,
    }) => {
      'id': 'message-1',
      'authorId': author,
      'content': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
      'attentionUserIds': ?attention,
    };

    test('a direct message', () {
      expect(messageSound('dm:message-created', message(), 'member-1'), (
        kind: CommunitySound.dm,
        id: 'message-1',
      ));
    });

    test('a channel message, with or without a mention', () {
      expect(
        messageSound('message:created', message(), 'member-1')?.kind,
        CommunitySound.channel,
      );
      expect(
        messageSound(
          'message:created',
          message(attention: ['member-1']),
          'member-1',
        )?.kind,
        CommunitySound.mention,
      );
    });

    test('nothing for the viewer\'s own messages or other events', () {
      expect(
        messageSound('dm:message-created', message(author: 'm'), 'm'),
        isNull,
      );
      expect(messageSound('message:updated', message(), 'member-1'), isNull);
      expect(messageSound('dm:message-created', message(), ''), isNull);
      expect(messageSound('dm:message-created', 'text', 'member-1'), isNull);
    });
  });
}
