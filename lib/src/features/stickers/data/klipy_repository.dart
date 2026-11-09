import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../../../i18n/vi.dart';
import '../domain/stickers.dart';

/// Sends one request to KLIPY and returns its status and body.
typedef KlipyTransport = Future<({int status, String body})> Function(
  String method,
  Uri uri, {
  String? body,
});

const _timeout = Duration(seconds: 10);

/// No cookies and no account data: KLIPY sees only the request.
Future<({int status, String body})> ioKlipyTransport(
  String method,
  Uri uri, {
  String? body,
}) async {
  final client = HttpClient()..connectionTimeout = _timeout;
  try {
    final request = await client.openUrl(method, uri).timeout(_timeout);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(body);
    }
    final response = await request.close().timeout(_timeout);
    final text = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_timeout);
    return (status: response.statusCode, body: text);
  } finally {
    client.close(force: true);
  }
}

/// KLIPY as the website uses it (`apps/web/lib/klipy.ts`): the config from
/// the API, then trending and search pages straight from api.klipy.com.
final class LiveKlipyRepository implements KlipyRepository {
  LiveKlipyRepository(this._client, {KlipyTransport? transport})
    : _transport = transport ?? ioKlipyTransport;

  final ApiClient _client;
  final KlipyTransport _transport;

  @override
  Future<KlipyConfig> config() => _client.get<KlipyConfig>(
    '/api/v1/integrations/klipy',
    refresh: true,
    decode: (json) => KlipyConfig(
      enabled: boolValue(json['enabled'], 'klipy.enabled'),
      apiKey: stringValue(json['apiKey'], 'klipy.apiKey'),
      customerId: stringValue(json['customerId'], 'klipy.customerId'),
    ),
  );

  @override
  Future<KlipyPage> search(
    KlipyConfig config, {
    required String query,
    required int page,
    required bool stickers,
  }) async {
    if (!config.enabled || config.apiKey.isEmpty) {
      throw KlipyException(vi.klipy.khoKlipyChuaDuocCau);
    }
    final ({int status, String body}) response;
    try {
      response = await _transport(
        'GET',
        klipySearchUri(config, query: query, page: page, stickers: stickers),
      );
    } on TimeoutException {
      throw KlipyException(vi.klipy.klipyPhanHoiQuaCham);
    } on IOException {
      throw KlipyException(vi.klipy.khongKetNoiDuocKlipy);
    }
    if (response.status == 429) {
      throw KlipyException(vi.klipy.klipyDaHetLuotGoi);
    }
    if (response.status == 401 || response.status == 403) {
      throw KlipyException(vi.klipy.klipyChuaChapNhanApi);
    }
    if (response.status < 200 || response.status > 299) {
      throw KlipyException(vi.klipy.chuaTaiDuocGifTu);
    }
    return parseKlipyPage(response.body, page, stickers: stickers);
  }

  @override
  Future<void> share(KlipyConfig config, GifChoice choice, String query) async {
    if (!choice.isKlipy || config.apiKey.isEmpty) return;
    final uri = Uri(
      scheme: 'https',
      host: 'api.klipy.com',
      pathSegments: [
        'api',
        'v1',
        config.apiKey,
        choice.sticker ? 'stickers' : 'gifs',
        'share',
        choice.slug,
      ],
    );
    try {
      await _transport(
        'POST',
        uri,
        body: jsonEncode({'customer_id': config.customerId, 'q': query}),
      );
    } on Object catch (error) {
      // Provider analytics never decides whether a comment was sent.
      developer.log('KLIPY share not recorded: $error', name: 'vnlf.klipy');
    }
  }
}

/// `https://api.klipy.com/api/v1/{key}/{gifs|stickers}/{trending|search}`.
Uri klipySearchUri(
  KlipyConfig config, {
  required String query,
  required int page,
  required bool stickers,
}) => Uri(
  scheme: 'https',
  host: 'api.klipy.com',
  pathSegments: [
    'api',
    'v1',
    config.apiKey,
    stickers ? 'stickers' : 'gifs',
    query.isEmpty ? 'trending' : 'search',
  ],
  queryParameters: {
    'page': '$page',
    'per_page': '24',
    'customer_id': config.customerId,
    'locale': 'vn',
    'format_filter': 'gif,webp',
    'content_filter': 'high',
    if (query.isNotEmpty) 'q': query,
  },
);

