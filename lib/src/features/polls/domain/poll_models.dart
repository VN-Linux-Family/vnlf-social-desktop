final class PollOption {
  const PollOption({
    required this.id,
    required this.label,
    required this.votes,
  });
  final String id;
  final String label;
  final int votes;
}

final class Poll {
  Poll({
    required this.id,
    required this.question,
    required List<PollOption> options,
    required this.totalVotes,
    this.viewerOptionId,
  }) : options = List.unmodifiable(options);
  final String id;
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final String? viewerOptionId;

  Poll withViewerSelection(String? optionId) => Poll(
    id: id,
    question: question,
    options: options,
    totalVotes: totalVotes,
    viewerOptionId: options.any((option) => option.id == optionId)
        ? optionId
        : null,
  );
}

/// Validated write input, kept separate from an incomplete editor draft.
final class PollInput {
  PollInput._(this.question, List<String> options)
    : options = List.unmodifiable(options);
  final String question;
  final List<String> options;
  static const questionLimit = 200;
  static const optionLimit = 100;
  static const minOptions = 2;
  static const maxOptions = 6;

  static PollInput? tryCreate(String question, List<String> options) {
    if (question.length > questionLimit ||
        options.length > maxOptions ||
        options.any((option) => option.length > optionLimit)) {
      return null;
    }
    String clean(String value) =>
        value.replaceAll(RegExp(r'\s+', unicode: true), ' ').trim();
    final normalizedQuestion = clean(question);
    final normalizedOptions = options
        .map(clean)
        .where((option) => option.isNotEmpty)
        .toSet()
        .toList();
    if (normalizedQuestion.isEmpty || normalizedOptions.length < minOptions) {
      return null;
    }
    return PollInput._(normalizedQuestion, normalizedOptions);
  }
}
