import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/voice/data/live_voice_repository.dart';

void main() {
  test('room directory maps server counts and ignores added fields', () async {
    final repository = LiveVoiceRepository(
      _client((request) async {
        expect(request.path, '/api/v1/voice/rooms');
        expect(request.method, 'GET');
        return _response({
          'items': [
            {
              'id': 'room-1',
              'slug': 'tieng-viet',
              'name': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
              'description': null,
              'status': 'ACTIVE',
              'capacity': 20,
              'minRole': 'MEMBER',
              'position': 2,
              'createdBy': 'synthetic-user',
              'livekitRoomName': 'synthetic-room',
              'archivedAt': null,
              'createdAt': '2026-11-05T00:00:00Z',
              'updatedAt': '2026-11-05T00:00:00Z',
              'participantCount': 4,
              'viewerInRoom': true,
              'newField': 'ignored',
            },
          ],
        });
      }),
    );
    final rooms = await repository.getRooms();
    expect(rooms.single.name, 'Tiếng Việt: ặ ữ ờ ẫ ệ');
    expect(rooms.single.description, '');
    expect(rooms.single.participantCount, 4);
    expect(rooms.single.viewerInRoom, isTrue);
  });

  test('invalid required room identity fails explicitly', () async {
    final repository = LiveVoiceRepository(
      _client(
        (_) async => _response({
          'items': [
            {'name': 'Broken room'},
          ],
        }),
      ),
    );
    await expectLater(repository.getRooms(), throwsA(isA<ParseFailure>()));
  });

  test(
    'join uses confirmed response fields and sends one bodyless POST',
    () async {
      var requests = 0;
      final repository = LiveVoiceRepository(
        _client((request) async {
          requests++;
          expect(request.path, '/api/v1/voice/rooms/room-1/join-token');
          expect(request.method, 'POST');
          expect(request.body, isNull);
          return _response({
            'serverUrl': 'wss://voice.example.invalid',
            'token': 'synthetic-test-value',
            'iceServers': [
              {
                'urls': ['stun:example.invalid:3478'],
              },
            ],
          });
        }),
      );
      final connection = await repository.join('room-1');
      expect(connection.serverUrl, 'wss://voice.example.invalid');
      expect(connection.iceServers.single.urls, ['stun:example.invalid:3478']);
      expect(requests, 1);
    },
  );

  test(
    'missing connection credentials cannot become a successful join',
    () async {
      final repository = LiveVoiceRepository(
        _client(
          (_) async => _response({'serverUrl': 'wss://voice.example.invalid'}),
        ),
      );
      await expectLater(
        repository.join('room-1'),
        throwsA(isA<ParseFailure>()),
      );
    },
  );

  test('failed leave is never automatically retried', () async {
    var requests = 0;
    final repository = LiveVoiceRepository(
      _client((request) async {
        requests++;
        expect(request.path, '/api/v1/voice/rooms/room-1/leave');
        expect(request.method, 'POST');
        expect(request.body, isNull);
        return ApiResponse(statusCode: 503, body: '{}');
      }),
    );
    await expectLater(repository.leave('room-1'), throwsA(isA<HttpFailure>()));
    expect(requests, 1);
  });
}

ApiClient _client(ApiTransport transport) => ApiClient(
  transport: transport,
  throttleInterval: Duration.zero,
  hostKey: Object(),
);
ApiResponse _response(Map<String, dynamic> data) =>
    ApiResponse(statusCode: 200, body: jsonEncode(data));
