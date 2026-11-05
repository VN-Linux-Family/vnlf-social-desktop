import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models.dart';
import '../domain/article_comment.dart';

final class CommentActionState {
  CommentActionState({
    Map<String, ArticleComment> changed = const {},
    Set<String> deleted = const {},
    Set<String> pending = const {},
    Map<String, AppFailure> errors = const {},
    this.pinChanged = false,
    this.pinnedId,
  }) : changed = Map.unmodifiable(changed),
       deleted = Set.unmodifiable(deleted),
       pending = Set.unmodifiable(pending),
       errors = Map.unmodifiable(errors);
  final Map<String, ArticleComment> changed;
  final Set<String> deleted, pending;
  final Map<String, AppFailure> errors;
  final bool pinChanged;
  final String? pinnedId;
  CommentActionState copyWith({
    Map<String, ArticleComment>? changed,
    Set<String>? deleted,
    Set<String>? pending,
    Map<String, AppFailure>? errors,
    bool? pinChanged,
    String? pinnedId,
  }) => CommentActionState(
    changed: changed ?? this.changed,
    deleted: deleted ?? this.deleted,
    pending: pending ?? this.pending,
    errors: errors ?? this.errors,
    pinChanged: pinChanged ?? this.pinChanged,
    pinnedId: pinChanged == null ? this.pinnedId : pinnedId,
  );
  List<ArticleComment> apply(Iterable<ArticleComment> source) => [
    for (final comment in {
      ...{for (final c in source) c.id: c},
      ...changed,
    }.values)
      if (!deleted.contains(comment.id))
        pinChanged ? comment.copyWith(pinned: comment.id == pinnedId) : comment,
  ];
}

/// Acknowledged mutations only; disposal on an account change rejects late results.
final class CommentActionsController extends StateNotifier<CommentActionState> {
  CommentActionsController(this._repository, this.articleId)
    : super(CommentActionState());
  final CommentsRepository _repository;
  final String articleId;
  int _revision = 0;
  int get revision => _revision;

  void acceptFresh(int startedAt) {
    if (!mounted || startedAt != _revision || state.pending.isNotEmpty) return;
    state = CommentActionState(errors: state.errors);
  }

  Future<bool> _run(
    ArticleComment comment,
    Future<void> Function() write, {
    bool pin = false,
  }) async {
    if (!mounted ||
        state.pending.contains(comment.id) ||
        (pin && state.pending.contains('@pin'))) {
      return false;
    }
    _revision++;
    final errors = {...state.errors}..remove(comment.id);
    state = state.copyWith(
      pending: {...state.pending, comment.id, if (pin) '@pin'},
      errors: errors,
    );
    try {
      await write();
      return mounted;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          errors: {
            ...state.errors,
            comment.id: error is AppFailure ? error : const TransportFailure(),
          },
        );
      }
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(
          pending: {...state.pending}
            ..remove(comment.id)
            ..remove(pin ? '@pin' : comment.id),
        );
      }
    }
  }

  Future<bool> vote(ArticleComment comment, int value) =>
      _run(comment, () async {
        final vote = await _repository.vote(comment.id, value);
        if (mounted) {
          state = state.copyWith(
            changed: {
              ...state.changed,
              comment.id: (state.changed[comment.id] ?? comment).copyWith(
                voteScore: vote.score,
                viewerVote: vote.value,
              ),
            },
          );
        }
      });
  Future<bool> edit(ArticleComment comment, String content) => _run(
    comment,
    () async {
      if (!comment.canEdit) throw const HttpFailure(403);
      final result = await _repository.edit(comment.id, content.trim());
      if (mounted) {
        state = state.copyWith(changed: {...state.changed, comment.id: result});
      }
    },
  );
  Future<bool> delete(ArticleComment comment) => _run(comment, () async {
    if (!comment.canDelete) throw const HttpFailure(403);
    await _repository.delete(comment.id);
    if (mounted) {
      final changed = {...state.changed}..remove(comment.id);
      state = state.copyWith(
        changed: changed,
        deleted: {...state.deleted, comment.id},
      );
    }
  });
  Future<bool> pin(ArticleComment comment) => _run(comment, () async {
    if (!comment.canPin || comment.parentId != null) {
      throw const HttpFailure(403);
    }
    final id = comment.pinned ? null : comment.id;
    await _repository.pin(articleId, id);
    if (mounted) state = state.copyWith(pinChanged: true, pinnedId: id);
  }, pin: true);
}
