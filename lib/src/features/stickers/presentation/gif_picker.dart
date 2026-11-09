import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/vnlf_navigation_helper.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../domain/stickers.dart';
import 'sticker_providers.dart';

/// What the picker returns: the item and the search that found it, which
/// KLIPY's share tracking needs.
typedef GifPick = ({GifChoice choice, String query});

/// Opens the website's sticker and GIF picker above [anchor].
Future<GifPick?> showGifPicker(BuildContext context, {required Rect anchor}) =>
    showVnlfPopover<GifPick>(
      context,
      anchor: anchor,
      label: vi.gifPicker.timStickerTrenKlipy,
      builder: (_) => const _GifPicker(),
    );

class _GifPicker extends ConsumerStatefulWidget {
  const _GifPicker();

  @override
  ConsumerState<_GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends ConsumerState<_GifPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  bool _stickers = true;
  String _query = '';
  final _pages = <KlipyPage>[];
  bool _loading = false;
  String? _error;
  int _generation = 0;
  bool _editingSaved = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  bool get _waiting => _search.text.trim() != _query;

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _apply(_search.text.trim());
    });
    setState(() {});
  }

  void _apply(String query) {
    _debounce?.cancel();
    setState(() {
      _query = query;
      _pages.clear();
      _error = null;
    });
    _load(1);
  }

  void _switch(bool stickers) {
    if (stickers == _stickers) return;
    _search.removeListener(_onSearch);
    _search.clear();
    _search.addListener(_onSearch);
    setState(() => _stickers = stickers);
    _apply('');
  }

  Future<void> _load(int page) async {
    final config = ref.read(klipyConfigProvider).valueOrNull;
    if (config == null || !config.enabled) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(klipyRepositoryProvider)
          .search(config, query: _query, page: page, stickers: _stickers);
      if (!mounted || generation != _generation) return;
      setState(() {
        _pages.add(result);
        _loading = false;
      });
    } on KlipyException catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _choose(GifChoice choice, {bool fromRecent = false}) {
    if (choice.isKlipy && _waiting && !fromRecent) return;
    Navigator.of(context)
        .pop<GifPick>((choice: choice, query: fromRecent ? '' : _query));
  }

  Future<void> _unsave(SavedSticker item) async {
    try {
      await ref.read(stickersRepositoryProvider).unsave(item.sticker.id);
      ref.invalidate(savedStickersProvider);
    } on Object {
      if (mounted) showVnlfToast(context, vi.stickers.chuaLuuDuoc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final config = ref.watch(klipyConfigProvider);
    if (config.valueOrNull?.enabled == true &&
        _pages.isEmpty &&
        !_loading &&
        _error == null &&
        !_waiting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.isEmpty && !_loading) _load(1);
      });
    }
    final muted = VnlfTypography.body(colors.muted);
    final items = [for (final page in _pages) ...page.items];
    final hasNext = _pages.isNotEmpty && _pages.last.hasNext;
    final height = MediaQuery.sizeOf(context).height;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 8,
          children: [
            _KindTabs(stickers: _stickers, onChanged: _switch),
            Expanded(
              child: InkWell(
                onTap: () => openVnlfLink(context, 'https://klipy.com/'),
                child: Text(
                  _stickers
                      ? vi.gifPicker.stickerTuKlipy
                      : vi.gifPicker.poweredByKlipy,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VnlfTypography.body(colors.ink)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            VnlfCloseButton(onPressed: () => Navigator.of(context).pop()),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _search,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => _apply(value.trim()),
          style: VnlfTypography.body(colors.ink),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            hintText: vi.gifPicker.searchKlipy,
            hintStyle: muted,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10, right: 6),
              child: VnlfIcon(VnlfLucide.search, size: 18, color: colors.muted),
            ),
            prefixIconConstraints: const BoxConstraints(),
            filled: true,
            fillColor: colors.surfaceSoft,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              borderSide: BorderSide(color: colors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              borderSide: BorderSide(color: colors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              borderSide: BorderSide(color: colors.brand),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (height * .52).clamp(120, 380).toDouble(),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                if (_stickers) ..._stickerSections(context),
                ...switch (config) {
                  AsyncValue(isLoading: true) => [
                    Text(vi.gifPicker.dangKetNoi, style: muted),
                  ],
                  AsyncValue(hasError: true) => [
                    Text(vi.gifPicker.chuaTaiDuocCauHinh, style: muted),
                    VnlfOutlineButton(
                      label: vi.common.thuLai,
                      onPressed: () => ref.invalidate(klipyConfigProvider),
                    ),
                  ],
                  AsyncValue(:final value?) when !value.enabled => [
                    Text(vi.gifPicker.khoKlipyChuaDuocCau, style: muted),
                  ],
                  _ => [
                    if (_loading || _waiting)
                      Text(
                        _stickers
                            ? vi.gifPicker.dangTimSticker
                            : vi.gifPicker.dangTimGif,
                        style: muted,
                      ),
                    if (_error != null) ...[
                      Text(_error!, style: muted),
                      VnlfOutlineButton(
                        label: vi.common.thuLai,
                        onPressed: () => _load(_pages.length + 1),
                      ),
                    ],
                    if (!_loading &&
                        !_waiting &&
                        _error == null &&
                        _pages.isNotEmpty &&
                        items.isEmpty)
                      Text(
                        _stickers
                            ? vi.gifPicker.khongTimThaySticker
                            : vi.gifPicker.khongTimThayGifThu,
                        style: muted,
                      ),
                    if (items.isNotEmpty)
                      _ResultGrid(
                        choices: items,
                        stickers: _stickers,
                        onSelect: _choose,
                      ),
                    if (hasNext)
                      VnlfOutlineButton(
                        label: _loading
                            ? vi.common.dangTai
                            : (_stickers
                                  ? vi.gifPicker.xemThemSticker
                                  : vi.gifPicker.xemThemGif),
                        onPressed: _loading || _waiting
                            ? null
                            : () => _load(_pages.last.currentPage + 1),
                      ),
                  ],
                },
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _stickerSections(BuildContext context) {
    final colors = VnlfColors.of(context);
    final recent = ref.watch(recentStickersProvider).valueOrNull ?? const [];
    final saved = ref.watch(savedStickersProvider).valueOrNull ?? const [];
    final packs = [
      for (final pack
          in ref.watch(stickerTrayProvider).valueOrNull ??
              const <StickerPack>[])
        if (pack.stickers.isNotEmpty) pack,
    ];
    if (_query.isNotEmpty) {
      final tagged = stickersTagged(firstEmoji(_query), saved, packs);
      return [
        if (tagged.isNotEmpty) ...[
          _SectionTitle(vi.stickers.stickerCuaBan),
          _ResultGrid(choices: tagged, stickers: true, onSelect: _choose),
        ],
      ];
    }
    return [
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          _PickerLink(
            icon: VnlfLucide.store,
            label: vi.stickers.choSticker,
            url: 'https://vietnamlinuxfamily.net/stickers',
          ),
          _PickerLink(
            icon: VnlfLucide.plus,
            label: vi.stickers.quanLy,
            url: 'https://vietnamlinuxfamily.net/stickers?tab=mine',
          ),
        ],
      ),
      if (recent.isNotEmpty) ...[
        _SectionTitle(vi.gifPicker.dungGanDay),
        _ResultGrid(
          choices: recent,
          stickers: true,
          onSelect: (choice) => _choose(choice, fromRecent: true),
        ),
      ],
      if (saved.isNotEmpty) ...[
        Row(
          children: [
            Expanded(child: _SectionTitle(vi.stickers.stickerDaLuu)),
            TextButton(
              onPressed: () => setState(() => _editingSaved = !_editingSaved),
              child: Text(_editingSaved ? vi.stickers.xong : vi.common.sua),
            ),
          ],
        ),
        _ResultGrid(
          choices: [for (final item in saved) item.pack.choice(item.sticker)],
          stickers: true,
          removing: _editingSaved,
          onSelect: (choice) {
            if (!_editingSaved) {
              _choose(choice);
              return;
            }
            final item = saved.firstWhere((s) => s.sticker.id == choice.id);
            _unsave(item);
          },
        ),
      ],
      for (final pack in packs) ...[
        InkWell(
          onTap: () => openVnlfLink(
            context,
            'https://vietnamlinuxfamily.net/stickers/${Uri.encodeComponent(pack.ref.slug)}',
          ),
          child: _SectionTitle(pack.ref.title, color: colors.ink),
        ),
        _ResultGrid(
          choices: [
            for (final sticker in pack.stickers) pack.ref.choice(sticker),
          ],
          stickers: true,
          onSelect: _choose,
        ),
      ],
      _SectionTitle(vi.stickers.stickerKlipy),
    ];
  }
}

class _KindTabs extends StatelessWidget {
  const _KindTabs({required this.stickers, required this.onChanged});

  final bool stickers;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    Widget tab(String label, bool value) {
      final selected = value == stickers;
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.surface : null,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x14101814),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: VnlfTypography.body(selected ? colors.brand : colors.muted)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: vi.gifPicker.loaiNoiDung,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            tab(vi.gifPicker.sticker, true),
            tab(vi.gifPicker.gif, false),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Text(
      text,
      style: VnlfTypography.body(color ?? colors.muted)
          .copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _PickerLink extends StatelessWidget {
  const _PickerLink({
    required this.icon,
    required this.label,
    required this.url,
  });

  final VnlfLucide icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return InkWell(
      onTap: () => openVnlfLink(context, url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            VnlfIcon(icon, size: 15, color: colors.brand),
            Text(label, style: VnlfTypography.body(colors.brand)),
          ],
        ),
      ),
    );
  }
}

