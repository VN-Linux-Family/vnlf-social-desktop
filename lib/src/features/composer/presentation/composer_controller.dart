import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../../../core/request_identity.dart';
import '../../../domain/models.dart' show StorageFailure;
import '../data/composer_recovery.dart';
import '../domain/composer_validation.dart';
import '../domain/composer_draft.dart';
import '../domain/composer_poll.dart';

final class ComposerController extends ChangeNotifier {
  ComposerController({
    required this._repository,
    required this._recovery,
    required this.userId,
    required this._isCurrent,
    this.slot = 'new',
  });
  final ComposerRepository _repository;
  final ComposerRecovery _recovery;
  final String userId;
  final String slot;
  final bool Function() _isCurrent;
  ComposerDraft _draft = const ComposerDraft(id: '', version: 0);
  ComposerDraft get draft => _draft;
  bool dirty = false;
  bool busy = false;
  bool initialized = false;
  bool initializationFailed = false;
  Object? error;
  Object? recoveryError;
  ComposerDraft? conflictingDraft;
  String? _publishKey;
  bool get publishUncertain => _publishKey != null;
  bool _disposed = false;
  int _revision = 0;
  Timer? _localTimer;
  Timer? _saveTimer;
  Future<void> _recoveryTail = Future.value();
  bool get _active => !_disposed && _isCurrent();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _requireActive() {
    if (!_active) throw const HttpFailure(401);
  }

  Future<void> initialize({String? draftId}) async {
    initializationFailed = false;
    error = null;
    try {
      final local = await _recovery.read(userId, slot: slot);
      _requireActive();
      if (local != null && (draftId == null || local.draft.id == draftId)) {
        _draft = local.draft;
        dirty = local.dirty;
        _publishKey = local.publishKey;
      } else if (draftId != null) {
        _draft = await _repository.load(draftId, refresh: true);
      }
    } catch (failure) {
      error = failure;
      initializationFailed = true;
    }
    initialized = true;
    _notify();
  }

