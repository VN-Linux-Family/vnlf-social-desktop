abstract interface class PostActionsRepository {
  Future<int> setVote(String id, int value);
  Future<void> toggleBookmark(String id);
}
