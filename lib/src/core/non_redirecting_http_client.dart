import 'dart:io';

/// WebSocket.connect accepts HttpClient but has no per-request redirect option.
/// Apply the same redirect refusal used by the ordinary authenticated transport.
final class NonRedirectingHttpClient implements HttpClient {
  NonRedirectingHttpClient(this._inner);
  final HttpClient _inner;

  Future<HttpClientRequest> _prepare(Future<HttpClientRequest> pending) async {
    final request = await pending;
    request.followRedirects = false;
    request.maxRedirects = 0;
    return request;
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _prepare(_inner.openUrl(method, url));
  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => _prepare(_inner.open(method, host, port, path));
  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _prepare(_inner.get(host, port, path));
  @override
  Future<HttpClientRequest> getUrl(Uri url) => _prepare(_inner.getUrl(url));
  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _prepare(_inner.head(host, port, path));
  @override
  Future<HttpClientRequest> headUrl(Uri url) => _prepare(_inner.headUrl(url));
  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _prepare(_inner.post(host, port, path));
  @override
  Future<HttpClientRequest> postUrl(Uri url) => _prepare(_inner.postUrl(url));
  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _prepare(_inner.put(host, port, path));
  @override
  Future<HttpClientRequest> putUrl(Uri url) => _prepare(_inner.putUrl(url));
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _prepare(_inner.patch(host, port, path));
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _prepare(_inner.patchUrl(url));
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _prepare(_inner.delete(host, port, path));
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) =>
      _prepare(_inner.deleteUrl(url));

  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) {
    _inner.autoUncompress = value;
  }

  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set idleTimeout(Duration value) {
    _inner.idleTimeout = value;
  }

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) {
    _inner.connectionTimeout = value;
  }

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? value) {
    _inner.maxConnectionsPerHost = value;
  }

  @override
  String? get userAgent => _inner.userAgent;
  @override
  set userAgent(String? value) {
    _inner.userAgent = value;
  }

  @override
  set authenticate(Future<bool> Function(Uri, String, String?)? callback) {
    _inner.authenticate = callback;
  }

  @override
  set authenticateProxy(
    Future<bool> Function(String, int, String, String?)? callback,
  ) {
    _inner.authenticateProxy = callback;
  }

  @override
  set badCertificateCallback(
    bool Function(X509Certificate, String, int)? callback,
  ) {
    _inner.badCertificateCallback = callback;
  }

  @override
  set findProxy(String Function(Uri)? callback) {
    _inner.findProxy = callback;
  }

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(Uri, String?, int?)? callback,
  ) {
    _inner.connectionFactory = callback;
  }

  @override
  set keyLog(dynamic Function(String)? callback) {
    _inner.keyLog = callback;
  }

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addCredentials(url, realm, credentials);
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addProxyCredentials(host, port, realm, credentials);
  @override
  void close({bool force = false}) => _inner.close(force: force);
}
