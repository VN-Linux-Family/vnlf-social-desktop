/// Recovery state for one account's feedback submission.
/// An uncertain upload occupies at least one additional, unidentified slot.
final class FeedbackDraft {
  FeedbackDraft({
    required this.ownerId,
    required this.submissionId,
    required this.kind,
    required this.detail,
    required this.contact,
    required this.pagePath,
    required List<String> assetIds,
    required this.uploadUncertain,
    required this.submissionUncertain,
    this.pendingAssetId,
    this.submissionConfirmed = false,
    Map<String, String> assetNames = const {},
  }) : assetIds = List.unmodifiable(assetIds),
       assetNames = Map.unmodifiable(assetNames);

  final String ownerId;
  final String submissionId;
  final String kind;
  final String detail;
  final String contact;
  final String pagePath;
  final List<String> assetIds;
  final Map<String, String> assetNames;
  final bool uploadUncertain;
  final bool submissionUncertain;
  final bool submissionConfirmed;
  /// Known asset whose upload, completion, or deletion needs reconciliation.
  /// Null with uploadUncertain means the presign result itself is unknown.
  final String? pendingAssetId;
}
