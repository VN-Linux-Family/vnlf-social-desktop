import 'dart:convert';
import 'dart:io';

/// Serves synthetic content in the observed public feed shape on loopback only.
Future<void> main() async {
  final rawPort = Platform.environment['VNLF_FAKE_SERVER_PORT'];
  final port = rawPort == null ? null : int.tryParse(rawPort);
  if (port == null || port < 0 || port > 65535) {
    stderr.writeln('Invalid fixture server port');
    exitCode = 64;
    return;
  }

  final feedFixture = await File.fromUri(Platform.script.resolve('feed.json'))
      .readAsString();
  final leaderboardsFixture = await File.fromUri(
    Platform.script.resolve('leaderboards.json'),
  ).readAsString();
  final projectsFixture = await File.fromUri(
    Platform.script.resolve('projects.json'),
  ).readAsString();
  final discoverFixture = await File.fromUri(
    Platform.script.resolve('discover.json'),
  ).readAsString();

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Fixture server listening on 127.0.0.1:${server.port}');
  await for (final request in server) {
    final response = request.response;
    response.headers.contentType = ContentType.json;
    if (request.method != 'GET') {
      response.statusCode = HttpStatus.methodNotAllowed;
      response.write(jsonEncode({'error': 'method_not_allowed'}));
    } else if (request.uri.path == '/api/v1/feed') {
      if (request.uri.queryParameters.containsKey('cursor')) {
        response.write(jsonEncode({'items': <Object>[], 'nextCursor': null}));
      } else {
        response.write(feedFixture);
      }
    } else if (request.uri.path == '/api/v1/leaderboards') {
      response.write(leaderboardsFixture);
    } else if (request.uri.path == '/api/v1/projects') {
      response.write(projectsFixture);
    } else if (request.uri.path == '/api/v1/discover') {
      response.write(discoverFixture);
    } else {
      response.statusCode = HttpStatus.notFound;
      response.write(jsonEncode({'error': 'fixture_not_found'}));
    }
    await response.close();
  }
}