/// Media must come from KLIPY's own image hosts.
bool isKlipyMedia(String url) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      uri.scheme == 'https' &&
      const {
        'static.klipy.com',
        'static1.klipy.com',
        'static2.klipy.com',
      }.contains(uri.host) &&
      !uri.hasPort &&
      uri.userInfo.isEmpty &&
      uri.path.startsWith('/ii/') &&
      RegExp(r'\.(gif|webp)$', caseSensitive: false).hasMatch(uri.path);
}

final _bigInteger = RegExp(r'"(?:\\.|[^"\\])*"|(:\s*)(\d{16,})(?=\s*[,}])');
final _id = RegExp(r'^\d{1,30}$');
final _slug = RegExp(r'^[a-zA-Z0-9_-]{1,200}$');

/// Parses a KLIPY page like the website's `parseKlipyPage`, refusing ads,
/// foreign hosts and anything malformed.
KlipyPage parseKlipyPage(
  String json,
  int requestedPage, {
  required bool stickers,
}) {
  KlipyException invalid() => KlipyException(vi.klipy.duLieuGifTuKlipy);
  Map<String, dynamic> object(Object? value) =>
      value is Map<String, dynamic> ? value : throw invalid();
  // Keep large integer ids exact: they become strings before decoding.
  final preserved = json.replaceAllMapped(
    _bigInteger,
    (match) => match[2] != null ? '${match[1]}"${match[2]}"' : match[0]!,
  );
  final Object? value;
  try {
    value = jsonDecode(preserved);
  } on FormatException {
    throw invalid();
  }
  final body = object(value);
  final data = object(body['data']);
  final list = data['data'];
  if (body['result'] != true ||
      list is! List ||
      list.length > 50 ||
      data['current_page'] != requestedPage ||
      data['has_next'] is! bool) {
    throw invalid();
  }
  final items = <GifChoice>[];
  for (final raw in list) {
    final item = object(raw);
    if (item['type'] == 'ad') {
      throw KlipyException(vi.klipy.klipyDangBatQuangCao);
    }
    final rawId = item['id'];
    final id = rawId is int && rawId >= 0 ? '$rawId' : rawId;
    final slug = item['slug'];
    final title = item['title'];
    if (id is! String ||
        !_id.hasMatch(id) ||
        slug is! String ||
        !_slug.hasMatch(slug) ||
        title is! String) {
      throw invalid();
    }
    final file = object(item['file']);
    Map<String, dynamic>? media;
    for (final size in const ['sm', 'md', 'hd', 'xs']) {
      final rendition = file[size];
      if (rendition == null) continue;
      final formats = object(rendition);
      if (formats['gif'] != null || formats['webp'] != null) {
        media = object(
          stickers
              ? formats['webp'] ?? formats['gif']
              : formats['gif'] ?? formats['webp'],
        );
        break;
      }
    }
    final url = media?['url'];
    final width = media?['width'];
    final height = media?['height'];
    if (url is! String ||
        url.length > 2048 ||
        !isKlipyMedia(url) ||
        width is! int ||
        height is! int ||
        width < 1 ||
        height < 1 ||
        width > 4096 ||
        height > 4096) {
      throw invalid();
    }
    final name = title.length > 200 ? title.substring(0, 200) : title;
    items.add(
      GifChoice.klipy(
        id: id,
        slug: slug,
        title: name.isNotEmpty
            ? name
            : (stickers ? 'Sticker KLIPY' : 'GIF KLIPY'),
        url: url,
        width: width,
        height: height,
        sticker: stickers,
      ),
    );
  }
  return KlipyPage(
    items: List.unmodifiable(items),
    currentPage: requestedPage,
    hasNext: data['has_next'] == true && items.isNotEmpty,
  );
}

/// Offline fixtures have no KLIPY catalogue.
final class FixtureKlipyRepository implements KlipyRepository {
  const FixtureKlipyRepository();

  @override
  Future<KlipyConfig> config() async =>
      const KlipyConfig(enabled: false, apiKey: '', customerId: '');

  @override
  Future<KlipyPage> search(
    KlipyConfig config, {
    required String query,
    required int page,
    required bool stickers,
  }) async => throw KlipyException(vi.klipy.khoKlipyChuaDuocCau);

  @override
  Future<void> share(
    KlipyConfig config,
    GifChoice choice,
    String query,
  ) async {}
}
