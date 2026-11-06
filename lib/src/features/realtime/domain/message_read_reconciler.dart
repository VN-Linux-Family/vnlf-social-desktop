import '../../../domain/models.dart' show ParseFailure;

/// An opaque, single-use handle for a read started by a reconciler.
final class MessageReadTicket<T extends Object> {
  MessageReadTicket._(this._baseline);

  final int _baseline;
}

/// Reconciles a server snapshot with mutations observed while it was in flight.
///
/// Returned lists are unmodifiable; ordering is the caller's responsibility.
final class MessageReadReconciler<T extends Object> {
  MessageReadReconciler({required this.idOf});

  final String Function(T) idOf;
  final Set<MessageReadTicket<T>> _active = {};
  final Map<String, _Mutation<T>> _mutations = {};
  int _sequence = 0;

  MessageReadTicket<T> beginRead() {
    final ticket = MessageReadTicket<T>._(_sequence);
    _active.add(ticket);
    return ticket;
  }

  void upsert(T message) {
    if (_active.isEmpty) return;
    _mutations[idOf(message)] = _Mutation(++_sequence, message);
  }

  void remove(String id) {
    if (_active.isEmpty) return;
    _mutations[id] = _Mutation<T>(++_sequence, null);
  }

  List<T> complete(MessageReadTicket<T> ticket, Iterable<T> serverItems) {
    if (!_active.contains(ticket)) {
      throw const ParseFailure('realtime.readTicket');
    }
    final items = <String, T>{};
    for (final message in serverItems) {
      items[idOf(message)] = message;
    }
    for (final entry in _mutations.entries) {
      if (entry.value.sequence <= ticket._baseline) continue;
      final message = entry.value.message;
      if (message == null) {
        items.remove(entry.key);
      } else {
        items[entry.key] = message;
      }
    }
    final result = List<T>.unmodifiable(items.values);
    _active.remove(ticket);
    _prune();
    return result;
  }

  /// Cancelling an inactive or foreign ticket has no effect.
  void cancel(MessageReadTicket<T> ticket) {
    if (_active.remove(ticket)) _prune();
  }

  /// Invalidates all outstanding tickets and drops retained mutations.
  void reset() {
    _active.clear();
    _mutations.clear();
    _sequence = 0;
  }

  void _prune() {
    if (_active.isEmpty) {
      _mutations.clear();
      return;
    }
    var oldest = _active.first._baseline;
    for (final ticket in _active) {
      if (ticket._baseline < oldest) oldest = ticket._baseline;
    }
    _mutations.removeWhere((_, mutation) => mutation.sequence <= oldest);
  }
}

final class _Mutation<T extends Object> {
  const _Mutation(this.sequence, this.message);

  final int sequence;
  final T? message;
}
