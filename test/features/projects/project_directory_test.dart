import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/projects/data/project_directory_repository.dart';
import 'package:vnlfsocialapp/src/features/projects/domain/project_directory.dart';
import 'package:vnlfsocialapp/src/features/projects/presentation/project_directory_controller.dart';

class PendingRepository implements ProjectDirectoryRepository {
  final calls =
      <
        ({
          ProjectFilters filters,
          String? cursor,
          Completer<ProjectDirectoryPage> result,
        })
      >[];
  @override
  Future<ProjectDirectoryPage> fetch(
    ProjectFilters filters, {
    String? cursor,
    bool refresh = false,
  }) {
    final result = Completer<ProjectDirectoryPage>();
    calls.add((filters: filters, cursor: cursor, result: result));
    return result.future;
  }
}

ProjectDirectoryPage page(String id, {String? cursor}) => ProjectDirectoryPage(
  page: ProjectsPage(
    items: [ProjectItem(id: id, name: id)],
    nextCursor: cursor,
  ),
  types: const [],
  languages: const [],
);

void main() {
  test('adapter sends server filters and parses facets and cursor', () async {
    ApiRequest? sent;
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        sent = request;
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'items': <Object?>[],
            'nextCursor': '24',
            'facets': {
              'types': [
                {'type': 'TOOL', 'count': 2},
              ],
              'languages': [
                {'name': 'C++', 'count': 1, 'color': '#fff'},
              ],
            },
          }),
        );
      },
    );
    final result = await ApiProjectDirectoryRepository(client).fetch(
      const ProjectFilters(
        type: 'TOOL',
        language: 'C++',
        seeking: true,
        query: 'bộ gõ',
        sort: 'stars',
      ),
      cursor: '24',
    );
    expect(sent!.path, '/api/v1/projects');
    expect(sent!.query, {
      'type': 'TOOL',
      'language': 'C++',
      'seeking': '1',
      'q': 'bộ gõ',
      'sort': 'stars',
      'cursor': '24',
    });
    expect(result.page.nextCursor, '24');
    expect(result.types.single.count, 2);
    expect(result.languages.single.name, 'C++');
  });

  test('late responses cannot replace a newer filter', () async {
    final repo = PendingRepository();
    final controller = ProjectDirectoryController(repo);
    controller.setFilters(const ProjectFilters(language: 'Rust'));
    repo.calls[1].result.complete(page('new', cursor: '24'));
    await Future<void>.delayed(Duration.zero);
    repo.calls[0].result.complete(page('old'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.items.single.id, 'new');
    expect(controller.state.filters.language, 'Rust');
    controller.dispose();
  });

  test('pagination appends and rejects a repeated cursor', () async {
    final repo = PendingRepository();
    final controller = ProjectDirectoryController(repo);
    repo.calls[0].result.complete(page('first', cursor: '24'));
    await Future<void>.delayed(Duration.zero);
    final pending = controller.load(more: true);
    expect(repo.calls.last.cursor, '24');
    repo.calls.last.result.complete(page('second', cursor: '48'));
    await pending;
    expect(controller.state.items.map((item) => item.id), ['first', 'second']);
    final repeated = controller.load(more: true);
    repo.calls.last.result.complete(page('third', cursor: '24'));
    await repeated;
    expect(controller.state.items.map((item) => item.id), ['first', 'second']);
    expect(controller.state.error, isA<ParseFailure>());
    controller.dispose();
  });

  test('overlapping server pages keep one copy of each project', () async {
    final repo = PendingRepository();
    final controller = ProjectDirectoryController(repo);
    addTearDown(controller.dispose);
    repo.calls[0].result.complete(page('first', cursor: '24'));
    await Future<void>.delayed(Duration.zero);
    final pending = controller.load(more: true);
    repo.calls.last.result.complete(
      ProjectDirectoryPage(
        page: ProjectsPage(
          items: const [
            ProjectItem(id: 'first', name: 'first'),
            ProjectItem(id: 'second', name: 'second'),
          ],
        ),
        types: const [],
        languages: const [],
      ),
    );
    await pending;
    expect(controller.state.items.map((item) => item.id), ['first', 'second']);
  });

  test('a session change discards the previous response', () async {
    final repo = PendingRepository();
    final controller = ProjectDirectoryController(repo);
    controller.resetSession();
    repo.calls[0].result.complete(page('old'));
    repo.calls[1].result.complete(page('current'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.items.single.id, 'current');
    controller.dispose();
  });
}
