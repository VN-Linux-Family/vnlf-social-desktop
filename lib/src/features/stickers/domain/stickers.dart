/// A GIF or sticker chosen for a comment, sent as the comment's `gif` field
/// exactly as the website builds it (`@vnlf/contracts` GifAttachment).
final class GifChoice {
  const GifChoice.klipy({
    required this.id,
    required this.slug,
    required this.title,
    required this.url,
    required this.width,
    required this.height,
    this.sticker = false,
  }) : provider = 'KLIPY',
       packId = '',
       packSlug = '';

  const GifChoice.vnlf({
    required this.id,
    required this.packId,
    required this.packSlug,
    required this.title,
    required this.url,
    required this.width,
    required this.height,
  }) : provider = 'VNLF',
       slug = '',
       sticker = true;

  final String provider;
  final String id;
  final String slug;
  final String packId;
  final String packSlug;
  final String title;
  final String url;
  final int width;
  final int height;
  final bool sticker;

  bool get isKlipy => provider == 'KLIPY';

  /// The comment payload, in a fixed key order so retries compare equal.
  Map<String, Object> toJson() => isKlipy
      ? {
          'provider': 'KLIPY',
          'id': id,
          'slug': slug,
          if (sticker) 'kind': 'sticker',
          'title': title,
          'url': url,
          'width': width,
          'height': height,
        }
      : {
          'provider': 'VNLF',
          'kind': 'sticker',
          'id': id,
          'packId': packId,
          'packSlug': packSlug,
          'title': title,
          'url': url,
          'width': width,
          'height': height,
        };

