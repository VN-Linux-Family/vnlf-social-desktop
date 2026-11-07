abstract interface class ReportRepository {
  Future<void> submit({
    required String targetId,
    required String targetType,
    required String reason,
    required String detail,
  });
}
