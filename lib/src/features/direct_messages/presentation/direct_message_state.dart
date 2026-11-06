import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/live_direct_message_repository.dart';
import '../domain/direct_message_repository.dart';
import 'dm_inbox_controller.dart';
import 'dm_timeline_controller.dart';
import 'dm_timeline_state.dart';

export 'dm_inbox_controller.dart';
export 'dm_timeline_controller.dart';
export 'dm_timeline_state.dart';

final directMessageRepositoryProvider = Provider<DirectMessageRepository>(
  (ref) => LiveDirectMessageRepository(ref.watch(apiClientProvider)),
);

/// Resets automatically whenever the authenticated user changes.
final selectedDmConversationIdProvider = StateProvider<String?>((ref) {
  ref.watch(sessionStateProvider.select((session) => session?.userId));
  return null;
});

enum DmInboxTab { all, requests }

final dmInboxTabProvider = StateProvider<DmInboxTab>((ref) {
  ref.watch(sessionStateProvider.select((session) => session?.userId));
  return DmInboxTab.all;
});

final dmInboxProvider = StateNotifierProvider<DmInboxController, DmInboxState>((
  ref,
) {
  final session = ref.watch(sessionStateProvider);
  final controller = DmInboxController(
    ref.watch(directMessageRepositoryProvider),
    userId: session?.userId,
    readActiveUserId: () => ref.read(sessionStateProvider)?.userId,
    readSelectedConversationId: () =>
        ref.read(selectedDmConversationIdProvider),
    onSelectConversation: (conversationId) {
      ref.read(selectedDmConversationIdProvider.notifier).state =
          conversationId;
    },
  );
  if (session != null && session.userId.isNotEmpty) {
    unawaited(controller.load());
  }
  return controller;
});

final dmTimelineProvider = StateNotifierProvider.autoDispose
    .family<DmTimelineController, DmTimelineState, String>((
      ref,
      conversationId,
    ) {
      final session = ref.watch(sessionStateProvider);
      final controller = DmTimelineController(
        ref.watch(directMessageRepositoryProvider),
        conversationId: conversationId,
        userId: session?.userId,
        readActiveUserId: () => ref.read(sessionStateProvider)?.userId,
        onConversationSynced: (conversation) {
          ref.read(dmInboxProvider.notifier).upsertConversation(conversation);
        },
        onConversationRemoved: (removedId) {
          ref.read(dmInboxProvider.notifier).removeConversation(removedId);
        },
      );
      if (session != null && session.userId.isNotEmpty) {
        unawaited(controller.load());
      }
      return controller;
    });