  /// Reads a stored payload back; null when it is not one this app writes.
  static GifChoice? fromJson(Object? value) {
    if (value is! Map) return null;
    String text(String key) => value[key] is String ? value[key] as String : '';
    int number(String key) => value[key] is int ? value[key] as int : 0;
    final width = number('width');
    final height = number('height');
    if (text('url').isEmpty || width < 1 || height < 1) return null;
    return switch (text('provider')) {
      'KLIPY' when text('id').isNotEmpty && text('slug').isNotEmpty =>
        GifChoice.klipy(
          id: text('id'),
          slug: text('slug'),
          title: text('title'),
          url: text('url'),
          width: width,
          height: height,
          sticker: text('kind') == 'sticker',
        ),
      'VNLF' when text('id').isNotEmpty && text('packId').isNotEmpty =>
        GifChoice.vnlf(
          id: text('id'),
          packId: text('packId'),
          packSlug: text('packSlug'),
          title: text('title'),
          url: text('url'),
          width: width,
          height: height,
        ),
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is GifChoice && other.provider == provider && other.id == id;

  @override
  int get hashCode => Object.hash(provider, id);
}

/// `GET /api/v1/integrations/klipy`: KLIPY is called from the client with
/// the server's public app key and a per-member pseudonym.
final class KlipyConfig {
  const KlipyConfig({
    required this.enabled,
    required this.apiKey,
    required this.customerId,
  });

  final bool enabled;
  final String apiKey;
  final String customerId;
}

/// One page of KLIPY results.
final class KlipyPage {
  const KlipyPage({
    required this.items,
    required this.currentPage,
    required this.hasNext,
  });

  final List<GifChoice> items;
  final int currentPage;
  final bool hasNext;
}

/// A KLIPY failure with the website's message.
final class KlipyException implements Exception {
  const KlipyException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class StickerItem {
  const StickerItem({
    required this.id,
    required this.emoji,
    required this.url,
    required this.width,
    required this.height,
  });

  final String id;
  final String emoji;
  final String? url;
  final int width;
  final int height;
}

final class StickerPackRef {
  const StickerPackRef({
    required this.id,
    required this.slug,
    required this.title,
  });

  final String id;
  final String slug;
  final String title;

  /// The comment payload for [sticker] from this pack.
  GifChoice choice(StickerItem sticker) => GifChoice.vnlf(
    id: sticker.id,
    packId: id,
    packSlug: slug,
    title: title,
    url: sticker.url ?? '',
    width: sticker.width < 1 ? 1 : sticker.width,
    height: sticker.height < 1 ? 1 : sticker.height,
  );
}

final class StickerPack {
  const StickerPack({required this.ref, required this.stickers});
  final StickerPackRef ref;
  final List<StickerItem> stickers;
}

final class SavedSticker {
  const SavedSticker({required this.sticker, required this.pack});
  final StickerItem sticker;
  final StickerPackRef pack;
}

abstract interface class KlipyRepository {
  Future<KlipyConfig> config();

  /// Trending items without a [query], search results with one.
  Future<KlipyPage> search(
    KlipyConfig config, {
    required String query,
    required int page,
    required bool stickers,
  });

  /// Tells KLIPY a result was sent, as the website does once per comment.
  Future<void> share(KlipyConfig config, GifChoice choice, String query);
}

abstract interface class StickersRepository {
  /// Packs the member made or added (`GET /api/v1/stickers/tray`).
  Future<List<StickerPack>> tray();

  /// Single stickers the member kept (`GET /api/v1/stickers/saved`).
  Future<List<SavedSticker>> saved();

  /// `DELETE /api/v1/stickers/:id/save`.
  Future<void> unsave(String stickerId);
}

/// The stickers a person tagged with [emoji], saved ones first, each once,
/// like the website's `stickersTagged`.
List<GifChoice> stickersTagged(
  String? emoji,
  List<SavedSticker> saved,
  List<StickerPack> packs,
) {
  if (emoji == null) return const [];
  final seen = <String>{};
  final found = <GifChoice>[];
  void add(StickerPackRef pack, StickerItem sticker) {
    if (sticker.emoji != emoji ||
        sticker.url == null ||
        !seen.add(sticker.id)) {
      return;
    }
    found.add(pack.choice(sticker));
  }

  for (final item in saved) {
    add(item.pack, item.sticker);
  }
  for (final pack in packs) {
    for (final sticker in pack.stickers) {
      add(pack.ref, sticker);
    }
  }
  return found;
}

bool _pictographic(int rune) =>
    (rune >= 0x1F000 && rune <= 0x1FAFF) ||
    (rune >= 0x2600 && rune <= 0x27BF) ||
    (rune >= 0x2300 && rune <= 0x23FF) ||
    (rune >= 0x2B00 && rune <= 0x2BFF) ||
    (rune >= 0x2190 && rune <= 0x21FF) ||
    (rune >= 0x25A0 && rune <= 0x25FF) ||
    const {
      0x00A9,
      0x00AE,
      0x203C,
      0x2049,
      0x2122,
      0x2139,
      0x24C2,
      0x2934,
      0x2935,
      0x3030,
      0x303D,
      0x3297,
      0x3299,
    }.contains(rune);

bool _regional(int rune) => rune >= 0x1F1E6 && rune <= 0x1F1FF;
bool _modifier(int rune) =>
    rune == 0xFE0F || (rune >= 0x1F3FB && rune <= 0x1F3FF);

/// The first emoji in [value] (a sticker's tag), or null: a flag, a keycap,
/// or a pictograph with its variation, skin tone and joined parts.
String? firstEmoji(String value) {
  final runes = value.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    final rune = runes[i];
    if (_regional(rune) && i + 1 < runes.length && _regional(runes[i + 1])) {
      return String.fromCharCodes(runes.sublist(i, i + 2));
    }
    if ('#*0123456789'.runes.contains(rune)) {
      var end = i + 1;
      if (end < runes.length && runes[end] == 0xFE0F) end++;
      if (end < runes.length && runes[end] == 0x20E3) {
        return String.fromCharCodes(runes.sublist(i, end + 1));
      }
      continue;
    }
    if (!_pictographic(rune)) continue;
    var end = i + 1;
    while (end < runes.length) {
      if (_modifier(runes[end])) {
        end++;
      } else if (runes[end] == 0x200D &&
          end + 1 < runes.length &&
          _pictographic(runes[end + 1])) {
        end += 2;
      } else {
        break;
      }
    }
    return String.fromCharCodes(runes.sublist(i, end));
  }
  return null;
}
