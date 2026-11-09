import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/stickers/domain/stickers.dart';
import 'package:vnlfsocialapp/src/features/stickers/presentation/gif_picker.dart';
import 'package:vnlfsocialapp/src/features/stickers/presentation/sticker_providers.dart';

const pack = StickerPackRef(id: 'pack-1', slug: 'meo', title: 'Mèo');
const sticker = StickerItem(
  id: 'sticker-1',
  emoji: '😀',
  url: 'https://cdn.example/sticker-1.webp',
  width: 160,
  height: 160,
);
const klipyGif = GifChoice.klipy(
  id: '42',
  slug: 'vui',
  title: 'Vui',
  url: 'https://static1.klipy.com/ii/vui.gif',
  width: 200,
  height: 150,
);

void main() {
  late List<String> searches;

  Future<List<GifPick?>> pump(WidgetTester tester) async {
    searches = [];
    final picks = <GifPick?>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith(
            (ref) => const Session(
              userId: 'reader',
              displayName: 'Bạn đọc',
              role: 'MEMBER',
            ),
          ),
          preferencesStorageProvider.overrideWithValue(_MemoryStorage()),
          klipyRepositoryProvider.overrideWithValue(_FakeKlipy(searches)),
          stickersRepositoryProvider.overrideWithValue(_FakeStickers()),
        ],
        child: MaterialApp(
          theme: VnlfTheme.light(),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    final box = context.findRenderObject()! as RenderBox;
                    picks.add(
                      await showGifPicker(
                        context,
                        anchor: box.localToGlobal(Offset.zero) & box.size,
                      ),
                    );
                  },
                  child: const Text('Mở'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return picks;
  }

  testWidgets('stickers come first, then the website sections', (tester) async {
    final picks = await pump(tester);
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(find.text('Sticker'), findsOneWidget);
    expect(find.text('GIF'), findsOneWidget);
    expect(find.text('Mèo'), findsOneWidget);
    expect(find.text('Sticker KLIPY'), findsOneWidget);
    expect(searches, ['sticker:']);
    await tester.tap(find.bySemanticsLabel('Chọn sticker Mèo'));
    await tester.pumpAndSettle();
    expect(picks.single!.choice.provider, 'VNLF');
    expect(picks.single!.choice.id, 'sticker-1');
  });

  testWidgets('the GIF tab searches after a pause and returns the query', (
    tester,
  ) async {
    final picks = await pump(tester);
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GIF'));
    await tester.pumpAndSettle();
    expect(searches.last, 'gif:');
    await tester.enterText(find.byType(TextField), 'vui');
    await tester.pump(const Duration(milliseconds: 200));
    expect(searches.last, 'gif:');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(searches.last, 'gif:vui');
    await tester.tap(find.bySemanticsLabel('Chọn GIF Vui').first);
    await tester.pumpAndSettle();
    expect(picks.single!.choice, klipyGif);
    expect(picks.single!.query, 'vui');
  });
}

class _FakeKlipy implements KlipyRepository {
  _FakeKlipy(this.searches);
  final List<String> searches;

  @override
  Future<KlipyConfig> config() async =>
      const KlipyConfig(enabled: true, apiKey: 'k', customerId: 'c');

  @override
  Future<KlipyPage> search(
    KlipyConfig config, {
    required String query,
    required int page,
    required bool stickers,
  }) async {
    searches.add('${stickers ? 'sticker' : 'gif'}:$query');
    return KlipyPage(
      items: stickers ? const [] : const [klipyGif],
      currentPage: page,
      hasNext: false,
    );
  }

  @override
  Future<void> share(
    KlipyConfig config,
    GifChoice choice,
    String query,
  ) async {}
}

class _FakeStickers implements StickersRepository {
  @override
  Future<List<StickerPack>> tray() async => const [
    StickerPack(ref: pack, stickers: [sticker]),
  ];

  @override
  Future<List<SavedSticker>> saved() async => const [];

  @override
  Future<void> unsave(String stickerId) async {}
}

class _MemoryStorage implements PreferencesStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
