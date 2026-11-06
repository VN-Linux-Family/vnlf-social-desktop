import 'dart:convert';

import '../../../core/api_client.dart';
import '../domain/activity_models.dart';
import '../domain/activity_repository.dart';

/// Typed adapter for the two activity endpoints used by the website.
///
/// Bind [currentOwnerId] to the app's confirmed session identity. Both it and
/// ApiClient's session generation are checked around every operation so work
/// queued by a previous account cannot be delivered to the next one.
final class LiveActivityRepository implements ActivityRepository {
  LiveActivityRepository(
    this._client, {
    required this.ownerId,
    required this.currentOwnerId,
  }) : _session = _client.captureSession();

  final ApiClient _client;
  final String ownerId;
  final String? Function() currentOwnerId;
  final ApiSessionScope _session;

  void _ensureOwner() {
    _session.ensureCurrent();
    if (currentOwnerId() != ownerId) throw const HttpFailure(401);
  }

  @override
  Future<ActivityCalendarData> loadCalendar({
    required String from,
    required String to,
  }) async {
    _ensureOwner();
    if (!_validDay(from) || !_validDay(to) || from.compareTo(to) > 0) {
      throw const ParseFailure('activity.range');
    }
    final span = DateTime.parse('${to}T00:00:00Z')
        .difference(DateTime.parse('${from}T00:00:00Z'))
        .inDays;
    if (span > 365) throw const ParseFailure('activity.range');
    final data = await _client.get<ActivityCalendarData>(
      '/api/v1/me/activity-calendar',
      query: {'from': from, 'to': to},
      refresh: true,
      decode: _decodeCalendar,
    );
    _ensureOwner();
    if (data.from != from || data.to != to) {
      throw const ParseFailure('activity.range.ack');
    }
    if (data.days.length != span + 1) {
      throw const ParseFailure('activity.days.coverage');
    }
    for (var index = 0; index < data.days.length; index++) {
      if (data.days[index].date != _shiftDay(from, index)) {
        throw const ParseFailure('activity.days.order');
      }
    }
    return data;
  }

  @override
  Future<CheckInAcknowledgment> checkIn({
    required bool claimCelebration,
  }) async {
    _ensureOwner();
    // ApiClient only retries GET/HEAD/OPTIONS. Keep this write explicit and
    // require the complete server acknowledgment before reporting success.
    final result = await _client.request<CheckInAcknowledgment>(
      'POST',
      '/api/v1/me/check-in',
      body: jsonEncode({'claimCelebration': claimCelebration}),
      decode: _decodeCheckIn,
    );
    _ensureOwner();
    return result;
  }

  ActivityCalendarData _decodeCalendar(Map<String, dynamic> json) {
    final daysValue = json['days'];
    if (daysValue is! List) throw const ParseFailure('activity.days');
    final days = <ActivityDay>[];
    for (final value in daysValue) {
      if (value is! Map) throw const ParseFailure('activity.day');
      final day = Map<String, dynamic>.from(value);
      final date = _requiredString(day, 'date', 'activity.day.date');
      if (!_validDay(date)) throw const ParseFailure('activity.day.date');
      days.add(
        ActivityDay(
          date: date,
          points: _requiredInt(day, 'points', 'activity.day.points'),
          checkedIn: _requiredBool(day, 'checkedIn', 'activity.day.checkedIn'),
          streakDay: _requiredInt(day, 'streakDay', 'activity.day.streakDay'),
        ),
      );
    }
    final from = _requiredString(json, 'from', 'activity.from');
    final to = _requiredString(json, 'to', 'activity.to');
    final today = _requiredString(json, 'today', 'activity.today');
    if (!_validDay(from) || !_validDay(to) || !_validDay(today)) {
      throw const ParseFailure('activity.date');
    }
    return ActivityCalendarData(
      from: from,
      to: to,
      today: today,
      totalPoints: _requiredInt(json, 'totalPoints', 'activity.totalPoints'),
      earnedPoints: _requiredInt(json, 'earnedPoints', 'activity.earnedPoints'),
      reversedPoints: _requiredInt(
        json,
        'reversedPoints',
        'activity.reversedPoints',
      ),
      currentStreak: _requiredInt(
        json,
        'currentStreak',
        'activity.currentStreak',
      ),
      longestStreak: _requiredInt(
        json,
        'longestStreak',
        'activity.longestStreak',
      ),
      days: days,
    );
  }

  CheckInAcknowledgment _decodeCheckIn(Map<String, dynamic> json) {
    final date = _requiredString(json, 'date', 'activity.checkin.date');
    final values = json['checkins'];
    if (!_validDay(date) || values is! List) {
      throw const ParseFailure('activity.checkin.ack');
    }
    final checkins = <CheckInDay>[];
    for (final value in values) {
      if (value is! Map) throw const ParseFailure('activity.checkin.day');
      final item = Map<String, dynamic>.from(value);
      final itemDate = _requiredString(
        item,
        'date',
        'activity.checkin.day.date',
      );
      if (!_validDay(itemDate)) {
        throw const ParseFailure('activity.checkin.day.date');
      }
      checkins.add(
        CheckInDay(
          date: itemDate,
          streakDay: _requiredInt(
            item,
            'streakDay',
            'activity.checkin.day.streakDay',
          ),
        ),
      );
    }
    if (!checkins.any((item) => item.date == date)) {
      throw const ParseFailure('activity.checkin.date.missing');
    }
    return CheckInAcknowledgment(
      date: date,
      currentStreak: _requiredInt(
        json,
        'currentStreak',
        'activity.checkin.currentStreak',
      ),
      longestStreak: _requiredInt(
        json,
        'longestStreak',
        'activity.checkin.longestStreak',
      ),
      showCelebration: _requiredBool(
        json,
        'showCelebration',
        'activity.checkin.showCelebration',
      ),
      checkins: checkins,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw ParseFailure(path);
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is! int) throw ParseFailure(path);
  return value;
}

bool _requiredBool(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is! bool) throw ParseFailure(path);
  return value;
}

bool _validDay(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse('${value}T00:00:00Z');
  return parsed != null &&
      '${parsed.year.toString().padLeft(4, '0')}-'
              '${parsed.month.toString().padLeft(2, '0')}-'
              '${parsed.day.toString().padLeft(2, '0')}' ==
          value;
}

String _shiftDay(String day, int offset) {
  final value = DateTime.parse('${day}T00:00:00Z').add(Duration(days: offset));
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
