import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/settings/preferences/preferences.dart';
import 'package:vnlfsocialapp/src/features/settings/preferences/preferences_repository.dart';
import 'package:vnlfsocialapp/src/features/settings/preferences/preferences_controller.dart';

void main() {
  test('null and missing fields use database defaults', () {
    final p = WebsitePreferences.fromJson(null);
    expect(p.dmPolicy, DmPolicy.everyone);
    expect(p.leaderboardVisible, isTrue);
    expect(p.onlineVisible, isTrue);
    expect(p.likeNotifications, isTrue);
    expect(p.followNotifications, isTrue);
    expect(p.messageNotifications, isTrue);
    expect(p.messageSoundEnabled, isTrue);
    expect(p.reduceMotion, isFalse);
  });

  test('parses opt out and rejects malformed values', () {
    expect(WebsitePreferences.fromJson({'leaderboardOptOut': true}).leaderboardVisible, isFalse);
    expect(() => WebsitePreferences.fromJson({'onlineVisible': 'yes'}), throwsA(isA<ParseFailure>()));
    expect(() => WebsitePreferences.fromJson({'dmPolicy': 'UNKNOWN'}), throwsA(isA<ParseFailure>()));
  });

  test('save sends explicit values once and requires acknowledgement', () async {
    final requests = <ApiRequest>[];
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (request) async {
      requests.add(request);
      return ApiResponse(statusCode: 200, body: '{"ok":true}');
    });
    final repository = PreferencesRepository(client, 'a', () => 'a');
    await repository.save(const WebsitePreferences(leaderboardVisible: false));
    expect(requests, hasLength(1));
    expect(requests.single.method, 'PATCH');
    expect(jsonDecode(requests.single.body!)['leaderboardOptOut'], isTrue);
    expect(jsonDecode(requests.single.body!)['dmPolicy'], 'EVERYONE');
  });

  test('old account cannot save after session invalidation', () async {
    var calls = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async {
      calls++;
      return ApiResponse(statusCode: 200, body: '{"ok":true}');
    });
    final repository = PreferencesRepository(client, 'a', () => 'a');
    client.invalidateSession();
    await expectLater(repository.save(const WebsitePreferences()), throwsA(isA<HttpFailure>()));
    expect(calls, 0);
  });
  test('uncertain write blocks another save until a fresh read', () async {
    var patches = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (request) async {
      if (request.method == 'GET') return ApiResponse(statusCode: 200, body: '{}');
      patches++;
      throw TimeoutException('lost response');
    });
    final controller = PreferencesController(PreferencesRepository(client, 'a', () => 'a'));
    await Future<void>.delayed(Duration.zero);
    // Wait for the initial asynchronous read without issuing a second load.
    while (controller.state.busy) {
      await Future<void>.delayed(Duration.zero);
    }
    controller.edit(controller.state.draft!.copyWith(reduceMotion: true));
    await controller.save();
    expect(controller.state.uncertain, isTrue);
    expect(controller.state.confirmed, isNull);
    await controller.save();
    expect(patches, 1);
    await controller.refresh();
    expect(controller.state.uncertain, isFalse);
    expect(controller.state.confirmed!.reduceMotion, isFalse);
    expect(controller.state.draft!.reduceMotion, isTrue);
    expect(controller.state.dirty, isTrue);
    controller.dispose();
  });

}
