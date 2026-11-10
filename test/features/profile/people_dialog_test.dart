import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/people.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/profile_relationship.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/people_dialog.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_relationship_controller.dart';

PersonRow _person(String id, {bool followed = false, bool viewer = false}) =>
    PersonRow(
      author: Author(id: id, username: id, displayName: 'Người $id'),
      followedByViewer: followed,
      isViewer: viewer,
    );

void main() {
  late _People people;
  late _Relationships relationships;

  setUp(() {
    people = _People();
    relationships = _Relationships();
  });

  Future<void> pump(WidgetTester tester, {Session? session}) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPeopleDialog(
                  context,
                  username: 'an',
                  name: 'Nguyễn An',
                  initial: PeopleTab.followers,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/profile/:id',
          builder: (context, state) =>
              Text('profile ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith((ref) => session),
          peopleRepositoryProvider.overrideWithValue(people),
          profileRelationshipRepositoryProvider.overrideWithValue(
            relationships,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists followers with follow buttons for a member', (
    tester,
  ) async {
    people.pages[(PeopleTab.followers, null)] = PeoplePage(
      items: [_person('lan', viewer: true), _person('minh')],
      nextCursor: 'page-2',
    );
    people.pages[(PeopleTab.followers, 'page-2')] = PeoplePage(
      items: [_person('hoa', followed: true)],
    );
    await pump(
      tester,
      session: const Session(userId: 'lan', displayName: 'Người lan'),
    );

    expect(find.text('Theo dõi của Nguyễn An'), findsOneWidget);
    expect(find.text('Bạn'), findsOneWidget);
    expect(find.text('@minh'), findsOneWidget);
    await tester.tap(find.text('Xem thêm'));
    await tester.pumpAndSettle();
    expect(people.requests.last, (PeopleTab.followers, 'page-2'));
    expect(find.text('@hoa'), findsOneWidget);
    expect(find.text('Xem thêm'), findsNothing);

    await tester.tap(find.text('Theo dõi'));
    await tester.pumpAndSettle();
    expect(relationships.calls, ['follow:minh']);
    expect(find.text('Đang theo dõi'), findsNWidgets(3));
  });

  testWidgets('a guest sees the lists without follow buttons', (tester) async {
    people.pages[(PeopleTab.followers, null)] = PeoplePage(
      items: [_person('minh')],
    );
    await pump(tester);
    expect(find.text('@minh'), findsOneWidget);
    expect(find.text('Theo dõi'), findsNothing);
  });

  testWidgets('switching tabs loads the other list', (tester) async {
    people.pages[(PeopleTab.followers, null)] = PeoplePage(items: const []);
    people.pages[(PeopleTab.following, null)] = PeoplePage(items: const []);
    await pump(tester);
    expect(find.text('Chưa có ai theo dõi.'), findsOneWidget);
    await tester.tap(find.text('Đang theo dõi'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa theo dõi ai.'), findsOneWidget);
    expect(people.requests.map((request) => request.$1), [
      PeopleTab.followers,
      PeopleTab.following,
    ]);
  });

  testWidgets('a failed list offers a retry', (tester) async {
    await pump(tester);
    expect(find.text('Chưa tải được danh sách.'), findsOneWidget);
    people.pages[(PeopleTab.followers, null)] = PeoplePage(
      items: [_person('minh')],
    );
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('@minh'), findsOneWidget);
  });

  testWidgets('a row opens the profile and closes the dialog', (tester) async {
    people.pages[(PeopleTab.followers, null)] = PeoplePage(
      items: [_person('minh')],
    );
    await pump(tester);
    await tester.tap(find.text('@minh'));
    await tester.pumpAndSettle();
    expect(find.text('profile minh'), findsOneWidget);
    expect(find.text('Theo dõi của Nguyễn An'), findsNothing);
  });
}

class _People implements PeopleRepository {
  final pages = <(PeopleTab, String?), PeoplePage>{};
  final requests = <(PeopleTab, String?)>[];

  @override
  Future<PeoplePage> list(
    String username,
    PeopleTab tab, {
    String? cursor,
  }) async {
    requests.add((tab, cursor));
    return pages[(tab, cursor)] ?? (throw const TransportFailure());
  }
}

class _Relationships implements ProfileRelationshipRepository {
  final calls = <String>[];

  @override
  Future<void> setFollowing(String userId, {required bool following}) async =>
      calls.add('${following ? 'follow' : 'unfollow'}:$userId');

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) async =>
      calls.add('${blocked ? 'block' : 'unblock'}:$userId');
}
