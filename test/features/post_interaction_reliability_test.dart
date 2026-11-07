import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/shared/presentation/post_interactions.dart';

void main() {
  test('post interactions clear on account change', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(postInteractionsProvider.notifier)
        .vote('fixture-post', VoteState.upvoted);
    expect(
      container.read(postInteractionProvider('fixture-post')).vote,
      VoteState.upvoted,
    );
    container.read(sessionStateProvider.notifier).state = const Session(
      userId: 'other',
      displayName: 'Other',
    );
    expect(
      container.read(postInteractionProvider('fixture-post')).vote,
      isNull,
    );
  });
}
