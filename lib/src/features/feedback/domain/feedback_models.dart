enum FeedbackKind { feedback, bug, osSupport, driverSupport }

enum FeedbackStatus { open, inReview, resolved, closed, deferred }

final class FeedbackTicket {
  const FeedbackTicket({
    required this.id,
    required this.reference,
    required this.kind,
    required this.status,
    required this.detail,
    required this.pagePath,
    required this.attachmentCount,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.staffReplied,
    this.resolvedAt,
  });

  final String id, reference, detail, pagePath;
  final FeedbackKind kind;
  final FeedbackStatus status;
  final int attachmentCount, messageCount;
  final DateTime createdAt, updatedAt;
  final DateTime? resolvedAt;
  final bool staffReplied;
}

final class FeedbackMessage {
  const FeedbackMessage({
    required this.id,
    required this.staff,
    required this.mine,
    required this.content,
    required this.createdAt,
    this.authorName,
  });
  final String id, content;
  final bool staff, mine;
  final DateTime createdAt;
  final String? authorName;
}

final class FeedbackThread {
  FeedbackThread({
    required this.ticket,
    required List<FeedbackMessage> messages,
  }) : messages = List.unmodifiable(messages);
  final FeedbackTicket ticket;
  final List<FeedbackMessage> messages;
}

abstract interface class FeedbackRepository {
  Future<List<FeedbackTicket>> loadMine({bool refresh = false});
  Future<FeedbackThread> loadThread(String ticketId, {bool refresh = false});
  Future<FeedbackMessage> sendMessage({
    required String ticketId,
    required String clientMessageId,
    required String content,
  });
}
