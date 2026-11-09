import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../core/preferences_storage.dart';
import '../../../data/field_reader.dart';
import '../domain/stickers.dart';

StickerItem _sticker(Map<String, dynamic> json) => StickerItem(
  id: stringValue(json['id'], 'sticker.id'),
  emoji: stringValue(json['emoji'], 'sticker.emoji'),
  url: nullableString(json['url'], 'sticker.url'),
  width: intValue(json['width'], 'sticker.width'),
  height: intValue(json['height'], 'sticker.height'),
);

/// Only finished stickers with an image can be sent.
bool _usable(Map<String, dynamic> json) =>
    json['status'] == 'READY' &&
    json['url'] is String &&
    (json['url'] as String).isNotEmpty;

StickerPackRef _pack(Map<String, dynamic> json, String field) => StickerPackRef(
  id: stringValue(json['id'], '$field.id'),
  slug: stringValue(json['slug'], '$field.slug'),
  title: stringValue(json['title'], '$field.title'),
);

/// The member's sticker tray and saved stickers, as the website's picker
/// reads them (`apps/web/lib/stickers.ts`).
final class LiveStickersRepository implements StickersRepository {
  LiveStickersRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<StickerPack>> tray() => _client.get<List<StickerPack>>(
    '/api/v1/stickers/tray',
    refresh: true,
    decode: (json) => List.unmodifiable([
      for (final pack in objectList(json['packs'], 'stickers.packs'))
        StickerPack(
          ref: _pack(pack, 'stickers.pack'),
          stickers: List.unmodifiable([
            for (final sticker in objectList(
              pack['stickers'],
              'stickers.pack.stickers',
            ))
              if (_usable(sticker)) _sticker(sticker),
          ]),
        ),
    ]),
  );

  @override
  Future<List<SavedSticker>> saved() => _client.get<List<SavedSticker>>(
    '/api/v1/stickers/saved',
    refresh: true,
    decode: (json) => List.unmodifiable([
      for (final item in objectList(json['items'], 'stickers.saved'))
        if (objectValue(item['sticker'], 'stickers.saved.sticker')
            case final sticker? when _usable(sticker))
          SavedSticker(
            sticker: _sticker(sticker),
            pack: _pack(
              objectValue(item['pack'], 'stickers.saved.pack') ??
                  (throw const ParseFailure('stickers.saved.pack')),
              'stickers.saved.pack',
            ),
          ),
    ]),
  );

  @override
  Future<void> unsave(String stickerId) async {
    await _client.request<void>(
      'DELETE',
      '/api/v1/stickers/${Uri.encodeComponent(stickerId)}/save',
    );
    _client.clearCache();
  }
}

/// Offline fixtures have no stickers.
final class FixtureStickersRepository implements StickersRepository {
  const FixtureStickersRepository();
  @override
  Future<List<StickerPack>> tray() async => const [];
  @override
  Future<List<SavedSticker>> saved() async => const [];
  @override
  Future<void> unsave(String stickerId) async {}
}

/// The 16 stickers a member sent last, kept on this device per account like
/// the website's `vnlf:recent-stickers`.
final class RecentStickersStore {
  const RecentStickersStore(this._storage);
  final PreferencesStorage _storage;
  static const limit = 16;

  String _key(String owner) =>
      'vnlf.recent-stickers.${Uri.encodeComponent(owner)}';

  Future<List<GifChoice>> read(String owner) async {
    if (owner.isEmpty) return const [];
    final raw = await _storage.read(_key(owner));
    if (raw == null) return const [];
    final Object? value;
    try {
      value = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (value is! List) return const [];
    return List.unmodifiable(
      value
          .map(GifChoice.fromJson)
          .whereType<GifChoice>()
          .where((choice) => choice.sticker)
          .take(limit),
    );
  }

  Future<void> remember(String owner, GifChoice choice) async {
    if (owner.isEmpty || !choice.sticker) return;
    final current = await read(owner);
    final next = [
      choice,
      ...current.where((item) => item != choice),
    ].take(limit).map((item) => item.toJson()).toList();
    await _storage.write(_key(owner), jsonEncode(next));
  }
}
