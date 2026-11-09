import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage.dart';
import 'package:vnlfsocialapp/src/features/composer/data/composer_repository.dart';
import 'package:vnlfsocialapp/src/features/composer/data/composer_recovery.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/compose_document.dart';
import 'package:vnlfsocialapp/src/features/composer/presentation/composer_controller.dart';

void main() {
  test(
    'stale field callbacks cannot rewind the acknowledged server version',
    () async {
      final controller = _controller(
        (request) async =>
            _response(version: request.method == 'PATCH' ? 2 : 1),
      );
      final stale = controller.draft.copyWith(
        document: composeDocument('Nội dung'),
      );
      controller.edit(stale);
      expect(await controller.save(), isTrue);
      controller.edit(stale.copyWith(title: 'Tiêu đề vừa gõ'));
      expect(controller.draft.version, 2);
      expect(controller.draft.id, 'draft-id');
      controller.dispose();
    },
  );
  test('failed recovery never overwrites the unread local draft', () async {
    final storage = _Storage()
      ..values['vnlf.composer.synthetic-owner.new'] =
          '{invalid synthetic recovery';
    final controller = _controller(
      (_) async => throw StateError('Unexpected network'),
      storage: storage,
    );
    await controller.initialize();
    controller.edit(
      controller.draft.copyWith(document: composeDocument('Không được ghi đè')),
    );
    await controller.flushRecovery();
    controller.dispose();
    expect(
      storage.values['vnlf.composer.synthetic-owner.new'],
      '{invalid synthetic recovery',
    );
  });
  test('opening is read only and explicit save precedes publish', () async {
    final requests = <ApiRequest>[];
    final controller = _controller((request) async {
      requests.add(request);
      return _response(
        version: requests.length,
        published: request.path.endsWith('/publish'),
      );
    });
    await controller.initialize();
    expect(requests, isEmpty);
    controller.edit(
      controller.draft.copyWith(document: composeDocument('Bài thử')),
    );
    final result = await controller.publish();
    expect(result?.status, 'PUBLISHED');
    expect(requests.map((r) => r.method), ['POST', 'PATCH', 'POST']);
    expect(
      jsonDecode(requests[1].body!)['contentJson'],
      composeDocument('Bài thử'),
    );
    expect(requests.last.headers['idempotency-key'], isNotEmpty);
    controller.dispose();
  });
  test(
    'acknowledged publication clears recovery instead of reopening an old post',
    () async {
      final storage = _Storage();
      final controller = _controller(
        (request) async =>
            _response(published: request.path.endsWith('/publish')),
        storage: storage,
      );
      controller.edit(
        controller.draft.copyWith(document: composeDocument('Bài đã đăng')),
      );
      expect(await controller.publish(), isNotNull);
      await controller.flushRecovery();
      controller.dispose();
      expect(await ComposerRecovery(storage).read('synthetic-owner'), isNull);
    },
  );
  test('failed save keeps recoverable text and never publishes', () async {
    final storage = _Storage();
    final requests = <ApiRequest>[];
    final controller = _controller((request) async {
      requests.add(request);
      return request.method == 'POST'
          ? _response()
          : ApiResponse(statusCode: 503, body: '{}');
    }, storage: storage);
    controller.edit(
      controller.draft.copyWith(document: composeDocument('Chưa được lưu')),
    );
    expect(await controller.publish(), isNull);
    expect(requests.map((r) => r.method), ['POST', 'PATCH']);
    expect(controller.dirty, isTrue);
    expect(controller.error, isA<HttpFailure>());
    await controller.flushRecovery();
    controller.dispose();
    final recovered = _controller(
      (_) async => throw StateError('Unexpected network'),
      storage: storage,
    );
    await recovered.initialize();
    expect(recovered.draft.document, composeDocument('Chưa được lưu'));
    expect(recovered.dirty, isTrue);
    recovered.dispose();
    expect(await ComposerRecovery(storage).read('another-owner'), isNull);
  });
  test(
    'newer edits survive an older save response while version advances',
    () async {
      final gate = Completer<ApiResponse>();
      final controller = _controller(
        (request) async =>
            request.method == 'PATCH' ? gate.future : _response(),
      );
      controller.edit(
        controller.draft.copyWith(document: composeDocument('Đầu tiên')),
      );
      final save = controller.save();
      await Future<void>.delayed(Duration.zero);
      controller.edit(
        controller.draft.copyWith(document: composeDocument('Mới nhất')),
      );
      gate.complete(_response(version: 2));
      expect(await save, isTrue);
      expect(controller.draft.document, composeDocument('Mới nhất'));
      expect(controller.draft.version, 2);
      expect(controller.dirty, isTrue);
      controller.dispose();
    },
  );
  test('a lost publish acknowledgment keeps the same attempt identity on manual retry', () async {
    final attempts = <String>[];
    final storage = _Storage();
    Future<ApiResponse> transport(ApiRequest request) async {
      if (request.path.endsWith('/publish')) {
        attempts.add(request.headers['idempotency-key']!);
        if (attempts.length == 1) throw const TransportFailure();
        return _response(version: 3, published: true);
      }
      return _response(version: request.method == 'PATCH' ? 2 : 1);
    }

    final controller = _controller(transport, storage: storage);
    controller.edit(
      controller.draft.copyWith(document: composeDocument('Chỉ đăng một lần')),
    );
    expect(await controller.publish(), isNull);
    await controller.flushRecovery();
    controller.dispose();
    final restored = _controller(transport, storage: storage);
    await restored.initialize();
    expect((await restored.publish())?.status, 'PUBLISHED');
    expect(attempts.length, 2);
    expect(attempts[0], attempts[1]);
    restored.dispose();
  });
  test(
    'account change after creation prevents a save with the new account',
    () async {
      var active = true;
      final requests = <ApiRequest>[];
      final controller = _controller((request) async {
        requests.add(request);
        active = false;
        return _response();
      }, isCurrent: () => active);
      controller.edit(
        controller.draft.copyWith(
          document: composeDocument('Riêng tài khoản thử'),
        ),
      );
      expect(await controller.publish(), isNull);
      expect(requests.map((r) => r.method), ['POST']);
      controller.dispose();
    },
  );
}

ComposerController _controller(
  ApiTransport transport, {
  _Storage? storage,
  bool Function()? isCurrent,
}) => ComposerController(
  repository: LiveComposerRepository(
    ApiClient(
      transport: transport,
      throttleInterval: Duration.zero,
      hostKey: Object(),
    ),
  ),
  recovery: ComposerRecovery(storage ?? _Storage()),
  userId: 'synthetic-owner',
  isCurrent: isCurrent ?? () => true,
);
ApiResponse _response({int version = 1, bool published = false}) => ApiResponse(
  statusCode: 200,
  body: jsonEncode({
    'id': 'draft-id',
    'version': version,
    'format': 'POST',
    'status': published ? 'PUBLISHED' : 'DRAFT',
    'contentJson': composeDocument('Bài thử'),
  }),
);

class _Storage implements SessionStorage {
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
