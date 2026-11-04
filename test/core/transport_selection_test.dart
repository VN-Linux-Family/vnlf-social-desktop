import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';

void main() {
  test('live transport is created only when explicitly enabled', () {
    var clientsCreated = 0;
    HttpOverrides.runZoned(
      () {
        final container = ProviderContainer();
        container.read(apiClientProvider);
        container.dispose();
      },
      createHttpClient: (_) {
        clientsCreated++;
        return _HttpClient();
      },
    );
    expect(clientsCreated, const bool.fromEnvironment('VNLF_LIVE') ? 1 : 0);
  });
}

class _HttpClient implements HttpClient {
  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
