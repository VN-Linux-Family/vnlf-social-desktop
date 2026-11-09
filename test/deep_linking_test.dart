import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/core/vnlf_navigation_helper.dart';
import 'package:vnlfsocialapp/src/design_system/components/vnlf_post_card.dart';
import 'package:vnlfsocialapp/src/design_system/components/vnlf_shell.dart';
import 'package:vnlfsocialapp/src/design_system/models/vnlf_models.dart';

void main() {
  group('resolveInAppVnlfRoute', () {
    test('resolves article and post deep links correctly', () {
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/a/slug-123'),
        ),
        '/thread/slug-123',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://www.vietnamlinuxfamily.net/article/art-456'),
        ),
        '/thread/art-456',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/articles/art-456'),
        ),
        '/thread/art-456',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/posts/post-789'),
        ),
        '/thread/post-789',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/thread/t-101'),
        ),
        '/thread/t-101',
      );
    });

    test('resolves user profile links with optional tabs', () {
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/user/alice'),
        ),
        '/profile/alice',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/users/bob?tab=guestbook'),
        ),
        '/profile/bob?tab=guestbook',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/u/charlie'),
        ),
        '/profile/charlie',
      );
    });

    test('resolves projects and explore routes', () {
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/projects/mechvibes'),
        ),
        '/projects/mechvibes',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/project/mechvibes'),
        ),
        '/projects/mechvibes',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/projects/submit'),
        ),
        '/projects/submit',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/projects'),
        ),
        '/projects',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/explore'),
        ),
        '/discover',
      );
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/discover'),
        ),
        '/discover',
      );
    });

    test('resolves custom vnlf:// scheme', () {
      expect(
        resolveInAppVnlfRoute(Uri.parse('vnlf://thread/abc')),
        '/thread/abc',
      );
      expect(
        resolveInAppVnlfRoute(Uri.parse('vnlf://projects/xyz')),
        '/projects/xyz',
      );
    });

    test('resolves relative paths', () {
      expect(resolveInAppVnlfRoute(Uri.parse('/a/my-slug')), '/thread/my-slug');
      expect(
        resolveInAppVnlfRoute(Uri.parse('/projects/mechvibes')),
        '/projects/mechvibes',
      );
    });

    test('returns null for external hosts and non-native pages', () {
      expect(
        resolveInAppVnlfRoute(Uri.parse('https://github.com/flutter/flutter')),
        isNull,
      );
      expect(resolveInAppVnlfRoute(Uri.parse('https://google.com')), isNull);
      expect(
        resolveInAppVnlfRoute(
          Uri.parse('https://vietnamlinuxfamily.net/caramos'),
        ),
        isNull,
      );
    });
  });

  group('Main router deep-link routes', () {
    testWidgets(
      'router handles /a/:id and /users/:id web aliases without error',
      (tester) async {
        final container = ProviderContainer(overrides: []);
        addTearDown(container.dispose);

        final router = createMainRouter();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('vi')],
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Deep link to /a/article-1
        router.go('/a/article-1');
        await tester.pumpAndSettle();
        expect(find.byType(VnlfAdaptiveShell), findsOneWidget);

        // Deep link to /users/linus
        router.go('/users/linus');
        await tester.pumpAndSettle();
        expect(find.byType(VnlfAdaptiveShell), findsOneWidget);

        // Deep link to /project/mechvibes
        router.go('/project/mechvibes');
        await tester.pumpAndSettle();
        expect(find.byType(VnlfAdaptiveShell), findsOneWidget);
      },
    );
  });

  group('VnlfPostCard link parsing', () {
    testWidgets('renders clickable URL in post paragraph', (tester) async {
      final post = PostData(
        id: '1',
        title: 'Post with link',
        paragraphs: const [
          'Check out https://vietnamlinuxfamily.net/a/awesome for details',
        ],
        author: const AuthorData(
          id: 'u1',
          displayName: 'Test User',
          username: 'tester',
        ),
        relativeTime: '1m',
        voteScore: 5,
        commentCount: 2,
        viewerVote: VoteState.neutral,
        isBookmarked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VnlfPostCard(post: post)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('https://vietnamlinuxfamily.net/a/awesome'),
        findsOneWidget,
      );
    });
  });
}
