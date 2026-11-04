import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/data/feed_dto.dart';
import 'package:vnlfsocialapp/src/data/leaderboard_dto.dart';
import 'package:vnlfsocialapp/src/data/projects_dto.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _singleItem(Map<String, dynamic> page) =>
    (page['items'] as List<dynamic>).single as Map<String, dynamic>;

void main() {
  group('FeedPostDto', () {
    test('maps every feed post and confirmed author field', () {
      final page = FeedPageDto.fromJson(_fixture('feed')).toDomain();
      final post = page.items.single;

      expect(page.nextCursor, isNull);
      expect(post.id, 'fixture-post-1');
      expect(post.excerpt, 'Chào cộng đồng! Tiếng Việt: ặ ữ ờ ẫ ệ');
      expect(post.voteScore, 3);
      expect(post.commentCount, 0);
      expect(post.title, 'Chào mừng đến với Vietnam Linux Family!');
      expect(post.slug, 'chao-mung-cong-dong-linux-viet-nam');
      expect(
        post.contentText,
        'Vietnam Linux Family là nơi chia sẻ kiến thức, kinh nghiệm cài đặt, tối ưu hóa các bản phân phối Linux và phát triển phần mềm mã nguồn mở. Tiếng Việt: ặ ữ ờ ẫ ệ.',
      );
      expect(
        post.contentHtml,
        '<p>Vietnam Linux Family là nơi chia sẻ kiến thức, kinh nghiệm cài đặt, tối ưu hóa các bản phân phối Linux và phát triển phần mềm mã nguồn mở. Tiếng Việt: ặ ữ ờ ẫ ệ.</p>',
      );
      expect(post.contentJson, {
        'type': 'doc',
        'content': [
          {
            'type': 'paragraph',
            'content': [
              {
                'type': 'text',
                'text': 'Vietnam Linux Family là nơi chia sẻ kiến thức. Tiếng Việt: ặ ữ ờ ẫ ệ.',
              },
            ],
          },
        ],
      });
      expect(post.coverUrl, isNull);
      expect(post.coverAlt, '');
      expect(post.format, 'post');
      expect(post.status, 'published');
      expect(post.version, 1);
      expect(post.likeCount, 12);
      expect(post.bookmarkCount, 8);
      expect(post.viewCount, 150);
      expect(post.viewerVote, 1);
      expect(post.viewerLiked, isTrue);
      expect(post.viewerBookmarked, isFalse);
      expect(post.canEdit, isFalse);
      expect(post.tagSlugs, ['linux', 'gioi-thieu', 'cong-dong']);
      expect(post.tags, ['Linux', 'Giới thiệu', 'Cộng đồng']);
      expect(post.publishedAt, DateTime.utc(2026, 11, 4, 12));
      expect(post.updatedAt, DateTime.utc(2026, 11, 4, 12, 30));

      final author = post.author;
      expect(author.id, 'user-synth-1');
      expect(author.username, 'thanhvien');
      expect(author.displayName, 'Thành viên');
      expect(
        author.avatarUrl,
        'https://vietnamlinuxfamily.net/assets/avatars/default.png',
      );
      expect(author.role, 'member');
      expect(author.style?.distroBadge, 'arch');
      expect(author.style?.frame, {
        'id': 'frame-terminal',
        'color': {'light': '#2563EB', 'dark': '#60A5FA'},
        'color2': null,
      });
      expect(author.style?.icon, {
        'name': 'tux',
        'url': 'https://vietnamlinuxfamily.net/assets/icons/tux.png',
        'pixelArt': true,
      });
      expect(author.style?.nameplate, {
        'id': 'np-default',
        'color': null,
        'name': null,
        'name2': null,
      });
      expect(author.style?.status, {
        'emoji': '🐧',
        'text': 'Đang dùng Arch Linux',
      });
    });

    test('ignores unknown feed and nested author fields', () {
      final json = _fixture('feed');
      json['futurePageField'] = true;
      final item = Map<String, dynamic>.from(_singleItem(json));
      item['futurePostField'] = {'ignored': true};
      final author = Map<String, dynamic>.from(item['author'] as Map);
      author['futureAuthorField'] = 42;
      item['author'] = author;
      json['items'] = [item];

      final post = FeedPageDto.fromJson(json).toDomain().items.single;
      expect(post.id, 'fixture-post-1');
      expect(post.author.username, 'thanhvien');
    });

    test('defaults nullable feed fields and optional author data', () {
      final post = FeedPostDto.fromJson({
        'id': 'post-nullables',
        'excerpt': null,
        'title': null,
        'contentJson': null,
        'coverUrl': null,
        'viewCount': null,
        'publishedAt': null,
        'updatedAt': null,
        'author': null,
      }).toDomain();

      expect(post.id, 'post-nullables');
      expect(post.excerpt, '');
      expect(post.title, isNull);
      expect(post.contentJson, isNull);
      expect(post.coverUrl, isNull);
      expect(post.viewCount, isNull);
      expect(post.publishedAt, isNull);
      expect(post.updatedAt, isNull);
      expect(post.author.username, '');
    });

    test('reports malformed feed field types as ParseFailure', () {
      final json = _fixture('feed');
      final item = Map<String, dynamic>.from(_singleItem(json));
      item['viewerLiked'] = 'true';
      json['items'] = [item];

      expect(
        () => FeedPageDto.fromJson(json),
        throwsA(
          isA<ParseFailure>().having(
            (failure) => failure.field,
            'field',
            'viewerLiked',
          ),
        ),
      );
    });
  });

  group('LeaderboardPageDto', () {
    test('maps every confirmed leaderboard and item field', () {
      final page = LeaderboardPageDto.fromJson(_fixture('leaderboards'))
          .toDomain();

      expect(page.period, 'week');
      expect(page.periodStart, DateTime.utc(2026, 11, 1));
      expect(page.periodEnd, DateTime.utc(2026, 11, 7, 23, 59, 59, 999));
      expect(page.computedAt, DateTime.utc(2026, 11, 4, 12));
      expect(page.items, hasLength(3));

      final first = page.items.first;
      expect(first.userId, 'user-synth-1');
      expect(first.username, 'hoangnam');
      expect(first.displayName, 'Hoàng Nam');
      expect(
        first.avatarUrl,
        'https://vietnamlinuxfamily.net/assets/avatars/user1.png',
      );
      expect(first.earnedPoints, 450);
      expect(first.rank, 1);
      expect(first.style?.distroBadge, 'arch');
      expect(first.style?.frame, {
        'id': 'frame-gold',
        'color': {'light': '#D97706', 'dark': '#F59E0B'},
        'color2': null,
      });
      expect(first.style?.icon, {
        'name': 'trophy',
        'url': 'https://vietnamlinuxfamily.net/assets/icons/trophy.png',
        'pixelArt': true,
      });
      expect(first.style?.nameplate, {
        'id': 'np-gold',
        'color': null,
        'name': null,
        'name2': null,
      });
      expect(first.style?.status, {'emoji': '👑', 'text': 'Top Contributor'});

      expect(page.items[1].style?.distroBadge, 'cachyos');
      expect(page.items[1].style?.frame?['id'], 'frame-silver');
      expect(page.items[1].style?.icon, isNull);
      expect(page.items[1].style?.nameplate, isNull);
      expect(page.items[2].style, isNotNull);
      expect(page.items[2].style?.distroBadge, 'debian');
      expect(page.items[2].style?.frame, isNull);
      expect(page.items[2].style?.status, isNull);
    });

    test('ignores unknown leaderboard fields and defaults nullable values', () {
      final json = {
        'period': 'all',
        'periodStart': null,
        'periodEnd': null,
        'computedAt': null,
        'futurePageField': 'ignored',
        'items': [
          {
            'userId': 'user-nullable',
            'username': 'linuxer',
            'displayName': null,
            'avatarUrl': null,
            'earnedPoints': null,
            'rank': null,
            'style': null,
            'futureItemField': true,
          },
        ],
      };

      final page = LeaderboardPageDto.fromJson(json).toDomain();
      final item = page.items.single;
      expect(page.periodStart, isNull);
      expect(page.periodEnd, isNull);
      expect(page.computedAt, isNull);
      expect(item.displayName, '');
      expect(item.avatarUrl, '');
      expect(item.earnedPoints, 0);
      expect(item.rank, 0);
      expect(item.style, isNull);
    });

    test('reports malformed leaderboard field types as ParseFailure', () {
      final json = _fixture('leaderboards');
      final item = Map<String, dynamic>.from(
        (json['items'] as List<dynamic>).first as Map<String, dynamic>,
      );
      item['rank'] = 'first';
      json['items'] = [item];

      expect(
        () => LeaderboardPageDto.fromJson(json),
        throwsA(
          isA<ParseFailure>().having(
            (failure) => failure.field,
            'field',
            'rank',
          ),
        ),
      );
    });
  });

  group('ProjectsPageDto', () {
    test('maps every confirmed project, owner, repository and rating field', () {
      final page = ProjectsPageDto.fromJson(_fixture('projects')).toDomain();
      expect(page.nextCursor, isNull);
      final project = page.items.single;

      expect(project.id, 'proj-synth-1');
      expect(project.name, 'vnlf-cli');
      expect(project.slug, 'vnlf-cli');
      expect(
        project.tagline,
        'Công cụ dòng lệnh quản lý gói và cấu hình Linux cộng đồng: ặ ữ ờ ẫ ệ',
      );
      expect(project.type, 'tool');
      expect(project.tier, 'community');
      expect(project.relation, 'owner');
      expect(project.seeking, isFalse);
      expect(project.featured, isTrue);
      expect(project.status, 'active');
      expect(
        project.logoUrl,
        'https://vietnamlinuxfamily.net/assets/projects/vnlf-cli.png',
      );
      expect(project.accentColor, '#2563EB');
      expect(project.commentCount, 12);
      expect(project.approvedAt, DateTime.utc(2026, 10, 15, 8));

      expect(project.owner?.id, 'user-synth-1');
      expect(project.owner?.username, 'hoangnam');
      expect(project.owner?.displayName, 'Hoàng Nam');
      expect(
        project.owner?.avatarUrl,
        'https://vietnamlinuxfamily.net/assets/avatars/user1.png',
      );
      expect(project.owner?.style, isNull);
      expect(project.repo, {
        'provider': 'github',
        'owner': 'vietnamlinuxfamily',
        'name': 'vnlf-cli',
        'url': 'https://github.com/vietnamlinuxfamily/vnlf-cli',
        'stars': 128,
        'forks': 24,
        'language': 'Dart',
        'languageColor': '#00B4AB',
        'archived': false,
        'fork': false,
        'pushedAt': '2026-11-03T18:00:00.000Z',
        'starsWeek': null,
        'unavailable': false,
      });
      expect(project.rating, {'average': 4.9, 'count': 35});
    });

    test('ignores unknown project fields and defaults nullable values', () {
      final json = {
        'items': [
          {
            'id': 'project-nullable',
            'name': 'project',
            'logoUrl': null,
            'accentColor': null,
            'owner': null,
            'repo': null,
            'rating': null,
            'approvedAt': null,
            'futureItemField': 'ignored',
          },
        ],
        'facets': {'languages': <String>[], 'types': <String>[]},
        'nextCursor': null,
        'futurePageField': true,
      };

      final page = ProjectsPageDto.fromJson(json).toDomain();
      final project = page.items.single;
      expect(project.logoUrl, isNull);
      expect(project.accentColor, isNull);
      expect(project.owner, isNull);
      expect(project.repo, isNull);
      expect(project.rating, isNull);
      expect(project.approvedAt, isNull);
      expect(page.nextCursor, isNull);
    });

    test('reports malformed project field types as ParseFailure', () {
      final json = _fixture('projects');
      final item = Map<String, dynamic>.from(_singleItem(json));
      item['seeking'] = 'false';
      json['items'] = [item];

      expect(
        () => ProjectsPageDto.fromJson(json),
        throwsA(
          isA<ParseFailure>().having(
            (failure) => failure.field,
            'field',
            'seeking',
          ),
        ),
      );
    });
  });
}
