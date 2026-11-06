import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../data/project_directory_repository.dart';
import '../domain/project_directory.dart';

final projectDirectoryRepositoryProvider = Provider<ProjectDirectoryRepository>(
  (ref) => ApiProjectDirectoryRepository(ref.watch(apiClientProvider)),
);
final projectDirectoryProvider =
    StateNotifierProvider.autoDispose<
      ProjectDirectoryController,
      ProjectDirectoryState
    >((ref) {
      final controller = ProjectDirectoryController(
        ref.watch(projectDirectoryRepositoryProvider),
      );
      final stop = ref
          .watch(apiClientProvider)
          .observeSessionInvalidation(controller.resetSession);
      ref.onDispose(stop);
      return controller;
    });

final class ProjectDirectoryState {
  const ProjectDirectoryState({
    this.filters = const ProjectFilters(),
    this.items = const [],
    this.types = const [],
    this.languages = const [],
    this.nextCursor,
    this.loading = false,
    this.error,
  });
  final ProjectFilters filters;
  final List<ProjectItem> items;
  final List<ProjectFacet> types;
  final List<ProjectFacet> languages;
  final String? nextCursor;
  final bool loading;
  final AppFailure? error;
}

final class ProjectDirectoryController
    extends StateNotifier<ProjectDirectoryState> {
  ProjectDirectoryController(this.repository)
    : super(const ProjectDirectoryState()) {
    load();
  }
  final ProjectDirectoryRepository repository;
  int _generation = 0;
  final Set<String> _cursors = {};
  Timer? _debounce;
  String? _pendingText;

  void search(String text) {
    _debounce?.cancel();
    _pendingText = text;
    // Invalidate immediately, so an old response cannot appear while typing.
    _generation++;
    state = ProjectDirectoryState(
      filters: state.filters,
      items: state.items,
      types: state.types,
      languages: state.languages,
    );
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setFilters(state.filters.copyWith(query: text.trim())),
    );
  }

  void setFilters(ProjectFilters filters) {
    _debounce?.cancel();
    final effective = filters.copyWith(
      query: _pendingText?.trim() ?? filters.query,
    );
    _pendingText = null;
    state = ProjectDirectoryState(
      filters: effective,
      types: state.types,
      languages: state.languages,
    );
    load();
  }

  void resetSession() {
    _debounce?.cancel();
    _pendingText = null;
    state = ProjectDirectoryState(filters: state.filters);
    load(refresh: true);
  }

  Future<void> load({bool more = false, bool refresh = false}) async {
    if (more && (state.loading || state.nextCursor == null)) return;
    final cursor = more ? state.nextCursor : null;
    if (!more) _cursors.clear();
    final generation = ++_generation;
    final previous = state;
    state = ProjectDirectoryState(
      filters: previous.filters,
      items: previous.items,
      types: previous.types,
      languages: previous.languages,
      nextCursor: previous.nextCursor,
      loading: true,
    );
    try {
      final result = await repository.fetch(
        previous.filters,
        cursor: cursor,
        refresh: refresh,
      );
      if (!mounted || generation != _generation) return;
      final next = result.page.nextCursor;
      if (cursor != null) _cursors.add(cursor);
      if (next != null && (next == cursor || _cursors.contains(next))) {
        throw const ParseFailure('nextCursor');
      }
      state = ProjectDirectoryState(
        filters: previous.filters,
        items: List.unmodifiable(
          {
            for (final item in [
              if (more) ...previous.items,
              ...result.page.items,
            ])
              item.id: item,
          }.values,
        ),
        types: more ? previous.types : result.types,
        languages: more ? previous.languages : result.languages,
        nextCursor: next,
      );
    } on AppFailure catch (error) {
      if (!mounted || generation != _generation) return;
      state = ProjectDirectoryState(
        filters: previous.filters,
        items: previous.items,
        types: previous.types,
        languages: previous.languages,
        nextCursor: previous.nextCursor,
        error: error,
      );
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = ProjectDirectoryState(
        filters: previous.filters,
        items: previous.items,
        types: previous.types,
        languages: previous.languages,
        nextCursor: previous.nextCursor,
        error: const TransportFailure(),
      );
    }
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    super.dispose();
  }
}
