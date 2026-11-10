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
    this.loadingMore = false,
    this.error,
  });
  final ProjectFilters filters;

  /// What the list shows. The previous results stay while new filters
  /// load, dimmed, like the website's `keepPreviousData`.
  final List<ProjectItem> items;
  final List<ProjectFacet> types;
  final List<ProjectFacet> languages;
  final String? nextCursor;

  /// A first page is on its way.
  final bool loading;

  /// "Xem thêm" is on its way.
  final bool loadingMore;

  /// The last first page failed; the list is then empty.
  final AppFailure? error;

  ProjectDirectoryState copyWith({
    ProjectFilters? filters,
    bool? loading,
    bool? loadingMore,
  }) => ProjectDirectoryState(
    filters: filters ?? this.filters,
    items: items,
    types: types,
    languages: languages,
    nextCursor: nextCursor,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
  );
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

  /// The search box: the list follows 300ms after the last keystroke.
  void search(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setFilters(state.filters.copyWith(query: text.trim())),
    );
  }

  void setFilters(ProjectFilters filters) {
    if (filters == state.filters) return;
    state = state.copyWith(filters: filters);
    load();
  }

  void resetSession() {
    _debounce?.cancel();
    state = ProjectDirectoryState(filters: state.filters);
    load(refresh: true);
  }

  Future<void> load({bool more = false, bool refresh = false}) async {
    if (more) {
      if (state.loading || state.loadingMore || state.nextCursor == null) {
        return;
      }
    } else {
      _cursors.clear();
    }
    final cursor = more ? state.nextCursor : null;
    final generation = ++_generation;
    final previous = state;
    state = more
        ? previous.copyWith(loadingMore: true)
        : previous.copyWith(loading: true, loadingMore: false);
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
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      if (more) {
        // The website keeps the list and the button, and says nothing. A
        // server that repeats a cursor would loop, so paging stops there.
        state = error is ParseFailure
            ? ProjectDirectoryState(
                filters: previous.filters,
                items: previous.items,
                types: previous.types,
                languages: previous.languages,
              )
            : previous.copyWith(loadingMore: false);
        return;
      }
      state = ProjectDirectoryState(
        filters: previous.filters,
        types: previous.types,
        languages: previous.languages,
        error: error is AppFailure ? error : const TransportFailure(),
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