  void edit(ComposerDraft value) {
    if (!_active || publishUncertain || initializationFailed) return;
    _draft = value.copyWith(
      id: _draft.id,
      version: _draft.version,
      status: _draft.status,
      slug: _draft.slug,
    );
    dirty = true;
    _revision++;
    error = null;
    _localTimer?.cancel();
    _localTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(flushRecovery()),
    );
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (_active && !busy && dirty) unawaited(save());
    });
    _notify();
  }

  Future<void> flushRecovery({bool strict = false}) async {
    if (initializationFailed) {
      if (strict) throw const ParseFailure('composer.recovery');
      return;
    }
    _localTimer?.cancel();
    final snapshot = RecoveredComposition(_draft, dirty, _publishKey);
    final task = _recoveryTail.then(
      (_) => _recovery.write(userId, snapshot, slot: slot),
    );
    _recoveryTail = task.catchError((Object failure) {
      recoveryError = failure;
      _notify();
    });
    try {
      await task;
      recoveryError = null;
    } catch (_) {
      if (strict) throw const StorageFailure();
    }
  }

  Future<T?> _mutate<T>(Future<T> Function() action) async {
    if (busy || !_active || initializationFailed) return null;
    _saveTimer?.cancel();
    busy = true;
    error = null;
    _notify();
    try {
      return await action();
    } catch (failure) {
      error = failure;
      return null;
    } finally {
      busy = false;
      await flushRecovery();
      _notify();
    }
  }

  Future<void> _ensureId() async {
    _requireActive();
    if (_draft.id.isNotEmpty) return;
    final created = await _repository.create();
    _draft = _draft.copyWith(id: created.id, version: created.version);
    await flushRecovery();
    _requireActive();
  }

  Future<void> _save() async {
    if (publishUncertain) throw const ParseFailure('composer.publishUncertain');
    validateDraft(_draft);
    await _ensureId();
    _requireActive();
    final revision = _revision;
    final snapshot = _draft;
    try {
      final saved = await _repository.save(snapshot);
      _requireActive();
      final acknowledged = snapshot.pollChanged
          ? saved.copyWith(pollDraft: snapshot.pollDraft, pollChanged: true)
          : saved;
      _draft = revision == _revision
          ? acknowledged
          : _draft.copyWith(
              version: saved.version,
              status: saved.status,
              slug: saved.slug,
            );
      conflictingDraft = null;
      dirty = revision != _revision || _draft.pollChanged;
      if (snapshot.pollChanged) {
        final input = snapshot.pollDraft?.validated;
        if (snapshot.pollDraft != null && input == null) return;
        final poll = await _repository.savePoll(snapshot.id, input);
        _requireActive();
        final samePoll =
            snapshot.format == _draft.format &&
            (snapshot.pollDraft == null
                ? _draft.pollDraft == null
                : snapshot.pollDraft!.sameInput(_draft.pollDraft));
        _draft = samePoll
            ? _draft.copyWith(
                poll: poll,
                pollDraft: poll == null
                    ? null
                    : ComposerPollDraft.fromPoll(poll),
                pollChanged: false,
              )
            : _draft.copyWith(poll: poll);
      }
      dirty = revision != _revision || _draft.pollChanged;
    } on HttpFailure catch (failure) {
      if (failure.code == 'ARTICLE_VERSION_CONFLICT' && _active) {
        try {
          conflictingDraft = await _repository.load(snapshot.id, refresh: true);
        } catch (_) {
          /* Keep the original conflict visible. */
        }
      }
      rethrow;
    }
  }

  Future<bool> save() async =>
      await _mutate(() async {
        await _save();
        return !_draft.pollChanged;
      }) ??
      false;

  Future<ComposerDraft?> publish() => _mutate(() async {
    validateDraft(_draft, publishing: true);
    if (dirty || _draft.id.isEmpty) await _save();
    if (dirty) throw const ParseFailure('composer.changedDuringSave');
    validateDraft(_draft, publishing: true);
    _requireActive();
    _publishKey ??= newRequestIdentity();
    await flushRecovery(strict: true);
    _requireActive();
    try {
      final published = await _repository.publish(
        _draft,
        idempotencyKey: _publishKey!,
      );
      _requireActive();
      _draft = published;
      dirty = false;
      _publishKey = null;
      try {
        await _recovery.clear(userId, slot: slot);
      } catch (failure) {
        recoveryError = failure;
      }
      return published;
    } on HttpFailure catch (failure) {
      if (failure.statusCode < 500) _publishKey = null;
      rethrow;
    }
  });

  Future<bool> resolveConflict({required bool keepLocal}) async {
    final remote = conflictingDraft;
    if (busy || remote == null || !_active) return false;
    conflictingDraft = null;
    if (keepLocal) {
      _draft = _draft.copyWith(version: remote.version);
      return save();
    }
    _draft = remote;
    dirty = false;
    error = null;
    _revision++;
    await flushRecovery();
    _notify();
    return true;
  }

  Future<DraftMedia?> upload(
    ComposerUpload file, {
    String placement = 'ATTACHMENT',
  }) => _mutate(() async {
    if (publishUncertain) throw const ParseFailure('composer.publishUncertain');
    if (placement == 'ATTACHMENT' &&
        (_draft.media.length >= 20 ||
            (file.mime.startsWith('video/') &&
                _draft.media.any((m) => m.isVideo)))) {
      throw const ParseFailure('composer.attachments');
    }
    await _ensureId();
    _requireActive();
    final media = await _repository.upload(
      _draft.id,
      file,
      placement: placement,
      format: _draft.format,
    );
    _requireActive();
    _draft = _draft.copyWith(
      assets: Map.unmodifiable({..._draft.assets, media.id: media}),
      media: placement == 'ATTACHMENT'
          ? List.unmodifiable([..._draft.media, media])
          : null,
      coverAssetId: placement == 'COVER' ? media.id : _draft.coverAssetId,
      coverUrl: placement == 'COVER' ? media.url : _draft.coverUrl,
    );
    dirty = true;
    _revision++;
    return media;
  });

  Future<DraftMedia?> refreshMedia(DraftMedia media) => _mutate(() async {
    _requireActive();
    final updated = await _repository.refreshMedia(_draft.id, media);
    _requireActive();
    _draft = _draft.copyWith(
      assets: Map.unmodifiable({..._draft.assets, updated.id: updated}),
      media: List.unmodifiable([
        for (final item in _draft.media)
          if (item.id == updated.id) updated else item,
      ]),
      coverUrl: _draft.coverAssetId == updated.id
          ? updated.url
          : _draft.coverUrl,
    );
    return updated;
  });

  Future<bool> removeMedia(String assetId) async =>
      await _mutate(() async {
        if (publishUncertain) {
          throw const ParseFailure('composer.publishUncertain');
        }
        _requireActive();
        await _repository.deleteMedia(_draft.id, assetId);
        _requireActive();
        Map<String, dynamic> withoutAsset(Map<String, dynamic> node) => {
          ...node,
          if (node['content'] is List)
            'content': [
              for (final child
                  in (node['content'] as List)
                      .whereType<Map<String, dynamic>>())
                if (!(child['type'] == 'image' &&
                    child['attrs'] is Map &&
                    child['attrs']['assetId'] == assetId))
                  withoutAsset(child),
            ],
        };
        final assets = {..._draft.assets}..remove(assetId);
        _draft = _draft.copyWith(
          assets: Map.unmodifiable(assets),
          media: List.unmodifiable(_draft.media.where((m) => m.id != assetId)),
          document: withoutAsset(_draft.document),
          coverAssetId: _draft.coverAssetId == assetId
              ? null
              : _draft.coverAssetId,
          coverUrl: _draft.coverAssetId == assetId ? null : _draft.coverUrl,
          coverAlt: _draft.coverAssetId == assetId ? '' : _draft.coverAlt,
        );
        dirty = true;
        _revision++;
        return true;
      }) ??
      false;

  @override
  void dispose() {
    _localTimer?.cancel();
    _saveTimer?.cancel();
    unawaited(flushRecovery());
    _disposed = true;
    super.dispose();
  }
}
