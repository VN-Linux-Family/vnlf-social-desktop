import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/channels/data/channel_media_repository.dart';

void main() {
  test('private media resolves the scoped download envelope through authenticated API transport', () async {
    ApiRequest? request;
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (value) async {
        request = value;
        return ApiResponse(
          statusCode: 200,
          body: '{"downloadUrl":"https://media.example.invalid/synthetic.png","expiresIn":3600}',
        );
      },
    );
    final url = await ChannelMediaRepository(client)
        .resolve('/api/v1/assets/synthetic/download');
    expect(request!.path, '/api/v1/assets/synthetic/download');
    expect(url.toString(), 'https://media.example.invalid/synthetic.png');
  });
  test('untrusted download paths never reach the API transport', () async {
    var calls = 0;
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async {
        calls++;
        return ApiResponse(statusCode: 200, body: '{}');
      },
    );
    expect(
      () =>
          ChannelMediaRepository(client)
              .resolve('https://example.invalid/steal'),
      throwsA(isA<ParseFailure>()),
    );
    expect(calls, 0);
  });
}
