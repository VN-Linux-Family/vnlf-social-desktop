import '../../../core/api_client.dart';
import '../../../data/feed_dto.dart';
import '../../../data/field_reader.dart';
import '../../../data/profile_dto.dart';
import '../../../data/projects_dto.dart';
import '../../../domain/models.dart';
import '../domain/public_profile.dart';

final class LivePublicProfileRepository implements PublicProfileRepository {
  const LivePublicProfileRepository(this._client);
  final ApiClient _client;
  String _userPath(String username) =>
      '/api/v1/users/${Uri.encodeComponent(username)}';

  @override
  Future<PublicProfile?> getProfile(String username) async {
    try {
      return await _client.get(
        _userPath(username),
        decode: (json) {
          final decor = objectValue(json['decor'], 'profile.decor');
          final cover = objectValue(decor?['cover'], 'profile.decor.cover');
          return PublicProfile(
            author: ProfileDto.fromJson(json).toDomain(),
            bio: nullableString(json['bio'], 'profile.bio'),
            totalPoints: nullableInt(
              json['totalPoints'],
              'profile.totalPoints',
            ),
            level: nullableInt(json['level'], 'profile.level'),
            currentStreak: nullableInt(
              json['currentStreak'],
              'profile.currentStreak',
            ),
            followerCount: nullableInt(
              json['followerCount'],
              'profile.followerCount',
            ),
            followingCount: nullableInt(
              json['followingCount'],
              'profile.followingCount',
            ),
            coverUrl: nullableString(
              cover?['imageUrl'],
              'profile.decor.cover.imageUrl',
            ),
            guestbookEnabled: decor?['guestbookEnabled'] == null
                ? true
                : boolValue(
                    decor?['guestbookEnabled'],
                    'profile.decor.guestbookEnabled',
                  ),
            followedByViewer: json['followedByViewer'] == null
                ? null
                : boolValue(
                    json['followedByViewer'],
                    'profile.followedByViewer',
                  ),
            blockedByViewer: json['blockedByViewer'] == null
                ? null
                : boolValue(json['blockedByViewer'], 'profile.blockedByViewer'),
            decor: decor == null ? const ProfileDecor() : _decor(decor),
          );
        },
      );
    } on HttpFailure catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  static ProfileDecor _decor(Map<String, Object?> decor) {
    final theme = objectValue(decor['theme'], 'profile.decor.theme');
    final cover = objectValue(decor['cover'], 'profile.decor.cover');
    final status = objectValue(decor['status'], 'profile.decor.status');
    final discord = objectValue(decor['discord'], 'profile.decor.discord');
    final visits = objectValue(decor['visits'], 'profile.decor.visits');
    final links = decor['links'];
    return ProfileDecor(
      themeId: nullableString(theme?['id'], 'profile.decor.theme.id') ?? 'vnlf',
      accentColor: nullableString(
        theme?['accentColor'],
        'profile.decor.theme.accentColor',
      ),
      coverSmallUrl: nullableString(
        cover?['smallUrl'],
        'profile.decor.cover.smallUrl',
      ),
      status: status == null
          ? null
          : (
              emoji:
                  nullableString(
                    status['emoji'],
                    'profile.decor.status.emoji',
                  ) ??
                  '',
              text:
                  nullableString(status['text'], 'profile.decor.status.text') ??
                  '',
            ),
      // Links come back to the screen as typed URLs and are checked again
      // there, as the website does; a malformed entry is left out.
      links: [
        if (links is List)
          for (final link in links)
            if (link is Map && link['url'] is String) link['url'] as String,
      ],
      discordUsername: nullableString(
        discord?['username'],
        'profile.decor.discord.username',
      ),
      visits: visits == null
          ? null
          : (
              count:
                  nullableInt(visits['count'], 'profile.decor.visits.count') ??
                  0,
              hidden: visits['hidden'] == true,
            ),
    );
  }

  @override
  Future<FeedPage> getPosts(String username) => _client.get(
    '${_userPath(username)}/articles',
    query: const {'limit': '50'},
    decode: (json) => FeedPageDto.fromJson(json).toDomain(),
  );

  @override
  Future<ProfileCommentsPage> getComments(String username) => _client.get(
    '${_userPath(username)}/comments',
    query: const {'limit': '50'},
    decode: (json) => ProfileCommentsPage(
      items: objectList(json['items'], 'comments.items')
          .map(
            (item) => ProfileComment(
              id: stringValue(item['id'], 'comment.id'),
              articleId: stringValue(item['articleId'], 'comment.articleId'),
              articleSlug: stringValue(
                item['articleSlug'],
                'comment.articleSlug',
              ),
              content: stringValue(item['content'], 'comment.content'),
              createdAt: dateValue(item['createdAt'], 'comment.createdAt'),
            ),
          )
          .toList(),
      nextCursor: nullableString(json['nextCursor'], 'comments.nextCursor'),
    ),
  );

  @override
  Future<ProjectsPage> getProjects(String username) => _client.get(
    '${_userPath(username)}/projects',
    decode: (json) => ProjectsPageDto.fromJson(json).toDomain(),
  );

  @override
  Future<GuestbookPage> getGuestbook(
    String username, {
    String? cursor,
  }) => _client.get(
    '/api/v1/profiles/${Uri.encodeComponent(username)}/guestbook',
    query: {'cursor': ?cursor},
    decode: (json) => GuestbookPage(
      enabled: boolValue(json['enabled'], 'guestbook.enabled'),
      total: intValue(json['total'], 'guestbook.total'),
      nextCursor: nullableString(json['nextCursor'], 'guestbook.nextCursor'),
      blockedReason: json.containsKey('blockedReason')
          ? nullableString(json['blockedReason'], 'guestbook.blockedReason')
          : 'UNKNOWN',
      items: objectList(json['items'], 'guestbook.items')
          .map(
            (item) => GuestbookEntry(
              id: stringValue(item['id'], 'guestbook.entry.id'),
              author: ProfileDto.fromJson(
                objectValue(item['author'], 'guestbook.entry.author') ??
                    const {},
              ).toDomain(),
              content: stringValue(item['content'], 'guestbook.entry.content'),
              status: switch (item['status']) {
                'VISIBLE' => GuestbookStatus.visible,
                'HIDDEN' => GuestbookStatus.hidden,
                _ => throw const ParseFailure('guestbook.entry.status'),
              },
              mine: boolValue(item['mine'], 'guestbook.entry.mine'),
              createdAt: dateValue(
                item['createdAt'],
                'guestbook.entry.createdAt',
              ),
            ),
          )
          .toList(),
    ),
  );
}
