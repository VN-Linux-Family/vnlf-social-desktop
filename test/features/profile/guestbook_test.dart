import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/profile/data/live_guestbook_actions.dart';
import 'package:vnlfsocialapp/src/features/profile/data/live_public_profile_repository.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/public_profile.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_data.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_guestbook.dart';

const owner = Session(userId: 'owner', displayName: 'Owner');
const author = Session(userId: 'author', displayName: 'Author');
const other = Session(userId: 'other', displayName: 'Other');
const entry = GuestbookEntry(
  id: 'entry',
  author: Author(id: 'author', username: 'author', displayName: 'Author'),
  content: 'Synthetic message',
  status: GuestbookStatus.hidden,
);

class Profiles implements PublicProfileRepository {
  int reads = 0;
  bool mine = false;
  String? blockedReason = 'GUESTBOOK_OWN';
  String? reasonAfterFirstRead;
  bool failAfterFirstRead = false;
  @override
  Future<GuestbookPage> getGuestbook(String username, {String? cursor}) async {
    reads++;
    if (reads > 1 && failAfterFirstRead) throw StateError('read failed');
    if (reads > 1 && reasonAfterFirstRead != null) {
      blockedReason = reasonAfterFirstRead;
    }
    return GuestbookPage(
      items: [
        GuestbookEntry(
          id: entry.id,
          author: entry.author,
          content: entry.content,
          status: entry.status,
          mine: mine,
        ),
      ],
      enabled: true,
      total: 1,
      blockedReason: blockedReason,
    );
  }

  @override
  Future<PublicProfile?> getProfile(String username) =>
      throw UnimplementedError();
  @override
  Future<FeedPage> getPosts(String username) => throw UnimplementedError();
  @override
  Future<ProfileCommentsPage> getComments(String username) =>
      throw UnimplementedError();
  @override
  Future<ProjectsPage> getProjects(String username) =>
      throw UnimplementedError();
}

Future<ProviderContainer> pumpGuestbook(
  WidgetTester tester,
  Session session,
  Profiles profiles,
  ApiClient client,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionStateProvider.overrideWith((ref) => session),
        publicProfileRepositoryProvider.overrideWithValue(profiles),
        apiClientProvider.overrideWithValue(client),
        guestbookActionsEnabledProvider.overrideWithValue(true),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileGuestbook(username: 'owner', ownerId: 'owner'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(ProfileGuestbook)),
  );
}

ApiClient clientFor(ApiTransport transport) => ApiClient(
  transport: transport,
  hostKey: Object(),
  throttleInterval: Duration.zero,
);

