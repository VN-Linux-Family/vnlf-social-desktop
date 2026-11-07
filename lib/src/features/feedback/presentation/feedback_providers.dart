import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../data/live_feedback_repository.dart';
import '../domain/feedback_models.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => LiveFeedbackRepository(ref.watch(apiClientProvider)),
);

final feedbackHistoryProvider = FutureProvider.autoDispose
    .family<List<FeedbackTicket>, String>((ref, ownerId) async {
      if (ref.watch(
            sessionStateProvider.select((session) => session?.userId),
          ) !=
          ownerId) {
        return const [];
      }
      final tickets = await ref
          .watch(feedbackRepositoryProvider)
          .loadMine(refresh: true);
      if (ref.read(sessionStateProvider)?.userId != ownerId) return const [];
      return tickets;
    });

final feedbackThreadProvider = FutureProvider.autoDispose
    .family<FeedbackThread, (String, String)>((ref, key) async {
      final (ownerId, ticketId) = key;
      if (ref.watch(
            sessionStateProvider.select((session) => session?.userId),
          ) !=
          ownerId) {
        throw const HttpFailure(401);
      }
      final result = await ref
          .watch(feedbackRepositoryProvider)
          .loadThread(ticketId, refresh: true);
      if (ref.read(sessionStateProvider)?.userId != ownerId) {
        throw const HttpFailure(401);
      }
      return result;
    });
