import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/feedback/data/feedback_media_repository.dart';

const submission = '12345678-1234-4234-8234-123456789abc';

FeedbackMediaFile file({String mime = 'image/png', int length = 2}) =>
    FeedbackMediaFile(name: 'test.png', mime: mime, length: length,
        openRead: () => Stream.value([1, 2]));

void main() {
  test('presigns, transfers, completes and deletes the same asset', () async {
    final requests = <ApiRequest>[];
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
        transport: (request) async {
      requests.add(request);
      if (request.path.endsWith('/presign')) {
        return ApiResponse(statusCode: 200, body: jsonEncode({
          'assetId': 'asset-1', 'uploadUrl': 'https://storage.invalid/object',
          'expiresIn': 600, 'headers': {'content-type': 'image/png'}
        }));
      }
      if (request.method == 'DELETE') {
        return ApiResponse(statusCode: 200, body: '{"ok":true}');
      }
      return ApiResponse(statusCode: 200, body: '{"assetId":"asset-1","status":"READY"}');
    });
    var transfers = 0;
    final repository = FeedbackMediaRepository(client, upload: (uri, input, headers) async {
      transfers++;
      expect(uri.scheme, 'https');
      expect(headers['content-type'], 'image/png');
      expect(await input.openRead().expand((chunk) => chunk).toList(), [1, 2]);
    });
    final pending = await repository.presign(submissionId: submission, kind: 'BUG', file: file());
    await repository.upload(pending);
    await repository.complete(pending);
    await repository.delete(pending);
    expect(transfers, 1);
    expect(jsonDecode(requests[0].body!), {
      'clientSubmissionId': submission, 'kind': 'BUG', 'fileName': 'test.png',
      'mime': 'image/png', 'size': 2,
    });
    expect(jsonDecode(requests[1].body!), {'clientSubmissionId': submission});
    expect(requests[2].query, {'clientSubmissionId': submission});
  });

  test('rejects unsupported and oversized files before presign', () async {
    var calls = 0;
    final client = ApiClient(hostKey: Object(), transport: (_) async {
      calls++;
      return ApiResponse(statusCode: 200, body: '{}');
    });
    final repository = FeedbackMediaRepository(client);
    for (final input in [file(mime: 'image/svg+xml'), file(length: 10 * 1024 * 1024 + 1), file(mime: 'video/mp4', length: 50 * 1024 * 1024 + 1)]) {
      await expectLater(repository.presign(submissionId: submission, file: input), throwsA(isA<ParseFailure>()));
    }
    expect(calls, 0);
  });

  test('invalid completion and delete acknowledgements fail', () async {
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
        transport: (request) async => ApiResponse(statusCode: 200, body:
          request.path.endsWith('/presign')
            ? '{"assetId":"asset-1","uploadUrl":"https://storage.invalid/a","expiresIn":600,"headers":{}}'
            : request.method == 'DELETE' ? '{"ok":false}' : '{"assetId":"other","status":"READY"}'));
    final repository = FeedbackMediaRepository(client);
    final pending = await repository.presign(submissionId: submission, file: file());
    await expectLater(repository.complete(pending), throwsA(isA<ParseFailure>()));
    await expectLater(repository.delete(pending), throwsA(isA<ParseFailure>()));
  });

  test('account change blocks transfer and later completion', () async {
    var calls = 0;
    var transfers = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
        transport: (_) async {
      calls++;
      return ApiResponse(statusCode: 200, body: '{"assetId":"asset-1","uploadUrl":"https://storage.invalid/a","expiresIn":600,"headers":{}}');
    });
    final repository = FeedbackMediaRepository(client, upload: (_, __, ___) async { transfers++; });
    final pending = await repository.presign(submissionId: submission, file: file());
    client.invalidateSession();
    await expectLater(repository.upload(pending), throwsA(isA<HttpFailure>()));
    await expectLater(repository.complete(pending), throwsA(isA<HttpFailure>()));
    await expectLater(repository.delete(pending), throwsA(isA<HttpFailure>()));
    expect(calls, 1);
    expect(transfers, 0);
  });

  test('session invalidation during streaming prevents completion', () async {
    final requests = <ApiRequest>[];
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
        transport: (request) async {
      requests.add(request);
      return ApiResponse(statusCode: 200, body: '{"assetId":"asset-1","uploadUrl":"https://storage.invalid/a","expiresIn":600,"headers":{}}');
    });
    final repository = FeedbackMediaRepository(client, upload: (_, input, __) async {
      client.invalidateSession();
      await input.openRead().drain<void>();
    });
    final pending = await repository.presign(submissionId: submission, file: file());
    await expectLater(repository.upload(pending), throwsA(isA<HttpFailure>()));
    await expectLater(repository.complete(pending), throwsA(isA<HttpFailure>()));
    expect(requests.length, 1);
  });

  test('rejects unsafe presign responses and never retries mutations', () async {
    var calls = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
        transport: (_) async {
      calls++;
      return ApiResponse(statusCode: 503, body: '{}');
    });
    final repository = FeedbackMediaRepository(client);
    await expectLater(repository.presign(submissionId: submission, file: file()), throwsA(isA<HttpFailure>()));
    expect(calls, 1);

    final unsafeClient = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
        transport: (_) async => ApiResponse(statusCode: 200, body:
          '{"assetId":"asset-1","uploadUrl":"https://user@storage.invalid/a","expiresIn":600,"headers":{}}'));
    await expectLater(FeedbackMediaRepository(unsafeClient).presign(submissionId: submission, file: file()), throwsA(isA<ParseFailure>()));
  });

}
