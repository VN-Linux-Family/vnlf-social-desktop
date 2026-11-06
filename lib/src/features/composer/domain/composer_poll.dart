import '../../polls/domain/poll_models.dart';

/// Unfinished editor input; validation happens only when sending to the server.
final class ComposerPollDraft {
  ComposerPollDraft(this.question, List<String> options)
    : options = List.unmodifiable(options);
  factory ComposerPollDraft.fromPoll(Poll poll) => ComposerPollDraft(
    poll.question,
    poll.options.map((option) => option.label).toList(),
  );
  final String question;
  final List<String> options;
  PollInput? get validated => PollInput.tryCreate(question, options);
  bool sameInput(ComposerPollDraft? other) =>
      other != null &&
      question == other.question &&
      options.length == other.options.length &&
      List.generate(
        options.length,
        (i) => options[i] == other.options[i],
      ).every((v) => v);
}
