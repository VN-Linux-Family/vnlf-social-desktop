import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/link_preview.dart';

/// `GET /api/v1/link-preview?url=` → `{preview: {url, title, description,
/// siteName, imageUrl} | null}`; photos load through
/// `/api/v1/link-preview/image?url=`.
final class LiveLinkPreviewRepository implements LinkPreviewRepository {
  LiveLinkPreviewRepository(this._client, {required this.baseUrl});
  final ApiClient _client;
  final String baseUrl;

  @override
  Future<LinkPreview?> preview(String url) => _client.get<LinkPreview?>(
    '/api/v1/link-preview',
    query: {'url': url},
    decode: (json) {
      final preview = objectValue(json['preview'], 'linkPreview.preview');
      if (preview == null) return null;
      return LinkPreview(
        url: stringValue(preview['url'], 'linkPreview.url'),
        title: stringValue(preview['title'], 'linkPreview.title'),
        description: stringValue(
          preview['description'],
          'linkPreview.description',
        ),
        siteName: stringValue(preview['siteName'], 'linkPreview.siteName'),
        imageUrl: nullableString(preview['imageUrl'], 'linkPreview.imageUrl'),
      );
    },
  );

  @override
  String proxiedImage(String imageUrl) =>
      Uri.parse(baseUrl)
          .resolve('/api/v1/link-preview/image')
          .replace(queryParameters: {'url': imageUrl})
          .toString();
}

/// Offline fixtures have no link cards.
final class FixtureLinkPreviewRepository implements LinkPreviewRepository {
  const FixtureLinkPreviewRepository();
  @override
  Future<LinkPreview?> preview(String url) async => null;
  @override
  String proxiedImage(String imageUrl) => imageUrl;
}
