import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/domain/direct_message_models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/dm_timeline_controller.dart';

import '../direct_messages/direct_message_controller_test.dart'
    show ControlledDmRepository;

DmMessage message(
  String id,
  String text, {
  String? conversation = 'conv-1',
  bool reacted = false,
}) => DmMessage(
  id: id,
  conversationId: conversation,
  authorId: 'peer',
  author: const Author(id: 'peer', username: 'peer', displayName: 'Peer'),
  content: text,
  reactions: [DmReaction(emoji: '👍', count: 2, viewerReacted: reacted)],
);

class PendingHistory extends ControlledDmRepository {
  final pending = Completer<DmMessagePage>();
  @override
  Future<DmMessagePage> getMessages(
    String id, {
    String? cursor,
    int limit = 50,
  }) => pending.future;
}

void main() {
  test('unrouted and other-conversation frames never reach the timeline', () {
    final c = DmTimelineController(
      ControlledDmRepository(),
      conversationId: 'conv-1',
      userId: 'owner',
    );
    addTearDown(c.dispose);
    c.applyRealtimeMessage(message('wrong', 'private', conversation: 'conv-2'));
    c.applyRealtimeMessage(message('missing', 'ambiguous', conversation: null));
    expect(c.state.messages, isEmpty);
  });
  test('incoming reaction projection preserves this viewer choice', () {
    final c = DmTimelineController(
      ControlledDmRepository(),
      conversationId: 'conv-1',
      userId: 'owner',
    );
    addTearDown(c.dispose);
    c.applyRealtimeMessage(message('m', 'before'), preserveViewerState: false);
    c.applyRealtimeMessage(message('m', 'after', reacted: true));
    expect(c.state.messages.single.reactions.single.viewerReacted, isFalse);
    expect(c.state.messages.single.content, 'after');
  });
  test(
    'events during initial history load survive its stale response',
    () async {
      final repo = PendingHistory();
      final c = DmTimelineController(
        repo,
        conversationId: 'conv-1',
        userId: 'owner',
      );
      addTearDown(c.dispose);
      final loading = c.load();
      c.applyRealtimeMessage(message('m', 'edited'));
      c.applyRealtimeMessage(message('new', 'added'));
      c.removeRealtimeMessage('deleted');
      repo.pending.complete(
        DmMessagePage(items: [message('m', 'old'), message('deleted', 'old')]),
      );
      await loading;
      expect(c.state.messages.map((m) => m.id), unorderedEquals(['m', 'new']));
      expect(c.state.messages.firstWhere((m) => m.id == 'm').content, 'edited');
    },
  );
}
