import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';

void main() {
  test(
    'repository providers expose local fixture data and unknowns safely',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final feed = await container.read(feedRepositoryProvider).getFeed();
      expect(feed.items.single.id, 'fixture-post-1');
      expect(
        (await container.read(postRepositoryProvider).getPost('fixture-post-1'))
            ?.id,
        'fixture-post-1',
      );
      expect(
        await container.read(postRepositoryProvider).getPost('missing'),
        isNull,
      );
      expect(
        await container.read(channelsRepositoryProvider).getChannels(),
        isEmpty,
      );
      expect(
        (await container.read(discoverRepositoryProvider).getProjects()).items,
        isEmpty,
      );
      expect(
        (await container.read(leaderboardsRepositoryProvider).getLeaderboard())
            .items,
        isEmpty,
      );
    },
  );

  testWidgets('post and profile routes pass identifiers to screen builders', (
    tester,
  ) async {
    final router = createAppRouter(
      screens: {
        for (final destination in VnlfNavDestination.values)
          destination: (_) => Text(destination.name),
      },
      postScreen: (_, id) => Text('post $id'),
      profileScreen: (_, username) => Text('profile $username'),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/posts/example');
    await tester.pumpAndSettle();
    expect(find.text('post example'), findsOneWidget);
    router.go('/users/an');
    await tester.pumpAndSettle();
    expect(find.text('profile an'), findsOneWidget);
  });
}
