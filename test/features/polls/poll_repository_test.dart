import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/polls/domain/poll_models.dart';
import 'package:vnlfsocialapp/src/features/polls/data/poll_dto.dart';
import 'package:vnlfsocialapp/src/features/polls/data/live_poll_repository.dart';

const pollId = '01a142c4-3482-79ad-be96-ff39844fdfd3';
const optionA = '01a1386b-f740-7ee8-8a6b-99adc27b090a';
const optionB = '01a1381a-d616-7df0-8910-99fe55941725';
const pollJson = <String, dynamic>{
  'id': pollId,
  'question': 'Bạn dùng Linux nào?',
  'options': [
    {'id': optionA, 'label': 'Arch', 'votes': 2},
    {'id': optionB, 'label': 'Debian', 'votes': 1},
  ],
  'totalVotes': 3,
  'viewerOptionId': optionA,
};
void main() {
  test('poll input applies source whitespace and case-sensitive choice rules without mutating input', () {
    final labels = [' Arch   Linux ', 'Debian', 'Arch Linux', '   '];
    final input = PollInput.tryCreate('  Bạn\n dùng Linux nào?  ', labels)!;
    expect(input.question, 'Bạn dùng Linux nào?');
    expect(input.options, ['Arch Linux', 'Debian']);
    expect(labels, hasLength(4));
    expect(() => input.options.add('Fedora'), throwsUnsupportedError);
    expect(PollInput.tryCreate('?', ['Arch', 'arch']), isNotNull);
    expect(PollInput.tryCreate('?', ['Arch', ' Arch ']), isNull);
    expect(PollInput.tryCreate(' ', ['a', 'b']), isNull);
    expect(PollInput.tryCreate('?' * 201, ['a', 'b']), isNull);
    expect(PollInput.tryCreate('?', ['a' * 101, 'b']), isNull);
    expect(PollInput.tryCreate('?', List.generate(7, (i) => '$i')), isNull);
    expect(PollInput.tryCreate('😀' * 101, ['a', 'b']), isNull);
  });
  test('poll DTO tolerates unknown fields, owns immutable options and rejects malformed counts', () {
    final poll = PollDto({...pollJson, 'future': true}).toDomain();
    expect(poll.id, pollId);
    expect(poll.viewerOptionId, optionA);
    expect(poll.options.last.votes, 1);
    expect(() => poll.options.clear(), throwsUnsupportedError);
    expect(
      () => PollDto({...pollJson, 'totalVotes': -1}).toDomain(),
      throwsA(isA<ParseFailure>()),
    );
    expect(
      () => PollDto({...pollJson, 'options': 'invalid'}).toDomain(),
      throwsA(isA<ParseFailure>()),
    );
  });
  test('vote and unvote use nullable choice payloads and require matching full acknowledgments', () async {
    final requests = <ApiRequest>[];
    final repo = _repo((request) async {
      requests.add(request);
      final body = jsonDecode(request.body!) as Map<String, dynamic>;
      return _reply({...pollJson, 'viewerOptionId': body['optionId']});
    });
    expect((await repo.vote(pollId, optionB)).viewerOptionId, optionB);
    expect((await repo.vote(pollId, null)).viewerOptionId, isNull);
    expect(requests.map((r) => r.method), ['POST', 'POST']);
    expect(
      requests.map((r) => r.path),
      List.filled(2, '/api/v1/polls/$pollId/vote'),
    );
    expect(jsonDecode(requests.last.body!), {'optionId': null});
  });
  test('edit and draft set/remove follow the verified routes and preserve server option identities', () async {
    final requests = <ApiRequest>[];
    final repo = _repo((request) async {
      requests.add(request);
      if (request.path.endsWith('/poll')) {
        final body = jsonDecode(request.body!) as Map<String, dynamic>;
        return _reply({'poll': body['poll'] == null ? null : pollJson});
      }
      return _reply(pollJson);
    });
    final input = PollInput.tryCreate('Bạn dùng Linux nào?', [
      'Arch',
      'Debian',
    ])!;
    expect((await repo.edit(pollId, input)).options.first.id, optionA);
    expect((await repo.setDraftPoll(pollId, input))?.id, pollId);
    expect(await repo.setDraftPoll(pollId, null), isNull);
    expect(requests.map((r) => r.method), ['PUT', 'PUT', 'PUT']);
    expect(requests[1].path, '/api/v1/articles/$pollId/poll');
    expect(jsonDecode(requests.first.body!), {
      'question': input.question,
      'options': input.options,
    });
    expect(jsonDecode(requests.last.body!), {'poll': null});
  });
  test('empty, unrelated and unacknowledged votes or draft removal cannot confirm success', () async {
    for (final response in [
      _reply({}),
      ApiResponse(statusCode: 204, body: ''),
      _reply({...pollJson, 'id': optionB}),
      _reply({...pollJson, 'viewerOptionId': optionB}),
    ]) {
      final repo = _repo((_) async => response);
      await expectLater(
        repo.vote(pollId, optionA),
        throwsA(isA<ParseFailure>()),
      );
    }
    final missingSelection = {...pollJson}..remove('viewerOptionId');
    await expectLater(
      _repo((_) async => _reply(missingSelection)).vote(pollId, null),
      throwsA(isA<ParseFailure>()),
    );
    await expectLater(
      _repo((_) async => _reply({})).setDraftPoll(pollId, null),
      throwsA(isA<ParseFailure>()),
    );
  });
  test('failed poll mutations are not automatically retried', () async {
    var calls = 0;
    final repo = _repo((_) async {
      calls++;
      return ApiResponse(statusCode: 503, body: '{}');
    });
    await expectLater(repo.vote(pollId, optionA), throwsA(isA<HttpFailure>()));
    expect(calls, 1);
  });
  test('invalid poll or choice identifiers are rejected before contacting the server', () async {
    var calls = 0;
    final repo = _repo((_) async {
      calls++;
      return _reply(pollJson);
    });
    await expectLater(
      Future.sync(() => repo.vote('../unknown', optionA)),
      throwsA(isA<ParseFailure>()),
    );
    await expectLater(
      Future.sync(() => repo.vote(pollId, 'unknown')),
      throwsA(isA<ParseFailure>()),
    );
    expect(calls, 0);
  });
}

LivePollRepository _repo(ApiTransport transport) => LivePollRepository(
  ApiClient(
    transport: transport,
    hostKey: Object(),
    throttleInterval: Duration.zero,
  ),
);
ApiResponse _reply(Map<String, dynamic> data) =>
    ApiResponse(statusCode: 200, body: jsonEncode(data));
