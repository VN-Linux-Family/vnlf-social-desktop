import 'dart:convert';

import '../../../core/api_client.dart';
import '../domain/feedback_draft.dart';
import 'feedback_draft_store.dart';
import 'feedback_media_repository.dart';

/// Coordinates a single authenticated draft. The caller supplies the current
/// account ID, and must discard this instance when its session changes.
final class FeedbackDraftController {
  FeedbackDraftController._(
    this._store,
    this._media,
    this._client,
    this._currentOwner,
    this._scope,
    this._recoverySession,
    this.draft,
  );

  final FeedbackDraftStore _store;
  final FeedbackMediaRepository _media;
  final ApiClient _client;
  final String? Function() _currentOwner;
  final ApiSessionScope _scope;
  final FeedbackMediaRecoverySession _recoverySession;
  FeedbackDraft draft;
  bool _busy = false;
  bool _storageFailed = false;
  bool _done = false;
  PendingFeedbackMedia? _pending;

  static Future<FeedbackDraftController> open({
    required FeedbackDraftStore store,
    required FeedbackMediaRepository media,
    required ApiClient client,
    required String? Function() currentOwner,
    required FeedbackDraft initial,
  }) async {
    final scope = client.captureSession();
    final recovery = media.captureRecoverySession();
    if (initial.ownerId.isEmpty || currentOwner() != initial.ownerId) {
      throw const HttpFailure(401);
    }
    final existing = await store.read(initial.ownerId);
    scope.ensureCurrent();
    if (currentOwner() != initial.ownerId) throw const HttpFailure(401);
    final controller = FeedbackDraftController._(
      store, media, client, currentOwner, scope, recovery, existing ?? initial,
    );
    if (existing == null) await controller._save(initial);
    return controller;
  }

  void _check() {
    _scope.ensureCurrent();
    if (_currentOwner() != draft.ownerId) throw const HttpFailure(401);
    if (_storageFailed) throw const StorageFailure();
    if (_done) throw StateError('Feedback was submitted');
  }

  Future<void> _save(FeedbackDraft next) async {
    _check();
    draft = next;
    try {
      await _store.write(next.ownerId, next);
    } catch (_) {
      _storageFailed = true;
      rethrow;
    }
    _check();
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    _check();
    if (_busy) throw StateError('Feedback operation already in progress');
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  FeedbackDraft _copy({
    String? kind,
    String? detail,
    String? contact,
    String? pagePath,
    List<String>? assetIds,
    bool? uploadUncertain,
    bool? submissionUncertain,
    String? pendingAssetId,
    bool clearPending = false,
  }) => FeedbackDraft(
    ownerId: draft.ownerId,
    submissionId: draft.submissionId,
    kind: kind ?? draft.kind,
    detail: detail ?? draft.detail,
    contact: contact ?? draft.contact,
    pagePath: pagePath ?? draft.pagePath,
    assetIds: assetIds ?? draft.assetIds,
    uploadUncertain: uploadUncertain ?? draft.uploadUncertain,
    submissionUncertain: submissionUncertain ?? draft.submissionUncertain,
    pendingAssetId: clearPending ? null : pendingAssetId ?? draft.pendingAssetId,
  );

  Future<void> edit({
    required String kind,
    required String detail,
    required String contact,
    required String pagePath,
  }) => _exclusive(() async {
    if (draft.submissionUncertain || draft.uploadUncertain ||
        (draft.assetIds.isNotEmpty && kind != draft.kind)) {
      throw StateError('Feedback draft is locked');
    }
    await _save(_copy(kind: kind, detail: detail, contact: contact, pagePath: pagePath));
  });

  Future<void> attach(FeedbackMediaFile file) => _exclusive(() async {
    if (draft.submissionUncertain || draft.uploadUncertain || draft.assetIds.length >= 5) {
      throw StateError('Feedback attachment is locked');
    }
    // Written before presign: an interrupted response may have allocated a slot.
    await _save(_copy(uploadUncertain: true));
    _check();
    final pending = await _media.presign(
      submissionId: draft.submissionId, kind: draft.kind, file: file,
    );
    _pending = pending;
    _check();
    await _save(_copy(
      assetIds: [...draft.assetIds, pending.assetId], pendingAssetId: pending.assetId,
    ));
    _check();
    await _media.upload(pending);
    _check();
    await _media.complete(pending);
    _check();
    await _save(_copy(uploadUncertain: false, clearPending: true));
    _pending = null;
  });

  Future<void> deleteAsset(String assetId) => _exclusive(() async {
    if (draft.submissionUncertain || !draft.assetIds.contains(assetId) ||
        (draft.uploadUncertain && draft.pendingAssetId != assetId)) {
      throw StateError('Feedback attachment cannot be deleted');
    }
    await _save(_copy(uploadUncertain: true, pendingAssetId: assetId));
    _check();
    if (_pending?.assetId == assetId) {
      await _media.delete(_pending!);
    } else {
      await _media.deleteRecovered(
        assetId: assetId, submissionId: draft.submissionId, session: _recoverySession,
      );
    }
    _check();
    await _save(_copy(
      assetIds: draft.assetIds.where((id) => id != assetId).toList(),
      uploadUncertain: false, clearPending: true,
    ));
    _pending = null;
  });

  Future<void> submit() => _exclusive(() async {
    if (draft.uploadUncertain || draft.detail.trim().length < 20 ||
        draft.detail.trim().length > 4000) {
      throw StateError('Feedback draft cannot be submitted');
    }
    // The persisted fields constitute the immutable retry payload.
    if (!draft.submissionUncertain) await _save(_copy(submissionUncertain: true));
    _check();
    final response = await _client.request<Map<String, dynamic>>(
      'POST', '/api/v1/feedback', body: jsonEncode({
        'clientSubmissionId': draft.submissionId,
        'kind': draft.kind,
        'detail': draft.detail.trim(),
        'pagePath': draft.pagePath,
        'assetIds': draft.assetIds,
      }),
    );
    _check();
    if (response['submissionId'] is! String ||
        (response['submissionId'] as String).isEmpty ||
        response['reference'] is! String || (response['reference'] as String).isEmpty ||
        response['rewardQueued'] is! bool || response['duplicate'] is! bool) {
      throw const ParseFailure('feedback.acknowledgment');
    }
    try {
      await _store.clear(draft.ownerId);
    } catch (_) {
      _storageFailed = true;
      rethrow;
    }
    _check();
    _done = true;
  });
}
