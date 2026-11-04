import 'dart:convert';
import 'dart:io';

/// Serves synthetic content in the observed public feed shape on loopback only.
Future<void> main() async {
  final rawPort =
      Platform.environment['VNLF_FAKE_SERVER_PORT'] ??
      Platform.environment['FAKE_SERVER_PORT'] ??
      Platform.environment['PORT'] ??
      '8080';
  final port = int.tryParse(rawPort);
  if (port == null || port < 0 || port > 65535) {
    stderr.writeln('Invalid fixture server port');
    exitCode = 64;
    return;
  }

  final fixture = await File.fromUri(Platform.script.resolve('feed.json'))
      .readAsString();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Fixture server listening on 127.0.0.1:${server.port}');
  await for (final request in server) {
    final response = request.response;
    response.headers.contentType = ContentType.json;
    if (request.method != 'GET') {
      response.statusCode = HttpStatus.methodNotAllowed;
      response.write(jsonEncode({'error': 'method_not_allowed'}));
    } else if (request.uri.path != '/api/v1/feed') {
      response.statusCode = HttpStatus.notFound;
      response.write(jsonEncode({'error': 'fixture_not_found'}));
    } else if (request.uri.queryParameters.containsKey('cursor')) {
      response.write(jsonEncode({'items': <Object>[], 'nextCursor': null}));
    } else {
      response.write(fixture);
    }
    await response.close();
  }
}
