import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../core/session_storage_contract.dart';
import '../domain/feedback_draft.dart';

/// Stores account-owned draft metadata only. Guest recovery is unsupported:
/// there is no persistent account identity with which to verify its owner.
final class FeedbackDraftStore {
  const FeedbackDraftStore(this._storage);
  final SessionStorage _storage;

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _assetId = RegExp(r'^[a-zA-Z0-9_-]{1,80}$');

  String _key(String ownerId) {
    if (ownerId.isEmpty) throw const ParseFailure('feedback.draft.owner');
    return 'vnlf.feedback.draft.${Uri.encodeComponent(ownerId)}';
  }

  void _validate(FeedbackDraft draft, String ownerId) {
    if (ownerId.isEmpty ||
        draft.ownerId != ownerId ||
        !_uuid.hasMatch(draft.submissionId) ||
        (draft.kind != 'FEEDBACK' && draft.kind != 'BUG') ||
        draft.assetIds.length > 5 ||
        draft.assetIds.toSet().length != draft.assetIds.length ||
        draft.assetIds.any((id) => !_assetId.hasMatch(id)) ||
        draft.assetNames.entries.any(
          (entry) =>
              !draft.assetIds.contains(entry.key) ||
              entry.value.isEmpty ||
              entry.value.length > 255,
        ) ||
        (draft.submissionConfirmed && !draft.submissionUncertain) ||
        (draft.pendingAssetId != null &&
            (!draft.uploadUncertain ||
                !draft.assetIds.contains(draft.pendingAssetId))) ||
        (draft.uploadUncertain &&
            draft.pendingAssetId == null &&
            draft.assetIds.length >= 5)) {
      throw const ParseFailure('feedback.draft');
    }
  }

  Future<FeedbackDraft?> read(String ownerId) async {
    final raw = await _storage.read(_key(ownerId));
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value['schema'] != 1) throw const FormatException();
      final draft = FeedbackDraft(
        ownerId: value['ownerId'] as String,
        submissionId: value['submissionId'] as String,
        kind: value['kind'] as String,
        detail: value['detail'] as String,
        contact: value['contact'] as String,
        pagePath: value['pagePath'] as String,
        assetIds: (value['assetIds'] as List).cast<String>(),
        assetNames: value['assetNames'] == null
            ? const {}
            : (value['assetNames'] as Map).cast<String, String>(),
        uploadUncertain: value['uploadUncertain'] as bool,
        submissionUncertain: value['submissionUncertain'] as bool,
        submissionConfirmed: value['submissionConfirmed'] == null
            ? false
            : value['submissionConfirmed'] as bool,
        pendingAssetId: value['pendingAssetId'] as String?,
      );
      _validate(draft, ownerId);
      return draft;
    } catch (_) {
      throw const ParseFailure('feedback.draft');
    }
  }

  Future<void> write(String ownerId, FeedbackDraft draft) {
    final key = _key(ownerId);
    _validate(draft, ownerId);
    return _storage.write(
      key,
      jsonEncode({
        'schema': 1,
        'ownerId': draft.ownerId,
        'submissionId': draft.submissionId,
        'kind': draft.kind,
        'detail': draft.detail,
        'contact': draft.contact,
        'pagePath': draft.pagePath,
        'assetIds': draft.assetIds,
        'assetNames': draft.assetNames,
        'uploadUncertain': draft.uploadUncertain,
        'submissionUncertain': draft.submissionUncertain,
        'submissionConfirmed': draft.submissionConfirmed,
        'pendingAssetId': draft.pendingAssetId,
      }),
    );
  }

  Future<void> clear(String ownerId) => _storage.delete(_key(ownerId));
}
