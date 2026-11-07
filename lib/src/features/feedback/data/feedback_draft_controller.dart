import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../core/request_identity.dart';
import '../../../domain/models.dart' show StorageFailure;
import '../domain/feedback_draft.dart';
import 'feedback_draft_store.dart';
import 'feedback_media_repository.dart';

/// The server accepted the submission, but local recovery cleanup failed.
final class FeedbackConfirmedCleanupFailure implements Exception {
  const FeedbackConfirmedCleanupFailure();
}

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
    Map<String, String>? assetNames,
    bool? uploadUncertain,
    bool? submissionUncertain,
    bool? submissionConfirmed,
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
    assetNames: assetNames ?? draft.assetNames,
    uploadUncertain: uploadUncertain ?? draft.uploadUncertain,
    submissionUncertain: submissionUncertain ?? draft.submissionUncertain,
    submissionConfirmed: submissionConfirmed ?? draft.submissionConfirmed,
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
    if (file.name.isEmpty || file.name.length > 255 ||
        !feedbackMediaMimes.contains(file.mime) || file.length < 1 ||
        file.length > (file.mime.startsWith('video/') ? feedbackVideoLimit : feedbackImageLimit)) {
      throw const ParseFailure('feedback.upload.file');
    }
    // Written before presign: an interrupted response may have allocated a slot.
    await _save(_copy(uploadUncertain: true));
    _check();
    PendingFeedbackMedia pending;
    try {
      pending = await _media.presign(
        submissionId: draft.submissionId, kind: draft.kind, file: file,
      );
    } on HttpFailure catch (failure) {
      // These source-defined errors occur before the asset insert. Unknown
      // responses, including gateway errors, cannot prove that no row exists.
      const preAllocation = {
        'FEEDBACK_MEDIA_TYPE_INVALID': 400,
        'FEEDBACK_MEDIA_TOO_LARGE': 400,
        'FEEDBACK_SUBMISSION_CLOSED': 409,
        'FEEDBACK_MEDIA_LIMIT': 409,
      };
      if (preAllocation[failure.code] == failure.statusCode) {
        _check();
        await _save(_copy(uploadUncertain: false));
      }
      rethrow;
    }
    _pending = pending;
    _check();
    await _save(_copy(
      assetIds: [...draft.assetIds, pending.assetId],
      assetNames: {...draft.assetNames, pending.assetId: file.name},
      pendingAssetId: pending.assetId,
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
        (draft.uploadUncertain && draft.pendingAssetId != null && draft.pendingAssetId != assetId)) {
      throw StateError('Feedback attachment cannot be deleted');
    }
    final unknownPresign = draft.uploadUncertain && draft.pendingAssetId == null;
    if (!unknownPresign) {
      await _save(_copy(uploadUncertain: true, pendingAssetId: assetId));
    } else {
      await _save(draft);
    }
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
      assetNames: Map.of(draft.assetNames)..remove(assetId),
      uploadUncertain: unknownPresign, clearPending: true,
    ));
    _pending = null;
  });

  /// Called only after the user accepts that an unidentified asset may remain.
  Future<void> restartAfterUnknownPresign() => _exclusive(() async {
    if (!draft.uploadUncertain || draft.pendingAssetId != null ||
        draft.assetIds.isNotEmpty || draft.submissionUncertain) {
      throw StateError('Unknown upload cannot be discarded yet');
    }
    await _save(FeedbackDraft(
      ownerId: draft.ownerId, submissionId: newRequestIdentity(), kind: draft.kind,
      detail: draft.detail, contact: draft.contact, pagePath: draft.pagePath,
      assetIds: const [], uploadUncertain: false, submissionUncertain: false,
    ));
  });

  Future<void> submit() => _exclusive(() async {
    if (draft.submissionConfirmed || draft.uploadUncertain || draft.detail.trim().length < 20 ||
        draft.detail.trim().length > 4000) {
      throw StateError('Feedback draft cannot be submitted');
    }
    // The persisted fields constitute the immutable retry payload.
    final wasUncertain = draft.submissionUncertain;
    if (!wasUncertain) await _save(_copy(submissionUncertain: true));
    _check();
    Map<String, dynamic> response;
    try {
      response = await _client.request<Map<String, dynamic>>(
      'POST', '/api/v1/feedback', body: jsonEncode({
        'clientSubmissionId': draft.submissionId,
        'kind': draft.kind,
        'detail': draft.detail.trim(),
        'pagePath': draft.pagePath,
        'assetIds': draft.assetIds,
      }),
      );
    } on HttpFailure catch (failure) {
      // A later rejection cannot resolve an earlier uncertain attempt.
      if (!wasUncertain && failure.statusCode >= 400 &&
          failure.statusCode < 500 && failure.statusCode != 408) {
        _check();
        await _save(_copy(submissionUncertain: false));
      }
      rethrow;
    }
    _check();
    if (response['submissionId'] is! String ||
        (response['submissionId'] as String).isEmpty ||
        response['reference'] is! String || (response['reference'] as String).isEmpty ||
        response['rewardQueued'] is! bool || response['duplicate'] is! bool) {
      throw const ParseFailure('feedback.acknowledgment');
    }
    try {
      // Preserve proof of success before attempting cleanup. If even this
      // write fails, the previous uncertain record still retains the same ID.
      await _save(_copy(submissionConfirmed: true));
      await _store.clear(draft.ownerId);
      _check();
      _done = true;
    } catch (_) {
      _done = true;
      throw const FeedbackConfirmedCleanupFailure();
    }
  });

  Future<void> clearConfirmed() async {
    if (!draft.submissionConfirmed) return;
    _scope.ensureCurrent();
    if (_currentOwner() != draft.ownerId) throw const HttpFailure(401);
    await _store.clear(draft.ownerId);
  }
}