void main() {
  test('hidden entries and blocked reason survive live decoding', () async {
    final client = clientFor(
      (request) async => ApiResponse(
        statusCode: 200,
        body: jsonEncode({
          'enabled': true,
          'total': 1,
          'nextCursor': null,
          'blockedReason': 'GUESTBOOK_OWN',
          'items': [
            {
              'id': 'entry',
              'author': {
                'id': 'author',
                'username': 'author',
                'displayName': 'Author',
              },
              'content': 'Hello',
              'status': 'HIDDEN',
              'mine': false,
              'createdAt': '2026-11-07T00:00:00Z',
            },
          ],
        }),
      ),
    );
    final page = await LivePublicProfileRepository(client)
        .getGuestbook('owner');
    expect(page.items.single.status, GuestbookStatus.hidden);
    expect(page.blockedReason, 'GUESTBOOK_OWN');
  });

  test(
    'malformed mutation acknowledgment fails and is never retried',
    () async {
      var calls = 0;
      final actions = LiveGuestbookActions(
        clientFor((request) async {
          calls++;
          return ApiResponse(statusCode: 200, body: '{"ok":false}');
        }),
      );
      await expectLater(actions.delete('entry'), throwsA(isA<ParseFailure>()));
      expect(calls, 1);
    },
  );

  testWidgets(
    'owner sees hidden note and moderation; author can only delete own note',
    (tester) async {
      final client = clientFor(
        (request) async => ApiResponse(statusCode: 200, body: '{"ok":true}'),
      );
      final profiles = Profiles();
      final container = await pumpGuestbook(tester, owner, profiles, client);
      expect(find.text('Hidden'), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Show'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Block this person'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      profiles.mine = true;
      container.read(sessionStateProvider.notifier).state = author;
      await tester.pumpAndSettle();
      // The server marks the viewer's own entry explicitly.
      // A non-owner must never gain owner controls from the entry status.
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Show'), findsNothing);
      expect(find.text('Block this person'), findsNothing);
      expect(find.text('Delete'), findsOneWidget);
    },
  );

  testWidgets('late write result is dropped after account change', (
    tester,
  ) async {
    final gate = Completer<ApiResponse>();
    var writes = 0;
    final client = clientFor((request) {
      writes++;
      return gate.future;
    });
    final profiles = Profiles();
    final container = await pumpGuestbook(tester, owner, profiles, client);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(writes, 1);
    expect(
      tester
          .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
          .enabled,
      isFalse,
    );
    container.read(sessionStateProvider.notifier).state = other;
    await tester.pump();
    gate.completeError(StateError('connection lost'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not confirm'), findsNothing);
    expect(writes, 1);
  });
  testWidgets('uncertain moderation refreshes and shows no success', (
    tester,
  ) async {
    var writes = 0;
    final client = clientFor((request) async {
      writes++;
      throw StateError('connection lost');
    });
    final profiles = Profiles();
    await pumpGuestbook(tester, owner, profiles, client);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(profiles.reads, greaterThan(1));
    expect(find.textContaining('Could not confirm'), findsOneWidget);
  });

  testWidgets('uncertain submission preserves the draft and refreshes', (
    tester,
  ) async {
    var writes = 0;
    final client = clientFor((request) async {
      writes++;
      throw StateError('connection lost');
    });
    final profiles = Profiles()..blockedReason = null;
    await pumpGuestbook(tester, other, profiles, client);
    await tester.enterText(find.byType(TextField), 'A synthetic greeting');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(profiles.reads, greaterThan(1));
    expect(find.text('A synthetic greeting'), findsOneWidget);
    expect(find.textContaining('Could not confirm'), findsOneWidget);
  });

  testWidgets('failed reconciliation still shows uncertainty and draft', (
    tester,
  ) async {
    final client = clientFor(
      (request) async => throw StateError('write failed'),
    );
    final profiles = Profiles()
      ..blockedReason = null
      ..failAfterFirstRead = true;
    await pumpGuestbook(tester, other, profiles, client);
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Keep this draft'), findsOneWidget);
    expect(find.textContaining('Could not confirm'), findsOneWidget);
  });

  testWidgets(
    'uncertain submission followed by daily limit keeps a copyable draft',
    (tester) async {
      final client = clientFor(
        (request) async => throw StateError('write failed'),
      );
      final profiles = Profiles()
        ..blockedReason = null
        ..reasonAfterFirstRead = 'GUESTBOOK_DAILY_LIMIT';
      await pumpGuestbook(tester, other, profiles, client);
      await tester.enterText(find.byType(TextField), 'Keep this draft');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Keep this draft'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      expect(find.textContaining('Could not confirm'), findsOneWidget);
    },
  );

  testWidgets(
    'acknowledged submission with failed refresh is reported accurately',
    (tester) async {
      final client = clientFor(
        (request) async => ApiResponse(
          statusCode: 201,
          body: jsonEncode({
            'id': 'new-entry',
            'author': {
              'id': 'other',
              'username': 'other',
              'displayName': 'Other',
            },
            'content': 'Hello',
            'status': 'VISIBLE',
            'mine': true,
            'createdAt': '2026-11-07T00:00:00Z',
          }),
        ),
      );
      final profiles = Profiles()
        ..blockedReason = null
        ..failAfterFirstRead = true;
      await pumpGuestbook(tester, other, profiles, client);
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Action confirmed'), findsOneWidget);
      expect(find.textContaining('Could not confirm'), findsNothing);
    },
  );
}
