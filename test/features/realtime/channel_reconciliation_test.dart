import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/channels/domain/channel_models.dart';
import 'package:vnlfsocialapp/src/features/channels/presentation/live_channel_state.dart';

import '../channels/live_channels_test.dart' show ControlledRepository;

ChannelMessage msg(String id, String text, {String topic = 'channel'}) =>
    ChannelMessage(
      id: id,
      channelId: topic,
      author: const Author(id: 'p', username: 'p', displayName: 'Peer'),
      content: text,
    );

class Pending extends ControlledRepository {
  final pending = Completer<ChannelMessagePage>();
  @override
  Future<ChannelMessagePage> getMessages(String id, {String? cursor}) =>
      pending.future;
}

void main() {
  test('channel routing is checked before any state is changed', () {
    final c = ChannelTimelineController(ControlledRepository(), 'channel');
    addTearDown(c.dispose);
    c.applyRealtimeMessage(msg('m', 'other', topic: 'other'));
    expect(c.state.messages, isEmpty);
  });
  test('stale history cannot undo realtime edits or deletions', () async {
    final repo = Pending();
    final c = ChannelTimelineController(repo, 'channel');
    addTearDown(c.dispose);
    final read = c.load();
    c.applyRealtimeMessage(msg('m', 'edited'));
    c.removeRealtimeMessage('gone');
    repo.pending.complete(
      ChannelMessagePage(items: [msg('m', 'old'), msg('gone', 'deleted')]),
    );
    await read;
    expect(c.state.messages.single.content, 'edited');
  });
}
