import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/projects/detail/data/project_detail_repository.dart';
import 'package:vnlfsocialapp/src/features/projects/detail/domain/project_detail.dart';
import 'package:vnlfsocialapp/src/features/projects/detail/presentation/project_detail_screen.dart';

Map<String, dynamic> fixture(String name) => {
  'id': 'project-id',
  'slug': 'du-an',
  'name': name,
  'tagline': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
  'intro': 'Giới thiệu',
  'owner': {'displayName': 'An', 'username': 'an'},
  'rating': {'average': 4.5, 'count': 2},
  'myRating': 5,
  'ratingDistribution': [0, 0, 0, 1, 1],
  'canRate': true,
  'links': [
    {'kind': 'WEBSITE', 'url': 'https://example.org'},
  ],
  'media': [
    {
      'url': 'https://example.org/small.webp',
      'fullUrl': 'https://example.org/full.webp',
      'width': 800,
      'height': 600,
    },
  ],
  'repo': {
    'owner': 'an',
    'name': 'du-an',
    'url': 'https://github.com/an/du-an',
    'stars': 2,
    'languages': [
      {'name': 'Dart'},
    ],
    'topics': ['linux'],
    'latestRelease': {'tag': 'v1', 'url': 'https://example.org/release'},
  },
  'discussion': {'slug': 'bai-viet'},
  'review': {'note': 'Chờ duyệt'},
};

class PendingRepository implements ProjectDetailRepository {
  final calls = <Completer<ProjectDetail>>[];
  @override
  Future<ProjectDetail> fetch(String slug, {bool refresh = false}) {
    final call = Completer<ProjectDetail>();
    calls.add(call);
    return call.future;
  }
}

void main() {
  test('fetch encodes slug and maps viewer-specific detail', () async {
    ApiRequest? sent;
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        sent = request;
        return ApiResponse(statusCode: 200, body: jsonEncode(fixture('Dự án')));
      },
    );
    final result = await ApiProjectDetailRepository(client).fetch('du an/1');
    expect(sent!.path, '/api/v1/projects/du%20an%2F1');
    expect(sent!.method, 'GET');
    expect(result.myRating, 5);
    expect(result.ratingDistribution, [0, 0, 0, 1, 1]);
    expect(result.media.single.fullUrl, 'https://example.org/full.webp');
    expect(result.repo!.languages, ['Dart']);
    expect(result.discussionSlug, 'bai-viet');
  });
  test('bad field types fail explicitly', () {
    final data = fixture('Dự án')..['ratingDistribution'] = [1, 'bad'];
    expect(
      () => ProjectDetailDto(data).toDomain(),
      throwsA(isA<ParseFailure>()),
    );
  });
  test('account change clears detail and ignores old response', () async {
    final repo = PendingRepository();
    final controller = ProjectDetailController(repo, 'du-an');
    controller.resetSession();
    expect(controller.state, isA<ProjectDetailLoading>());
    repo.calls[1].complete(ProjectDetailDto(fixture('Mới')).toDomain());
    await Future<void>.delayed(Duration.zero);
    repo.calls[0].complete(ProjectDetailDto(fixture('Cũ')).toDomain());
    await Future<void>.delayed(Duration.zero);
    expect((controller.state as ProjectDetailLoaded).project.name, 'Mới');
    controller.dispose();
  });
  test('404 is unavailable and other failures are reported', () async {
    final repo = PendingRepository();
    final controller = ProjectDetailController(repo, 'du-an');
    repo.calls[0].completeError(const HttpFailure(404));
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, isA<ProjectDetailEmpty>());
    final retry = controller.load();
    repo.calls[1].completeError(const TransportFailure());
    await retry;
    expect(controller.state, isA<ProjectDetailError>());
    controller.dispose();
  });
}
