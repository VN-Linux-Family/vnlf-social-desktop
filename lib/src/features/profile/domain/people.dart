import '../../../domain/models.dart';

/// The two lists behind a profile's follow counts.
enum PeopleTab { followers, following }

/// One person in a followers or following list (`PersonRow`).
final class PersonRow {
  const PersonRow({
    required this.author,
    required this.followedByViewer,
    required this.isViewer,
  });

  final Author author;
  final bool followedByViewer;

  /// The signed-in member, who gets "Bạn" instead of a follow button.
  final bool isViewer;

  PersonRow following(bool value) =>
      PersonRow(author: author, followedByViewer: value, isViewer: isViewer);
}

final class PeoplePage {
  PeoplePage({required List<PersonRow> items, this.nextCursor})
    : items = List.unmodifiable(items);

  final List<PersonRow> items;
  final String? nextCursor;
}

/// Reads who follows a member and whom they follow, newest first.
abstract interface class PeopleRepository {
  Future<PeoplePage> list(String username, PeopleTab tab, {String? cursor});
}
