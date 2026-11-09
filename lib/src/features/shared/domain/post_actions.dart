abstract interface class PostActionsRepository {
  Future<int> setVote(String id, int value);

  /// Saves the post when [saved], otherwise removes it from saved posts.
  Future<void> setBookmark(String id, {required bool saved});

  /// Deletes the viewer's own post.
  Future<void> deletePost(String id);

  /// Hides someone else's post from the viewer's feed.
  Future<void> hidePost(String id);
}
