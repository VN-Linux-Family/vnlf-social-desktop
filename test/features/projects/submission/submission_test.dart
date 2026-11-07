import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/projects/submission/project_submission.dart';
import 'package:vnlfsocialapp/src/features/projects/submission/project_submission_screen.dart';

final class _MemoryStorage implements SessionStorage {
  final data = <String, String>{};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

ProjectMediaFile _dummyFile({
  String name = 'preview.png',
  String mime = 'image/png',
  int length = 1024,
}) {
  return ProjectMediaFile(
    name: name,
    mime: mime,
    length: length,
    openRead: () => Stream.value(utf8.encode('image-bytes')),
  );
}

void main() {
  ProjectSubmissionInput valid() => const ProjectSubmissionInput(
    name: 'Dự án',
    tagline: 'Một dự án mã nguồn mở',
    intro: 'Giới thiệu dự án dài hơn ba mươi ký tự cho cộng đồng.',
    type: 'TOOL',
    relation: 'AUTHOR',
    repoUrl: '',
    noRepo: true,
    links: [ProjectSubmissionLink('WEBSITE', 'https://example.org')],
  );

  group('ProjectSubmissionInput and validation', () {
    test('requires an introduction and a link without a repository', () {
      final errors = const ProjectSubmissionInput(
        name: '',
        tagline: '',
        intro: 'ngắn',
        type: '',
        relation: '',
        repoUrl: '',
        noRepo: true,
      ).validate();
      expect(
        errors.keys,
        containsAll(['name', 'tagline', 'intro', 'type', 'relation', 'links']),
      );
      expect(valid().validate(), isEmpty);
    });

    test('validates repo url formats and prevents invalid domains', () {
      expect(
        projectRepositoryUrl('https://github.com/vnlf/client'),
        'https://github.com/vnlf/client',
      );
      expect(
        projectRepositoryUrl('git@github.com:vnlf/client.git'),
        'https://github.com/vnlf/client',
      );
      expect(projectRepositoryUrl('https://gitlab.com/vnlf/client'), isNull);
      expect(projectRepositoryUrl('https://github.com/explore'), isNull);
    });
  });

  group('LiveProjectSubmissionRepository contracts', () {
    test('strict acknowledgement accepts only a pending project identity', () async {
      var response =
          '{"id":"550e8400-e29b-41d4-a716-446655440000","slug":"du-an","status":"PENDING"}';
      final client = ApiClient(
        transport: (_) async => ApiResponse(statusCode: 201, body: response),
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final repository = LiveProjectSubmissionRepository(client);
      expect((await repository.create(valid())).slug, 'du-an');

      response = '{"slug":"du-an","status":"APPROVED"}';
      await expectLater(
        repository.create(valid()),
        throwsA(isA<ParseFailure>()),
      );
    });

    test('preview parses repo information', () async {
      final client = ApiClient(
        transport: (req) async {
          expect(req.path, '/api/v1/projects/repo-preview');
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'provider': 'GITHUB',
              'url': 'https://github.com/owner/repo',
              'name': 'repo',
              'stars': 42,
              'forks': 5,
              'description': 'A repo',
              'language': 'Dart',
            }),
          );
        },
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final repo = LiveProjectSubmissionRepository(client);
      final preview = await repo.preview('https://github.com/owner/repo');
      expect(preview.name, 'repo');
      expect(preview.stars, 42);
      expect(preview.forks, 5);
      expect(preview.language, 'Dart');
    });

    test('presignMedia, uploadMedia, and completeMedia lifecycle', () async {
      final uploadedUrls = <Uri>[];
      final client = ApiClient(
        transport: (req) async {
          if (req.path == '/api/v1/project-images/presign') {
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'assetId': '550e8400-e29b-41d4-a716-446655440001',
                'uploadUrl': 'https://upload.example.com/asset-1',
                'expiresIn': 300,
                'headers': {'x-amz-acl': 'public-read'},
              }),
            );
          } else if (req.path ==
              '/api/v1/project-images/550e8400-e29b-41d4-a716-446655440001/complete') {
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'assetId': '550e8400-e29b-41d4-a716-446655440001',
                'status': 'READY',
              }),
            );
          }
          throw UnimplementedError(req.path);
        },
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final repo = LiveProjectSubmissionRepository(
        client,
        transfer: (url, file, headers) async {
          uploadedUrls.add(url);
          expect(headers['x-amz-acl'], 'public-read');
        },
      );
      final file = _dummyFile();
      final pending = await repo.presignMedia(file: file, logo: true);
      expect(pending.assetId, '550e8400-e29b-41d4-a716-446655440001');
      await repo.uploadMedia(pending);
      expect(
        uploadedUrls,
        contains(Uri.parse('https://upload.example.com/asset-1')),
      );
      await repo.completeMedia(pending);
    });

    test('presignMedia rejects forbidden headers and CRLF injection', () async {
      final client = ApiClient(
        transport: (req) async => ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'assetId': '550e8400-e29b-41d4-a716-446655440001',
            'uploadUrl': 'https://upload.example.com/asset-1',
            'expiresIn': 300,
            'headers': {'Authorization': 'Bearer evil'},
          }),
        ),
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final repo = LiveProjectSubmissionRepository(client);
      await expectLater(
        repo.presignMedia(file: _dummyFile()),
        throwsA(isA<ParseFailure>()),
      );
    });
  });

  group('ProjectSubmissionDraftStore', () {
    test('persists and restores submission drafts with media', () async {
      final storage = _MemoryStorage();
      final store = SessionStorageProjectSubmissionDraftStore(storage);
      const draft = ProjectSubmissionDraft(
        name: 'Tên',
        tagline: 'Tagline',
        intro: 'Intro',
        type: 'APP',
        relation: 'MAINTAINER',
        repoUrl: 'https://github.com/owner/repo',
        logoAssetId: '550e8400-e29b-41d4-a716-446655440001',
        logoFileName: 'logo.png',
        mediaAssets: [
          (
            assetId: '550e8400-e29b-41d4-a716-446655440002',
            fileName: 'screen1.png',
          ),
        ],
        uncertain: false,
      );
      await store.write('user-1', draft);
      final restored = await store.read('user-1');
      expect(restored, isNotNull);
      expect(restored!.name, 'Tên');
      expect(restored.logoAssetId, '550e8400-e29b-41d4-a716-446655440001');
      expect(restored.logoFileName, 'logo.png');
      expect(restored.mediaAssets.length, 1);
      expect(
        restored.mediaAssets.first.assetId,
        '550e8400-e29b-41d4-a716-446655440002',
      );

      await store.delete('user-1');
      expect(await store.read('user-1'), isNull);
    });
  });

  group('ProjectSubmissionController', () {
    test(
      'uncertain response locks repeat submission and keeps draft',
      () async {
        var calls = 0;
        final storage = _MemoryStorage();
        final store = SessionStorageProjectSubmissionDraftStore(storage);
        final client = ApiClient(
          transport: (_) async {
            calls++;
            throw TimeoutException('lost');
          },
          throttleInterval: Duration.zero,
          hostKey: Object(),
        );
        final controller = ProjectSubmissionController(
          repository: LiveProjectSubmissionRepository(client),
          ownerId: 'one',
          currentOwner: () => 'one',
          draftStore: store,
        );
        controller.input = valid();
        await controller.submit();
        await controller.submit();
        expect(calls, 1);
        expect(controller.uncertain, isTrue);
        expect(controller.input.name, 'Dự án');

        final saved = await store.read('one');
        expect(saved, isNotNull);
        expect(saved!.uncertain, isTrue);
      },
    );

    test(
      'account switch during send cannot expose acknowledgement or resend',
      () async {
        final response = Completer<ApiResponse>();
        var owner = 'one';
        final client = ApiClient(
          transport: (_) => response.future,
          throttleInterval: Duration.zero,
          hostKey: Object(),
        );
        final controller = ProjectSubmissionController(
          repository: LiveProjectSubmissionRepository(client),
          ownerId: 'one',
          currentOwner: () => owner,
        );
        controller.input = valid();
        final pending = controller.submit();
        await Future<void>.delayed(Duration.zero);
        owner = 'two';
        client.invalidateSession();
        response.complete(
          ApiResponse(
            statusCode: 201,
            body: jsonEncode({
              'id': '550e8400-e29b-41d4-a716-446655440000',
              'slug': 'du-an',
              'status': 'PENDING',
            }),
          ),
        );
        await pending;
        expect(controller.receipt, isNull);
        expect(controller.uncertain, isTrue);
      },
    );

    test('uploadLogo and removeLogo updates input and draft store', () async {
      final storage = _MemoryStorage();
      final store = SessionStorageProjectSubmissionDraftStore(storage);
      final client = ApiClient(
        transport: (req) async {
          if (req.path == '/api/v1/project-images/presign') {
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'assetId': '550e8400-e29b-41d4-a716-446655440001',
                'uploadUrl': 'https://upload.example.com/logo',
                'expiresIn': 300,
                'headers': <String, dynamic>{},
              }),
            );
          } else if (req.path.endsWith('/complete')) {
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'assetId': '550e8400-e29b-41d4-a716-446655440001',
                'status': 'READY',
              }),
            );
          }
          throw UnimplementedError();
        },
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final controller = ProjectSubmissionController(
        repository: LiveProjectSubmissionRepository(
          client,
          transfer: (_, _, _) async {},
        ),
        ownerId: 'user-1',
        currentOwner: () => 'user-1',
        draftStore: store,
      );
      await controller.uploadLogo(_dummyFile(name: 'mylogo.png'));
      expect(
        controller.input.logoAssetId,
        '550e8400-e29b-41d4-a716-446655440001',
      );
      expect(controller.logoFileName, 'mylogo.png');

      var saved = await store.read('user-1');
      expect(saved?.logoAssetId, '550e8400-e29b-41d4-a716-446655440001');

      await controller.removeLogo();
      expect(controller.input.logoAssetId, isNull);
      expect(controller.logoFileName, isNull);

      saved = await store.read('user-1');
      expect(saved?.logoAssetId, isNull);
    });

    test('uploadScreenshot limits at 6 items', () async {
      final client = ApiClient(
        transport: (req) async {
          if (req.path == '/api/v1/project-images/presign') {
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'assetId': '550e8400-e29b-41d4-a716-446655440002',
                'uploadUrl': 'https://upload.example.com/screen',
                'expiresIn': 300,
                'headers': <String, dynamic>{},
              }),
            );
          } else if (req.path.endsWith('/complete')) {
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'assetId': '550e8400-e29b-41d4-a716-446655440002',
                'status': 'READY',
              }),
            );
          }
          throw UnimplementedError();
        },
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final controller = ProjectSubmissionController(
        repository: LiveProjectSubmissionRepository(
          client,
          transfer: (_, _, _) async {},
        ),
        ownerId: 'user-1',
        currentOwner: () => 'user-1',
      );
      for (var i = 0; i < 6; i++) {
        await controller.uploadScreenshot(_dummyFile(name: 's$i.png'));
      }
      expect(controller.mediaAssets.length, 6);
      await controller.uploadScreenshot(_dummyFile(name: 's7.png'));
      expect(controller.mediaAssets.length, 6);
      expect(controller.error, contains('Tối đa 6'));

      await controller.removeScreenshot(0);
      expect(controller.mediaAssets.length, 5);
    });
  });

  group('ProjectSubmissionScreen widget tests', () {
    testWidgets('loads and allows full submission with logo and media', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = _MemoryStorage();
      final client = ApiClient(
        transport: (req) async {
          if (req.path == '/api/v1/project-images/presign') {
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'assetId': '550e8400-e29b-41d4-a716-446655440001',
                'uploadUrl': 'https://upload.example.com/asset',
                'expiresIn': 300,
                'headers': <String, dynamic>{},
              }),
            );
          } else if (req.path.endsWith('/complete')) {
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'assetId': '550e8400-e29b-41d4-a716-446655440001',
                'status': 'READY',
              }),
            );
          } else if (req.path == '/api/v1/projects') {
            return ApiResponse(
              statusCode: 201,
              body: jsonEncode({
                'id': '550e8400-e29b-41d4-a716-446655440000',
                'slug': 'test-project',
                'status': 'PENDING',
              }),
            );
          }
          throw UnimplementedError(req.path);
        },
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final repo = LiveProjectSubmissionRepository(
        client,
        transfer: (_, _, _) async {},
      );

      String? submittedSlug;
      final session = const Session(
        userId: 'test-user',
        username: 'tester',
        displayName: 'Tester',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStateProvider.overrideWith((ref) => session),
            sessionStorageProvider.overrideWithValue(storage),
            projectSubmissionRepositoryProvider.overrideWithValue(repo),
            projectFilePickerProvider.overrideWithValue(
              () async => _dummyFile(name: 'logo.png'),
            ),
          ],
          child: MaterialApp(
            home: ProjectSubmissionScreen(
              onSubmitted: (slug) => submittedSlug = slug,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Giới thiệu dự án'), findsOneWidget);
      expect(find.text('Bước 1 / 3'), findsOneWidget);

      // Select relation
      await tester.tap(find.text('Vai trò của bạn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tác giả').last);
      await tester.pumpAndSettle();

      // Check no repo
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      // Enter name, tagline, intro
      await tester.enterText(
        find.widgetWithText(TextField, 'Tên dự án'),
        'VNLF Flutter',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mô tả ngắn'),
        'Native client cho cộng đồng',
      );

      // Select category
      await tester.tap(find.text('Thể loại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ứng dụng').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Giới thiệu dự án'),
        'Đây là phần giới thiệu dự án rất dài hơn ba mươi ký tự cho ứng dụng VNLF.',
      );
      await tester.pumpAndSettle();

      // Upload logo
      await tester.ensureVisible(find.text('Tải lên logo'));
      await tester.tap(find.text('Tải lên logo'));
      await tester.pumpAndSettle();
      expect(find.text('logo.png'), findsOneWidget);

      // Advance to step 2 (Links)
      await tester.ensureVisible(find.text('Tiếp tục'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Bước 2 / 3'), findsOneWidget);

      // Add a link
      await tester.ensureVisible(find.text('Thêm liên kết'));
      await tester.tap(find.text('Thêm liên kết'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'URL'),
        'https://vietnamlinuxfamily.net',
      );
      await tester.pumpAndSettle();

      // Advance to step 3 (Review)
      await tester.ensureVisible(find.text('Tiếp tục'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Bước 3 / 3'), findsOneWidget);
      expect(find.text('VNLF Flutter'), findsOneWidget);
      expect(find.text('Logo: logo.png'), findsOneWidget);

      // Submit
      await tester.ensureVisible(find.text('Gửi duyệt'));
      await tester.tap(find.text('Gửi duyệt'));
      await tester.pumpAndSettle();

      expect(submittedSlug, 'test-project');
      expect(find.text('Đã gửi dự án và đang chờ duyệt.'), findsOneWidget);
    });

    testWidgets('restores draft from store on screen mount', (tester) async {
      final storage = _MemoryStorage();
      final store = SessionStorageProjectSubmissionDraftStore(storage);
      await store.write(
        'test-user',
        const ProjectSubmissionDraft(
          name: 'Dự án đã lưu',
          tagline: 'Mô tả đã lưu',
          intro:
              'Phần giới thiệu đã được lưu lại trong session storage của máy.',
          type: 'TOOL',
          relation: 'MAINTAINER',
          noRepo: true,
          logoAssetId: '550e8400-e29b-41d4-a716-446655440001',
          logoFileName: 'saved_logo.png',
        ),
      );

      final session = const Session(
        userId: 'test-user',
        username: 'tester',
        displayName: 'Tester',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStateProvider.overrideWith((ref) => session),
            sessionStorageProvider.overrideWithValue(storage),
            projectSubmissionDraftStoreProvider.overrideWithValue(store),
          ],
          child: const MaterialApp(home: ProjectSubmissionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dự án đã lưu'), findsOneWidget);
      expect(find.text('saved_logo.png'), findsOneWidget);
    });
  });
}
