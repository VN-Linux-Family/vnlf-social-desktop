import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/composer/data/composer_recovery.dart';
import 'package:vnlfsocialapp/src/features/composer/data/composer_repository.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/compose_document.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_draft.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_format.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_poll.dart';
import 'package:vnlfsocialapp/src/features/composer/presentation/composer_controller.dart';
import 'package:vnlfsocialapp/src/features/polls/domain/poll_models.dart';

void main() {
  test(
    'converting a draft post removes its poll through the separate endpoint',
    () async {
      final server = _Server();
      final controller = _controller(server);
      controller.edit(
        controller.draft.copyWith(
          document: composeDocument('Nội dung'),
          pollDraft: ComposerPollDraft('Chọn', ['Linux', 'BSD']),
          pollChanged: true,
        ),
      );
      expect(await controller.save(), isTrue);
      controller.edit(asArticle(controller.draft));
      expect(await controller.save(), isTrue);
      expect(controller.draft.format, 'ARTICLE');
      expect(controller.draft.pollDraft, isNull);
      expect(server.poll, isNull);
      expect(jsonDecode(server.requests.last.body!), {'poll': null});
      controller.dispose();
    },
  );

  test(
    'published poll format conversion follows the server ARTICLE projection',
    () async {
      final server = _Server();
      final controller = _controller(server);
      controller.edit(
        controller.draft.copyWith(
          document: composeDocument('Nội dung'),
          pollDraft: ComposerPollDraft('Chọn', ['Linux', 'BSD']),
          pollChanged: true,
        ),
      );
      expect(await controller.publish(), isNotNull);
      final puts = server.requests.where((r) => r.method == 'PUT').length;
      controller.edit(asArticle(controller.draft));
      expect(await controller.save(), isTrue);
      expect(controller.draft.pollDraft, isNull);
      expect(await controller.save(), isTrue);
      expect(server.requests.where((r) => r.method == 'PUT').length, puts);
      controller.dispose();
    },
  );

  test('a text edit during poll save does not replace poll option identities again', () async {
    final server = _Server()..pollGate = Completer<void>();
    final controller = _controller(server);
    controller.edit(
      controller.draft.copyWith(
        document: composeDocument('Nội dung'),
        pollDraft: ComposerPollDraft('Chọn', ['Linux', 'BSD']),
        pollChanged: true,
      ),
    );
    final save = controller.save();
    await server.pollEntered.future;
    controller.edit(
      controller.draft.copyWith(document: composeDocument('Nội dung mới')),
    );
    server.pollGate!.complete();
    await save;
    expect(controller.draft.pollChanged, isFalse);
    expect(controller.dirty, isTrue);
    expect(await controller.save(), isTrue);
    expect(server.requests.where((r) => r.method == 'PUT').length, 1);
    controller.dispose();
  });

  test(
    'account changes while a poll saves prevent publication and acknowledgment',
    () async {
      var current = true;
      final server = _Server()..pollGate = Completer<void>();
      final controller = ComposerController(
        repository: _repository(server),
        recovery: ComposerRecovery(_Memory()),
        userId: 'owner',
        isCurrent: () => current,
      );
      controller.edit(
        controller.draft.copyWith(
          document: composeDocument('Nội dung'),
          pollDraft: ComposerPollDraft('Chọn', ['Linux', 'BSD']),
          pollChanged: true,
        ),
      );
      final publication = controller.publish();
      await server.pollEntered.future;
      current = false;
      server.pollGate!.complete();
      expect(await publication, isNull);
      expect(controller.draft.pollChanged, isTrue);
      expect(server.requests.any((r) => r.path.endsWith('/publish')), isFalse);
      controller.dispose();
    },
  );

  test('incomplete poll recovery is owner scoped and lossless', () async {
    final recovery = ComposerRecovery(_Memory());
    final raw = ComposerPollDraft('', ['Linux', '']);
    await recovery.write(
      'owner',
      RecoveredComposition(
        ComposerDraft(id: '', version: 0, pollDraft: raw, pollChanged: true),
        true,
        null,
      ),
    );
    final restored = await recovery.read('owner');
    expect(restored!.draft.pollDraft!.question, '');
    expect(restored.draft.pollDraft!.options, ['Linux', '']);
    expect(restored.draft.pollChanged, isTrue);
    expect(await recovery.read('other'), isNull);
  });

  test(
    'poll save precedes publish and unchanged polls are not replaced',
    () async {
      final server = _Server();
      final controller = _controller(server);
      controller.edit(
        controller.draft.copyWith(
          document: composeDocument('Bình chọn'),
          pollDraft: ComposerPollDraft('Bạn dùng gì?', ['Linux', 'BSD']),
          pollChanged: true,
        ),
      );
      expect(await controller.save(), isTrue);
      expect(server.requests.map((r) => r.method), ['POST', 'PATCH', 'PUT']);
      expect(controller.draft.poll!.id, 'poll-id');
      expect(controller.draft.pollChanged, isFalse);
      controller.edit(
        controller.draft.copyWith(document: composeDocument('Thêm nội dung')),
      );
      expect(await controller.publish(), isNotNull);
      expect(server.requests.where((r) => r.method == 'PUT').length, 1);
      expect(server.requests.last.path.endsWith('/publish'), isTrue);
      controller.dispose();
    },
  );

  test(
    'incomplete choices stay local and block publish without a write',
    () async {
      final server = _Server();
      final controller = _controller(server);
      controller.edit(
        controller.draft.copyWith(
          document: composeDocument('Nội dung'),
          pollDraft: ComposerPollDraft('Chọn', ['Linux', '']),
          pollChanged: true,
        ),
      );
      expect(await controller.save(), isFalse);
      expect(controller.dirty, isTrue);
      expect(server.requests.where((r) => r.method == 'PUT'), isEmpty);
      final before = server.requests.length;
      expect(await controller.publish(), isNull);
      expect(server.requests.length, before);
      controller.dispose();
    },
  );

  test(
    'failed poll write retains acknowledged body version and recoverable input',
    () async {
      final server = _Server()..failPoll = true;
      final memory = _Memory();
      final controller = _controller(server, memory: memory);
      controller.edit(
        controller.draft.copyWith(
          document: composeDocument('Nội dung'),
          pollDraft: ComposerPollDraft('Chọn', ['Linux', 'BSD']),
          pollChanged: true,
        ),
      );
      expect(await controller.save(), isFalse);
      expect(controller.draft.version, 2);
      expect(controller.draft.pollChanged, isTrue);
      expect(server.requests.where((r) => r.method == 'PUT').length, 1);
      await controller.flushRecovery();
      expect(
        (await ComposerRecovery(memory).read('owner'))!
            .draft
            .pollDraft!
            .options,
        ['Linux', 'BSD'],
      );
      server.failPoll = false;
      expect(await controller.save(), isTrue);
      expect(controller.draft.version, 3);
      expect(server.requests.where((r) => r.method == 'PUT').length, 2);
      controller.dispose();
    },
  );

  test('late poll acknowledgement cannot erase newer editor input', () async {
    final server = _Server()..pollGate = Completer<void>();
    final controller = _controller(server);
    controller.edit(
      controller.draft.copyWith(
        document: composeDocument('Nội dung'),
        pollDraft: ComposerPollDraft('Cũ', ['Linux', 'BSD']),
        pollChanged: true,
      ),
    );
    final save = controller.save();
    await server.pollEntered.future;
    controller.edit(
      controller.draft.copyWith(
        pollDraft: ComposerPollDraft('Mới', ['Linux', 'BSD']),
        pollChanged: true,
      ),
    );
    server.pollGate!.complete();
    await save;
    expect(controller.draft.pollDraft!.question, 'Mới');
    expect(controller.draft.pollChanged, isTrue);
    expect(controller.dirty, isTrue);
    controller.dispose();
  });

  test('draft poll deletion requires explicit null acknowledgment', () async {
    final server = _Server();
    final repository = _repository(server);
    final input = PollInput.tryCreate('Chọn', ['Linux', 'BSD'])!;
    expect(
      (await repository.savePoll(
        '00000000-0000-4000-8000-000000000111',
        input,
      ))!.question,
      'Chọn',
    );
    expect(
      await repository.savePoll('00000000-0000-4000-8000-000000000111', null),
      isNull,
    );
    expect(jsonDecode(server.requests.last.body!), {'poll': null});
    server.badAck = true;
    await expectLater(
      repository.savePoll('00000000-0000-4000-8000-000000000111', null),
      throwsA(isA<ParseFailure>()),
    );
    await expectLater(
      repository.savePoll('00000000-0000-4000-8000-000000000111', input),
      throwsA(isA<ParseFailure>()),
    );
  });
}

