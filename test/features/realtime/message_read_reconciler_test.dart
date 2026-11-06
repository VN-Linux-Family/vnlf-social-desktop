import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/message_read_reconciler.dart';

class Message {
  const Message(this.id, this.text);
  final String id;
  final String text;
}

void main() {
  MessageReadReconciler<Message> reconciler() =>
      MessageReadReconciler(idOf: (message) => message.id);
  Map<String, String> contents(List<Message> messages) => {
    for (final message in messages) message.id: message.text,
  };

  test('applies later updates, additions and tombstones to a stale read', () {
    final state = reconciler();
    final ticket = state.beginRead();
    state.upsert(const Message('a', 'new'));
    state.upsert(const Message('c', 'added'));
    state.remove('b');
    expect(contents(state.complete(ticket, [
      const Message('a', 'old'),
      const Message('b', 'deleted'),
    ])), {'a': 'new', 'c': 'added'});
  });

  test('overlapping reads retain only mutations newer than each baseline', () {
    final state = reconciler();
    final old = state.beginRead();
    state.upsert(const Message('a', 'between'));
    state.remove('b');
    final newer = state.beginRead();
    state.upsert(const Message('c', 'after'));
    expect(contents(state.complete(newer, [
      const Message('a', 'server-new'),
      const Message('b', 'server-restored'),
    ])), {'a': 'server-new', 'b': 'server-restored', 'c': 'after'});
    expect(contents(state.complete(old, [
      const Message('a', 'old'),
      const Message('b', 'old'),
    ])), {'a': 'between', 'c': 'after'});
  });

  test('oldest completion and cancellation preserve newer active overlays', () {
    final state = reconciler();
    final old = state.beginRead();
    state.upsert(const Message('a', 'before-new'));
    final newer = state.beginRead();
    state.remove('b');
    state.complete(old, const []);
    final third = state.beginRead();
    state.cancel(third);
    expect(contents(state.complete(newer, [
      const Message('a', 'fresh'),
      const Message('b', 'stale'),
    ])), {'a': 'fresh'});
    final fresh = state.beginRead();
    expect(contents(state.complete(fresh, [const Message('b', 'restored')])),
        {'b': 'restored'});
  });

  test('idle mutations and cleared overlays do not mask later reads', () {
    final state = reconciler();
    state.remove('a');
    state.upsert(const Message('b', 'idle'));
    final first = state.beginRead();
    expect(contents(state.complete(first, [
      const Message('a', 'server'),
      const Message('b', 'server'),
    ])), {'a': 'server', 'b': 'server'});
    final cancelled = state.beginRead();
    state.remove('a');
    state.cancel(cancelled);
    final fresh = state.beginRead();
    expect(contents(state.complete(fresh, [const Message('a', 'server')])),
        {'a': 'server'});
  });

  test('last mutation wins and server duplicates collapse by ID', () {
    final state = reconciler();
    final ticket = state.beginRead();
    state.remove('a');
    state.upsert(const Message('a', 'restored'));
    state.upsert(const Message('b', 'temporary'));
    state.remove('b');
    final result = state.complete(ticket, [
      const Message('a', 'old'),
      const Message('a', 'duplicate'),
      const Message('b', 'old'),
      const Message('c', 'first'),
      const Message('c', 'last'),
    ]);
    expect(contents(result), {'a': 'restored', 'c': 'last'});
    expect(result.length, 2);
    expect(() => result.add(const Message('d', 'x')), throwsUnsupportedError);
    expect(() => result.clear(), throwsUnsupportedError);
  });

  test('foreign, consumed, cancelled and reset tickets cannot complete', () {
    final state = reconciler();
    final other = reconciler();
    final foreign = other.beginRead();
    expect(() => state.complete(foreign, const []), throwsA(isA<ParseFailure>()));
    final used = state.beginRead();
    state.complete(used, const []);
    expect(() => state.complete(used, const []), throwsA(isA<ParseFailure>()));
    final cancelled = state.beginRead();
    state.cancel(cancelled);
    state.cancel(cancelled);
    state.cancel(foreign);
    expect(() => state.complete(cancelled, const []), throwsA(isA<ParseFailure>()));
    final reset = state.beginRead();
    state.upsert(const Message('a', 'prior'));
    state.reset();
    state.cancel(reset);
    expect(() => state.complete(reset, const []), throwsA(isA<ParseFailure>()));
    final fresh = state.beginRead();
    expect(contents(state.complete(fresh, [const Message('a', 'fresh')])),
        {'a': 'fresh'});
    expect(other.complete(foreign, const []), isEmpty);
  });
}
