import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/activity/data/live_activity_repository.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_models.dart';

void main() {
  group('activity date handling', () {
    test('uses Vietnam date at UTC midnight boundary', () {
      expect(activityDayString(DateTime.utc(2026, 1, 31, 16, 59)), '2026-01-31');
      expect(activityDayString(DateTime.utc(2026, 1, 31, 17)), '2026-02-01');
    });

    test('month range handles leap February and year rollover', () {
      expect(activityMonthRange(2024, 2), (
        from: '2024-02-01',
        to: '2024-02-29',
      ));
      expect(activityMonthRange(2025, 12), (
        from: '2025-12-01',
        to: '2025-12-31',
      ));
    });

    test('date shifts stay calendar based across month boundaries', () {
      expect(shiftActivityDay('2026-03-01', -1), '2026-02-28');
      expect(shiftActivityDay('2024-03-01', -1), '2024-02-29');
    });
  });

  group('live activity repository', () {
    test('requests only the source-defined calendar and check-in paths', () async {
      final requests = <ApiRequest>[];
      final repository = _repository((request) async {
        requests.add(request);
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode(
            request.method == 'GET' ? _calendarPayload() : _checkInPayload(),
          ),
        );
      });

      final result = await repository.loadCalendar(
        from: '2026-11-01',
        to: '2026-11-02',
      );
      expect(result.days, hasLength(2));
      expect(result.totalPoints, 14);
      final acknowledgment = await repository.checkIn(
        claimCelebration: true,
      );
      expect(acknowledgment.showCelebration, isTrue);

      expect(requests, hasLength(2));
      expect(requests[0].path, '/api/v1/me/activity-calendar');
      expect(requests[0].query, {'from': '2026-11-01', 'to': '2026-11-02'});
      expect(requests[1].path, '/api/v1/me/check-in');
      expect(requests[1].method, 'POST');
      expect(jsonDecode(requests[1].body!), {'claimCelebration': true});
    });

    test('rejects malformed dates and mismatched calendar acknowledgments', () async {
      final repository = _repository(
        (_) async => ApiResponse(
          statusCode: 200,
          body: jsonEncode(_calendarPayload()..['from'] = '2026-10-01'),
        ),
      );
      await expectLater(
        repository.loadCalendar(from: '2026-02-30', to: '2026-03-01'),
        throwsA(isA<ParseFailure>()),
      );
      await expectLater(
        repository.loadCalendar(from: '2026-11-01', to: '2026-11-30'),
        throwsA(isA<ParseFailure>()),
      );
    });

    test('requires a full check-in acknowledgment and never retries POST', () async {
      var postCount = 0;
      final repository = _repository((request) async {
        if (request.method == 'POST') postCount++;
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode({'date': '2026-11-06', 'showCelebration': true}),
        );
      });

      await expectLater(
        repository.checkIn(claimCelebration: false),
        throwsA(isA<ParseFailure>()),
      );
      expect(postCount, 1);
    });

    test('rejects queued or completed work after owner/session changes', () async {
      var owner = 'owner-a';
      final readResponse = Completer<ApiResponse>();
      final repository = _repository((_) async {
        return readResponse.future;
      }, currentOwnerId: () => owner);
      final request = repository.loadCalendar(
        from: '2026-11-01',
        to: '2026-11-30',
      );
      owner = 'owner-b';
      readResponse.complete(
        ApiResponse(statusCode: 200, body: jsonEncode(_calendarPayload())),
      );
      await expectLater(request, throwsA(isA<HttpFailure>()));
    });
  });


}

LiveActivityRepository _repository(
  ApiTransport transport, {
  String? Function()? currentOwnerId,
}) => LiveActivityRepository(
  ApiClient(
    transport: transport,
    throttleInterval: Duration.zero,
    cacheDuration: Duration.zero,
  ),
  ownerId: 'owner-a',
  currentOwnerId: currentOwnerId ?? () => 'owner-a',
);

Map<String, Object?> _calendarPayload() => {
  'from': '2026-11-01',
  'to': '2026-11-02',
  'today': '2026-11-06',
  'totalPoints': 14,
  'earnedPoints': 17,
  'reversedPoints': -3,
  'currentStreak': 2,
  'longestStreak': 9,
  'days': [
    {
      'date': '2026-11-01',
      'points': 14,
      'checkedIn': true,
      'streakDay': 1,
    },
    {
      'date': '2026-11-02',
      'points': 0,
      'checkedIn': false,
      'streakDay': 0,
    },
  ],
};

Map<String, Object?> _checkInPayload() => {
  'date': '2026-11-06',
  'currentStreak': 3,
  'longestStreak': 9,
  'showCelebration': true,
  'checkins': [
    {'date': '2026-11-06', 'streakDay': 3},
  ],
};
