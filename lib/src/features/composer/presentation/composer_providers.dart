import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_client.dart';
import '../data/composer_recovery.dart';
import '../data/composer_repository.dart';
import '../domain/composer_draft.dart';
import 'composer_controller.dart';

final composerRepositoryProvider = Provider<ComposerRepository>(
  (ref) => LiveComposerRepository(ref.watch(apiClientProvider)),
);
final composerControllerProvider = ChangeNotifierProvider.autoDispose
    .family<ComposerController, String?>((ref, id) {
      final session =
          ref.watch(sessionStateProvider) ??
          ref.watch(sessionProvider).valueOrNull;
      if (session == null) throw const HttpFailure(401);
      final controller = ComposerController(
        repository: ref.watch(composerRepositoryProvider),
        recovery: ComposerRecovery(ref.watch(sessionStorageProvider)),
        userId: session.userId,
        slot: id ?? 'new',
        isCurrent: () =>
            (ref.read(sessionStateProvider) ??
                    ref.read(sessionProvider).valueOrNull)
                ?.userId ==
            session.userId,
      );
      unawaited(controller.initialize(draftId: id));
      return controller;
    });
final composerDraftsProvider = FutureProvider.autoDispose<List<ComposerDraft>>((
  ref,
) {
  final session =
      ref.watch(sessionStateProvider) ?? ref.watch(sessionProvider).valueOrNull;
  if (session == null) throw const HttpFailure(401);
  return ref.watch(composerRepositoryProvider).drafts();
});
