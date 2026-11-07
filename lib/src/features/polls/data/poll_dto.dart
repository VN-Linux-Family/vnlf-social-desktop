import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/poll_models.dart';

final class PollDto {
  const PollDto(this.json);
  final Map<String, dynamic> json;
  static Poll? optional(Object? value) {
    final data = objectValue(value, 'poll');
    return data == null ? null : PollDto(data).toDomain();
  }

  Poll toDomain() {
    final id = _id(json['id'], 'poll.id');
    final question = stringValue(json['question'], 'poll.question');
    if (question.trim().isEmpty) throw const ParseFailure('poll.question');
    final options = objectList(json['options'], 'poll.options').map((item) {
      final votes = intValue(item['votes'], 'poll.option.votes');
      if (votes < 0) throw const ParseFailure('poll.option.votes');
      return PollOption(
        id: _id(item['id'], 'poll.option.id'),
        label: stringValue(item['label'], 'poll.option.label'),
        votes: votes,
      );
    }).toList();
    if (options.map((option) => option.id).toSet().length != options.length) {
      throw const ParseFailure('poll.options');
    }
    final total = intValue(json['totalVotes'], 'poll.totalVotes');
    if (total < 0) throw const ParseFailure('poll.totalVotes');
    final selected = nullableString(
      json['viewerOptionId'],
      'poll.viewerOptionId',
    );
    return Poll(
      id: id,
      question: question,
      options: options,
      totalVotes: total,
      viewerOptionId: selected?.isEmpty == true ? null : selected,
    );
  }

  Poll acknowledged() {
    if (json['question'] is! String ||
        json['options'] is! List ||
        json['totalVotes'] is! int ||
        !json.containsKey('viewerOptionId')) {
      throw const ParseFailure('poll.acknowledgment');
    }
    for (final option in objectList(json['options'], 'poll.options')) {
      if (option['id'] is! String ||
          option['label'] is! String ||
          option['votes'] is! int) {
        throw const ParseFailure('poll.option.acknowledgment');
      }
    }
    return toDomain();
  }
}

String _id(Object? value, String field) {
  final id = stringValue(value, field);
  if (id.isEmpty) throw ParseFailure(field);
  return id;
}
