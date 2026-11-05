import '../../../core/api_client.dart';

final class ChannelMediaRepository {
  const ChannelMediaRepository(this._client);
  final ApiClient _client;
  Future<Uri> resolve(String path) {
    if (!RegExp(r'^/api/v1/assets/[a-zA-Z0-9_-]+/download$').hasMatch(path)) {
      throw const ParseFailure('attachment.downloadPath');
    }
    return _client.get(
      path,
      refresh: true,
      decode: (json) {
        final value = json['downloadUrl'];
        final uri = value is String ? Uri.tryParse(value) : null;
        if (uri == null ||
            uri.scheme != 'https' ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty) {
          throw const ParseFailure('attachment.downloadUrl');
        }
        return uri;
      },
    );
  }
}
