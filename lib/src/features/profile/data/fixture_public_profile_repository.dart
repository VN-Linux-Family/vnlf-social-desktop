import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../domain/public_profile.dart';

final class FixturePublicProfileRepository implements PublicProfileRepository {
  const FixturePublicProfileRepository({
    required this.feed,
    required this.rankings,
    required this.projects,
    required this.sampleAuthor,
    required this.samplePost,
  });
  final FeedRepository feed;
  final LeaderboardRepository rankings;
  final ProjectsRepository projects;
  final Author sampleAuthor;
  final FeedPost samplePost;

  @override
  Future<PublicProfile?> getProfile(String username) async {
    final (posts, leaders) = await (
      feed.getFeed(),
      rankings.getLeaderboard(),
    ).wait;
    final authors = [
      ...posts.items.map((post) => post.author),
      ...leaders.items.map(
        (item) => Author(
          id: item.userId,
          username: item.username,
          displayName: item.displayName,
          avatarUrl: item.avatarUrl,
          style: item.style,
        ),
      ),
      sampleAuthor,
    ];
    final author = authors
        .where((author) => author.username == username || author.id == username)
        .firstOrNull;
    if (author == null) return null;
    return PublicProfile(author: author, isSample: true);
  }

  @override
  Future<FeedPage> getPosts(String username) async => FeedPage(
    items: [
      ...(await feed.getFeed()).items.where(
        (post) => post.author.username == username,
      ),
      if (username == sampleAuthor.username) samplePost,
    ],
  );

  @override
  Future<ProjectsPage> getProjects(String username) async => ProjectsPage(
    items: (await projects.getProjects()).items
        .where((item) => item.owner?.username == username)
        .toList(),
  );

  @override
  Future<ProfileCommentsPage> getComments(String username) async =>
      ProfileCommentsPage(items: const []);

  @override
  Future<GuestbookPage> getGuestbook(String username, {String? cursor}) async =>
      GuestbookPage(items: const [], enabled: true, total: 0);
}