ComposerController _controller(_Server server, {_Memory? memory}) =>
    ComposerController(
      repository: _repository(server),
      recovery: ComposerRecovery(memory ?? _Memory()),
      userId: 'owner',
      isCurrent: () => true,
    );
LiveComposerRepository _repository(_Server server) => LiveComposerRepository(
  ApiClient(
    transport: server.call,
    throttleInterval: Duration.zero,
    hostKey: Object(),
  ),
);

class _Server {
  final requests = <ApiRequest>[];
  var version = 1;
  var format = 'POST';
  var published = false;
  Map<String, Object?>? poll;
  bool failPoll = false, badAck = false;
  Completer<void>? pollGate;
  final pollEntered = Completer<void>();
  Future<ApiResponse> call(ApiRequest request) async {
    requests.add(request);
    if (request.path.endsWith('/poll')) {
      if (!pollEntered.isCompleted) pollEntered.complete();
      if (pollGate != null) await pollGate!.future;
      if (failPoll) return ApiResponse(statusCode: 503, body: '{}');
      if (badAck) return ApiResponse(statusCode: 200, body: '{}');
      final input = (jsonDecode(request.body!) as Map)['poll'] as Map?;
      poll = input == null
          ? null
          : {
              'id': 'poll-id',
              'question': input['question'],
              'options': [
                for (var i = 0; i < (input['options'] as List).length; i++)
                  {'id': 'option-$i', 'label': input['options'][i], 'votes': 0},
              ],
              'totalVotes': 0,
              'viewerOptionId': null,
            };
      return ApiResponse(statusCode: 200, body: jsonEncode({'poll': poll}));
    }
    if (request.method == 'PATCH') {
      if (jsonDecode(request.body!)['version'] != version) {
        return ApiResponse(statusCode: 409, body: '{}');
      }
      version++;
      format = jsonDecode(request.body!)['format'] as String;
    }
    if (request.path.endsWith('/publish')) published = true;
    return ApiResponse(
      statusCode: 200,
      body: jsonEncode({
        'id': '00000000-0000-4000-8000-000000000111',
        'version': version,
        'format': format,
        'status': published ? 'PUBLISHED' : 'DRAFT',
        'publishedAt': published ? '2026-11-06T00:00:00Z' : null,
        'contentJson': composeDocument('Nội dung'),
        'poll': format == 'POST' ? poll : null,
      }),
    );
  }
}

class _Memory implements SessionStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
