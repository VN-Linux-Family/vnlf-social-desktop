import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/feedback/data/feedback_draft_controller.dart';
import 'package:vnlfsocialapp/src/features/feedback/data/feedback_draft_store.dart';
import 'package:vnlfsocialapp/src/features/feedback/data/feedback_media_repository.dart';
import 'package:vnlfsocialapp/src/features/feedback/domain/feedback_draft.dart';

FeedbackDraft initial() => FeedbackDraft(
  ownerId: 'owner', submissionId: '12345678-1234-4234-8234-123456789abc',
  kind: 'BUG', detail: 'This is a sufficiently long report.', contact: '',
  pagePath: '/feed', assetIds: [], uploadUncertain: false, submissionUncertain: false,
);

FeedbackMediaFile file() => FeedbackMediaFile(
  name: 'a.png', mime: 'image/png', length: 1, openRead: () => Stream.value([1]),
);

void main() {
  test('lost presign remains locked after reopening', () async {
    var calls = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
      transport: (_) async { calls++; throw const TransportFailure(); });
    final store = FeedbackDraftStore(_Memory());
    final media = FeedbackMediaRepository(client);
    Future<FeedbackDraftController> open() => FeedbackDraftController.open(
      store: store, media: media, client: client, currentOwner: () => 'owner', initial: initial(),
    );
    final controller = await open();
    await expectLater(controller.attach(file()), throwsA(isA<TransportFailure>()));
    final recovered = await open();
    expect(recovered.draft.uploadUncertain, isTrue);
    expect(recovered.draft.pendingAssetId, isNull);
    await expectLater(recovered.attach(file()), throwsA(isA<StateError>()));
    expect(calls, 1);
  });

  test('uncertain submission freezes exact retry across reopen', () async {
    final bodies = <String>[];
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
      transport: (request) async {
        bodies.add(request.body!);
        if (bodies.length == 1) throw const TransportFailure();
        return ApiResponse(statusCode: 200, body: jsonEncode({
          'submissionId': 'server-id', 'reference': 'ref',
          'rewardQueued': false, 'duplicate': true,
        }));
      });
    final store = FeedbackDraftStore(_Memory());
    final media = FeedbackMediaRepository(client);
    Future<FeedbackDraftController> open() => FeedbackDraftController.open(
      store: store, media: media, client: client, currentOwner: () => 'owner', initial: initial(),
    );
    await expectLater((await open()).submit(), throwsA(isA<TransportFailure>()));
    final recovered = await open();
    await expectLater(recovered.edit(kind: 'BUG', detail: 'changed', contact: '', pagePath: '/'),
      throwsA(isA<StateError>()));
    await recovered.submit();
    expect(bodies[1], bodies[0]);
    expect(await store.read('owner'), isNull);
    await expectLater(recovered.submit(), throwsA(isA<StateError>()));
  });

  test('account change blocks mutation before transport', () async {
    var owner = 'owner';
    var calls = 0;
    final client = ApiClient(hostKey: Object(), transport: (_) async {
      calls++;
      return ApiResponse(statusCode: 200, body: '{}');
    });
    final controller = await FeedbackDraftController.open(
      store: FeedbackDraftStore(_Memory()), media: FeedbackMediaRepository(client),
      client: client, currentOwner: () => owner, initial: initial(),
    );
    owner = 'other';
    await expectLater(controller.attach(file()), throwsA(isA<HttpFailure>()));
    expect(calls, 0);
  });
}

final class _Memory implements SessionStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async { values[key] = value; }
  @override
  Future<void> delete(String key) async { values.remove(key); }
}
