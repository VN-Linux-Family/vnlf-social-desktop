import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/data/feed_dto.dart';
import 'package:vnlfsocialapp/src/data/json_object.dart';
import 'package:vnlfsocialapp/src/data/profile_dto.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';

void main() {
  group('tolerant DTO parsing', () {
    test(
      'feed ignores unknown fields and defaults nullable items and cursor',
      () {
        final page = FeedPageDto.fromJson(
          decodeJsonObject(
            '{"items": null, "nextCursor": null, "future": true}',
          ),
        ).toDomain();
        expect(page.items, isEmpty);
        expect(page.nextCursor, isNull);
      },
    );

    test('post ignores unknown fields and defaults null optional fields', () {
      final post = FeedPostDto.fromJson(
        decodeJsonObject(
          '{"id":"p1","excerpt":null,"voteScore":null,"commentCount":null,"author":null,"newField":{}}',
        ),
      ).toDomain();
      expect(post.id, 'p1');
      expect(post.excerpt, isEmpty);
      expect(post.voteScore, 0);
      expect(post.commentCount, 0);
      expect(post.author.username, isEmpty);
    });

    test('public author profile ignores unknown fields and handles nulls', () {
      final profile = ProfileDto.fromJson(
        decodeJsonObject('{"username":"an","displayName":null,"future":true}'),
      ).toDomain();
      expect(profile.username, 'an');
      expect(profile.displayName, 'an');
    });

    test('malformed JSON and non-object roots are typed parse failures', () {
      for (final input in ['{', '[]', 'null']) {
        expect(() => decodeJsonObject(input), throwsA(isA<ParseFailure>()));
      }
    });

    test('invalid feed, post, and profile fields produce typed failures', () {
      expect(
        () => FeedPageDto.fromJson({'items': 'bad'}),
        throwsA(isA<ParseFailure>()),
      );
      expect(
        () => FeedPostDto.fromJson({'id': null}),
        throwsA(isA<ParseFailure>()),
      );
      expect(
        () => ProfileDto.fromJson({'username': 42}),
        throwsA(isA<ParseFailure>()),
      );
    });
  });
}
