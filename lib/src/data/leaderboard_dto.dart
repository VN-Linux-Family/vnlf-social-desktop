import '../domain/models.dart';
import 'field_reader.dart';

final class LeaderboardItemDto {
  LeaderboardItemDto._(this._json);
  factory LeaderboardItemDto.fromJson(Map<String, dynamic> json) {
    final dto = LeaderboardItemDto._(objectValue(json, 'item')!);
    dto.toDomain();
    return dto;
  }
  final Map<String, dynamic> _json;
  LeaderboardItem toDomain() => LeaderboardItem(
    userId: stringValue(_json['userId'], 'userId'),
    username: stringValue(_json['username'], 'username'),
    displayName: stringValue(_json['displayName'], 'displayName'),
    avatarUrl: stringValue(_json['avatarUrl'], 'avatarUrl'),
    earnedPoints: intValue(_json['earnedPoints'], 'earnedPoints'),
    rank: intValue(_json['rank'], 'rank'),
    style: styleValue(_json['style'], 'style'),
  );
}

final class LeaderboardPageDto {
  LeaderboardPageDto.fromJson(Map<String, dynamic> json)
    : period = stringValue(json['period'], 'period'),
      periodStart = dateValue(json['periodStart'], 'periodStart'),
      periodEnd = dateValue(json['periodEnd'], 'periodEnd'),
      computedAt = dateValue(json['computedAt'], 'computedAt'),
      items = objectList(
        json['items'],
        'items',
      ).map(LeaderboardItemDto.fromJson).toList(growable: false);
  final String period;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? computedAt;
  final List<LeaderboardItemDto> items;
  LeaderboardPage toDomain() => LeaderboardPage(
    period: period,
    periodStart: periodStart,
    periodEnd: periodEnd,
    computedAt: computedAt,
    items: items.map((item) => item.toDomain()).toList(),
  );
}
