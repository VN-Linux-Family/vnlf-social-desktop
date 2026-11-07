import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/feedback/data/feedback_draft_store.dart';
import 'package:vnlfsocialapp/src/features/feedback/domain/feedback_draft.dart';

FeedbackDraft draft(String owner, {bool uncertain = false}) => FeedbackDraft(
  ownerId: owner,
  submissionId: '12345678-1234-4234-8234-123456789abc',
  kind: 'BUG',
  detail: 'Tiếng Việt: ặ ữ ờ ẫ ệ',
  contact: 'contact',
  pagePath: '/feed',
  assetIds: ['asset-1'],
  uploadUncertain: uncertain,
  submissionUncertain: uncertain,
);

void main() {
  test('round trips metadata and isolates account owners', () async {
    final storage = _Memory();
    final store = FeedbackDraftStore(storage);
    await store.write('account/a', draft('account/a', uncertain: true));
    await store.write('account', draft('account'));
    final recovered = (await store.read('account/a'))!;
    expect(recovered.detail, 'Tiếng Việt: ặ ữ ờ ẫ ệ');
    expect(recovered.assetIds, ['asset-1']);
    expect(recovered.uploadUncertain, isTrue);
    expect(recovered.submissionUncertain, isTrue);
    expect((await store.read('account'))!.uploadUncertain, isFalse);
    await store.clear('account');
    expect(await store.read('account'), isNull);
    expect(await store.read('account/a'), isNotNull);
    final encoded = storage.values.values.single;
    expect(encoded, isNot(contains('uploadUrl')));
    expect(encoded, isNot(contains('headers')));
  });

  test('rejects mismatched owners and damaged recovery records', () async {
    final storage = _Memory();
    final store = FeedbackDraftStore(storage);
    expect(() => store.write('other', draft('owner')), throwsA(isA<ParseFailure>()));
    expect(() => store.write('', draft('')), throwsA(isA<ParseFailure>()));
    await store.write('owner', draft('owner'));
    final key = storage.values.keys.single;
    final value = jsonDecode(storage.values[key]!) as Map<String, dynamic>;
    value['ownerId'] = 'other';
    storage.values[key] = jsonEncode(value);
    await expectLater(store.read('owner'), throwsA(isA<ParseFailure>()));
    value['ownerId'] = 'owner';
    value.remove('uploadUncertain');
    storage.values[key] = jsonEncode(value);
    await expectLater(store.read('owner'), throwsA(isA<ParseFailure>()));
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
