import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import 'preferences.dart';
import 'preferences_repository.dart';

final class PreferencesState {
  const PreferencesState({
    this.saved,
    this.draft,
    this.busy = false,
    this.loadFailed = false,
    this.uncertain = false,
    this.savedNotice = false,
  });

  /// Last confirmed server value; it is not current while a write is uncertain.
  final WebsitePreferences? saved;
  WebsitePreferences? get confirmed => uncertain ? null : saved;
  final WebsitePreferences? draft;
  final bool busy;
  final bool loadFailed;
  final bool uncertain;
  final bool savedNotice;
  bool get dirty => saved != null && draft != null && !_same(saved!, draft!);
}

bool _same(WebsitePreferences a, WebsitePreferences b) {
  final left = a.toJson();
  final right = b.toJson();
  return left.keys.every((key) => left[key] == right[key]);
}

final class PreferencesController extends StateNotifier<PreferencesState> {
  PreferencesController(this.repository) : super(const PreferencesState()) {
    unawaited(refresh());
  }
  final PreferencesRepository repository;

  void edit(WebsitePreferences value) {
    if (state.busy || state.uncertain || state.saved == null) return;
    state = PreferencesState(saved: state.saved, draft: value);
  }

  Future<void> refresh() async {
    if (state.busy) return;
    final previous = state;
    state = PreferencesState(
      saved: previous.saved,
      draft: previous.draft,
      busy: true,
      uncertain: previous.uncertain,
    );
    try {
      final result = await repository.load();
      if (!mounted) return;
      state = PreferencesState(
        saved: result,
        draft: previous.uncertain ? previous.draft : result,
      );
    } on Object {
      if (!mounted) return;
      state = PreferencesState(
        saved: previous.saved,
        draft: previous.draft,
        loadFailed: true,
        uncertain: previous.uncertain,
      );
    }
  }

  Future<void> save() async {
    if (state.busy || state.uncertain || !state.dirty) return;
    final previous = state;
    state = PreferencesState(
      saved: previous.saved,
      draft: previous.draft,
      busy: true,
    );
    try {
      await repository.save(previous.saved!, previous.draft!);
      if (!mounted) return;
      state = PreferencesState(
        saved: previous.draft,
        draft: previous.draft,
        savedNotice: true,
      );
    } on Object {
      if (!mounted) return;
      // A failed or malformed response does not prove the server rejected the write.
      state = PreferencesState(
        saved: previous.saved,
        draft: previous.draft,
        uncertain: true,
      );
    }
  }
}

final preferencesControllerProvider =
    StateNotifierProvider.autoDispose<PreferencesController, PreferencesState>((
      ref,
    ) {
      final owner = ref.watch(sessionStateProvider)?.userId;
      if (owner == null || owner.isEmpty) throw StateError('Session required');
      final client = ref.watch(apiClientProvider);
      final unsubscribe = client.observeSessionInvalidation(ref.invalidateSelf);
      ref.onDispose(unsubscribe);
      return PreferencesController(
        PreferencesRepository(
          client,
          owner,
          () => ref.read(sessionStateProvider)?.userId,
        ),
      );
    });
