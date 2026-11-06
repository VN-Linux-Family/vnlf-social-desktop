import 'poll_models.dart';

abstract interface class PollRepository {
  Future<Poll> vote(String pollId, String? optionId);
  Future<Poll> edit(String pollId, PollInput input);
  Future<Poll?> setDraftPoll(String articleId, PollInput? input);
}
