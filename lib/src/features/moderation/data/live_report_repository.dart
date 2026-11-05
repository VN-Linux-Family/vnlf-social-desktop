import 'dart:convert';

import '../../../core/api_client.dart';
import '../domain/report_repository.dart';

final class LiveReportRepository implements ReportRepository {
  const LiveReportRepository(this._client);
  final ApiClient _client;
  @override
  Future<void> submit({
    required String targetId,
    required String targetType,
    required String reason,
    required String detail,
  }) async {
    if (reason.trim().isEmpty || reason.length > 60 || detail.length > 2000) {
      throw const ParseFailure('report.input');
    }
    await _client.request<void>(
      'POST',
      '/api/v1/reports',
      body: jsonEncode({
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason.trim(),
        'detail': detail.trim(),
      }),
      decode: (json) {
        if (json['reportId'] is! String ||
            (json['reportId'] as String).isEmpty) {
          throw const ParseFailure('report.reportId');
        }
      },
    );
  }
}