/// Stickers four to a row on a transparent ground, GIFs two to a row on
/// rounded tiles.
class _ResultGrid extends StatelessWidget {
  const _ResultGrid({
    required this.choices,
    required this.stickers,
    required this.onSelect,
    this.removing = false,
  });

  final List<GifChoice> choices;
  final bool stickers;
  final bool removing;
  final ValueChanged<GifChoice> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final columns = stickers ? 4 : 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth - 6 * (columns - 1)) / columns;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final choice in choices)
              Semantics(
                button: true,
                label: removing
                    ? format(vi.stickers.boLuuSticker, {'title': choice.title})
                    : format(
                        stickers
                            ? vi.gifPicker.chonSticker
                            : vi.gifPicker.chonGif,
                        {'title': choice.title},
                      ),
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onSelect(choice),
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                  child: Container(
                    width: size,
                    height: stickers ? size : size * .75,
                    decoration: BoxDecoration(
                      color: stickers ? null : colors.surfaceSoft,
                      border: removing
                          ? Border.all(color: colors.red, width: 1.5)
                          : null,
                      borderRadius: BorderRadius.circular(
                        VnlfDimensions.radiusMd,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      choice.url,
                      fit: stickers ? BoxFit.contain : BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          vi.gifPicker.gifChuaTaiDuoc,
                          textAlign: TextAlign.center,
                          style: VnlfTypography.body(colors.muted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
