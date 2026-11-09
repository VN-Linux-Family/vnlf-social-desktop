import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/shared/data/link_preview_repository.dart';
import 'package:vnlfsocialapp/src/features/shared/domain/link_preview.dart';

void main() {
  test('the first link is cleaned like the website does it', () {
    expect(
      firstContentLink('Xem (https://example.com/a_(b)).'),
      'https://example.com/a_(b)',
    );
    expect(
      firstContentLink('vào www.example.com nhé!'),
      'https://www.example.com',
    );
    expect(firstContentLink('không có liên kết'), isNull);
    expect(
      firstContentLink('ftp://example.com https://ok.vn'),
      'https://ok.vn',
    );
  });

  test('YouTube ids come from every link shape the website accepts', () {
    expect(youtubeVideoId('https://youtu.be/dQw4w9WgXcQ?t=5'), 'dQw4w9WgXcQ');
    expect(
      youtubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
      'dQw4w9WgXcQ',
    );
    expect(
      youtubeVideoId('https://m.youtube.com/shorts/dQw4w9WgXcQ'),
      'dQw4w9WgXcQ',
    );
    expect(youtubeVideoId('https://www.youtube.com/watch?v=short'), isNull);
    expect(youtubeVideoId('https://example.com/watch?v=dQw4w9WgXcQ'), isNull);
  });

  test('the repository reads the card and proxies its photo', () async {
    final requests = <ApiRequest>[];
    final repository = LiveLinkPreviewRepository(
      ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          requests.add(request);
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'preview': {
                'url': 'https://example.com/a',
                'title': 'Tiêu đề',
                'description': 'Mô tả',
                'siteName': 'Example',
                'imageUrl': 'https://example.com/a.png',
                'unknown': true,
              },
            }),
          );
        },
      ),
      baseUrl: 'https://vietnamlinuxfamily.net',
    );
    final preview = await repository.preview('https://example.com/a');
    expect(requests.single.path, '/api/v1/link-preview');
    expect(preview?.title, 'Tiêu đề');
    expect(
      repository.proxiedImage(preview!.imageUrl!),
      'https://vietnamlinuxfamily.net/api/v1/link-preview/image?url=https%3A%2F%2Fexample.com%2Fa.png',
    );
  });
}
