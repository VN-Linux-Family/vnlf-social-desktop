import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/projects/detail/rating/project_rating_control.dart';

const initial = ProjectRatingSnapshot(average: 4, count: 1, myRating: 4, distribution: [0, 0, 0, 1, 0]);
Map<String, Object?> acknowledgement(int? score) => {
  'rating': {'average': score?.toDouble(), 'count': score == null ? 0 : 1},
  'myRating': score,
  'ratingDistribution': [for (var i = 1; i <= 5; i++) i == score ? 1 : 0],
};

class PendingRepository implements ProjectRatingRepository {
  final calls = <Completer<ProjectRatingSnapshot>>[];
  @override
  Future<ProjectRatingSnapshot> setRating(String projectId, int? score) {
    final call = Completer<ProjectRatingSnapshot>();
    calls.add(call);
    return call.future;
  }
}

void main() {
  test('PUT and DELETE send the confirmed contract exactly once', () async {
    final requests = <ApiRequest>[];
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (request) async {
      requests.add(request);
      return ApiResponse(statusCode: 200, body: jsonEncode(acknowledgement(request.method == 'PUT' ? 5 : null)));
    });
    final repo = ApiProjectRatingRepository(client);
    await repo.setRating('synthetic/id', 5);
    await repo.setRating('synthetic/id', null);
    expect(requests.map((r) => r.method), ['PUT', 'DELETE']);
    expect(requests.first.path, '/api/v1/projects/synthetic%2Fid/rating');
    expect(jsonDecode(requests.first.body!), {'score': 5});
    expect(requests.last.body, isNull);
  });

  test('failed write is not automatically retried', () async {
    var calls = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async {
      calls++;
      return ApiResponse(statusCode: 503, body: '{}');
    });
    await expectLater(ApiProjectRatingRepository(client).setRating('id', 3), throwsA(isA<HttpFailure>()));
    expect(calls, 1);
  });

  test('mismatched or malformed acknowledgements fail', () async {
    var payload = acknowledgement(4);
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async => ApiResponse(statusCode: 200, body: jsonEncode(payload)));
    final repo = ApiProjectRatingRepository(client);
    await expectLater(repo.setRating('id', 5), throwsA(isA<ParseFailure>()));
    payload = acknowledgement(5)..['ratingDistribution'] = [0, 0];
    await expectLater(repo.setRating('id', 5), throwsA(isA<ParseFailure>()));
  });

  test('account change invalidates in-flight result and blocks further writes', () async {
    final repo = PendingRepository();
    final controller = ProjectRatingController(repo, 'id', initial, true);
    final pending = controller.save(5);
    controller.invalidateSession();
    repo.calls.single.complete(const ProjectRatingSnapshot(average: 5, count: 1, myRating: 5, distribution: [0, 0, 0, 0, 1]));
    await pending;
    expect(controller.state.data.myRating, isNull);
    expect(controller.state.canRate, isFalse);
    await controller.save(3);
    expect(repo.calls.length, 1);
    controller.dispose();
  });

  test('stale replacement cannot overwrite a pending write', () async {
    final repo = PendingRepository();
    final controller = ProjectRatingController(repo, 'id', initial, true);
    final pending = controller.save(5);
    controller.replaceInitial(initial, true);
    repo.calls.single.complete(const ProjectRatingSnapshot(average: 5, count: 1, myRating: 5, distribution: [0, 0, 0, 0, 1]));
    await pending;
    controller.replaceInitial(initial, true); // A detail fetch started before the write returned late.
    expect(controller.state.data.myRating, 5);
    controller.dispose();
  });

  test('single flight ignores repeated taps and failures retain confirmed data', () async {
    final repo = PendingRepository();
    final controller = ProjectRatingController(repo, 'id', initial, true);
    final pending = controller.save(5);
    await controller.save(3);
    expect(repo.calls.length, 1);
    repo.calls.single.completeError(const TransportFailure());
    await pending;
    expect(controller.state.data.myRating, 4);
    expect(controller.state.error, isTrue);
    controller.dispose();
  });

  testWidgets('unauthorized viewers see summary but no controls', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(body: ProjectRatingControl(projectId: 'id', initialAverage: 4, initialCount: 1, initialMyRating: null, initialDistribution: [0, 0, 0, 1, 0], canRate: false)))));
    expect(find.byType(IconButton), findsNothing);
    expect(find.textContaining('4.0 / 5'), findsOneWidget);
  });

  testWidgets('failed interaction keeps confirmed choice and shows error', (tester) async {
    final repo = PendingRepository();
    await tester.pumpWidget(ProviderScope(overrides: [projectRatingRepositoryProvider.overrideWithValue(repo)], child: const MaterialApp(home: Scaffold(body: ProjectRatingControl(projectId: 'id', initialAverage: 4, initialCount: 1, initialMyRating: 4, initialDistribution: [0, 0, 0, 1, 0], canRate: true)))));
    await tester.tap(find.byTooltip('5 sao'));
    await tester.pump();
    repo.calls.single.completeError(const TransportFailure());
    await tester.pump();
    expect(find.textContaining('Không thể'), findsOneWidget);
    expect(find.text('Đánh giá của bạn: 4 / 5'), findsOneWidget);
  });
}
