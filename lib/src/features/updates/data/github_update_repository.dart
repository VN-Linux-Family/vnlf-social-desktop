import 'dart:convert';
import 'dart:io';

import '../domain/app_update.dart';

final class ReleaseResponse {
  const ReleaseResponse(this.status, this.body);
  final int status;
  final String body;
}

typedef ReleaseTransport = Future<ReleaseResponse> Function(Uri uri);

final class GitHubUpdateRepository implements UpdateRepository {
  GitHubUpdateRepository({
    ReleaseTransport? transport,
    this.repository = 'VN-Linux-Family/vnlf-social-desktop',
  }) : _transport = transport ?? _getRelease;
  final ReleaseTransport _transport;
  final String repository;

  Uri _trustedLink(Object? value) {
    if (value is! String) throw const UpdateFailure();
    final uri = Uri.tryParse(value);
    final repo = repository.toLowerCase().split('/');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'github.com' ||
        uri.userInfo.isNotEmpty ||
        uri.pathSegments.length < 4 ||
        uri.pathSegments[0].toLowerCase() != repo[0] ||
        uri.pathSegments[1].toLowerCase() != repo[1] ||
        uri.pathSegments[2] != 'releases') {
      throw const UpdateFailure();
    }
    return uri;
  }

  @override
  Future<AppUpdate> check(
    String currentVersion,
    UpdatePlatform platform,
  ) async {
    try {
      if (!RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(repository)) {
        throw const UpdateFailure();
      }
      final response = await _transport(
        Uri.https('api.github.com', '/repos/$repository/releases/latest'),
      );
      if (response.status == 404) return const UpdateUnavailable();
      if (response.status != 200) throw UpdateFailure(response.status);
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) throw const UpdateFailure();
      if (json['draft'] == true || json['prerelease'] == true) {
        return const UpdateUnavailable();
      }
      final tag = json['tag_name'];
      if (tag is! String) throw const UpdateFailure();
      final version = tag.startsWith('v') ? tag.substring(1) : tag;
      if (ReleaseVersion.parse(version)
              .compareTo(ReleaseVersion.parse(currentVersion)) <=
          0) {
        return const UpdateCurrent();
      }
      final page = _trustedLink(json['html_url']);
      UpdateAsset? selected;
      for (final asset
          in (json['assets'] as List? ?? [])
              .whereType<Map<String, dynamic>>()) {
        if (asset['name'] ==
            'vnlf-social-$version-${platform.os}-${platform.arch}.${platform.extension}') {
          selected = UpdateAsset(
            asset['name'] as String,
            _trustedLink(asset['browser_download_url']),
          );
          break;
        }
      }
      return UpdateAvailable(
        version: version,
        releasePage: page,
        asset: selected,
      );
    } on UpdateFailure {
      rethrow;
    } catch (_) {
      throw const UpdateFailure();
    }
  }
}

Future<ReleaseResponse> _getRelease(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 10));
    request.followRedirects = false;
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'VNLF-Social-App update checker',
    );
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );
    final response = await request.close().timeout(const Duration(seconds: 10));
    if (response.contentLength > 1024 * 1024) throw const UpdateFailure();
    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 10));
    if (body.length > 1024 * 1024) throw const UpdateFailure();
    return ReleaseResponse(response.statusCode, body);
  } on UpdateFailure {
    rethrow;
  } catch (_) {
    throw const UpdateFailure();
  } finally {
    client.close(force: true);
  }
}
