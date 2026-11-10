import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/search_results.dart';
import 'search_providers.dart';
import 'search_results_list.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  SearchScope _scope = SearchScope.all;
  Timer? _debounce;
  String? _activeQuery;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final uri = GoRouterState.of(context).uri;
    final query = uri.queryParameters['q'] ?? '';
    _query.text = query.length > 100 ? query.substring(0, 100) : query;
    _scope = switch (uri.queryParameters['type']) {
      'user' => SearchScope.users,
      'article' => SearchScope.posts,
      'project' => SearchScope.projects,
      'tag' => SearchScope.topics,
      _ => SearchScope.all,
    };
    if (_query.text.trim().length >= 2) _activeQuery = _query.text.trim();
  }

  void _changed(String value) {
    _debounce?.cancel();
    setState(() => _activeQuery = null);
    if (value.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 300), _searchNow);
  }

  void _searchNow() {
    _debounce?.cancel();
    final keyword = _query.text.trim();
    setState(() => _activeQuery = keyword.length >= 2 ? keyword : null);
  }

  /// Topics open their page, as on the website's search.
  void _useTopic(SearchTopic topic) =>
      context.push('/t/${Uri.encodeComponent(topic.slug)}');

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final colors = VnlfColors.of(context);
    final labels = [
      vi.common.tatCa,
      vi.common.baiViet,
      vi.searchView.duAn,
      vi.common.roleMember,
      vi.searchView.chuDe,
    ];
    final query = _activeQuery;
    final results = query == null
        ? null
        : ref.watch(searchResultsProvider(query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!mobile) ...[
          VnlfCenterPageHeader(
            title: vi.common.timKiem,
            leading: context.canPop()
                ? IconButton(
                    tooltip: vi.app.common.quayLai,
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  )
                : null,
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const Key('search-input'),
          controller: _query,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          onChanged: _changed,
          onSubmitted: (_) => _searchNow(),
          decoration: InputDecoration(
            labelText: vi.app.search.timTrongCongDong,
            counterText: '',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: vi.app.search.xoaTimKiem,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _query.clear();
                      _changed('');
                    },
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final scope in SearchScope.values)
                ChoiceChip(
                  selectedColor: colors.brandSoft,
                  backgroundColor: colors.surface,
                  checkmarkColor: colors.brand,
                  side: BorderSide(color: colors.line),
                  labelStyle: VnlfTypography.control(colors.ink),
                  label: Text(labels[scope.index]),
                  selected: _scope == scope,
                  onSelected: (_) => setState(() => _scope = scope),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (offlineFeatures)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(vi.app.search.timKiemCongDong),
          ),
        Expanded(
          child: results == null
              ? _query.text.trim().length >= 2
                    ? const Center(child: CircularProgressIndicator())
                    : _suggestions()
              : results.when(
                  skipLoadingOnReload: false,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => ListView(
                    children: [
                      FeatureLoadError(
                        onRetry: () =>
                            ref.invalidate(searchResultsProvider(query!)),
                      ),
                    ],
                  ),
                  data: (data) => SearchResultsList(
                    results: data,
                    scope: _scope,
                    onTopic: _useTopic,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _suggestions() {
    final topics = ref.watch(popularTopicsProvider);
    return ListView(
      children: [
        Text(
          _query.text.trim().isEmpty
              ? vi.app.search.timBaiVietDu
              : vi.app.search.nhapItNhat2,
        ),
        const SizedBox(height: 16),
        Text(
          vi.app.common.chuDePhoBien,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        topics.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(popularTopicsProvider),
            child: Text(vi.app.search.taiLaiChuDe),
          ),
          data: (items) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in items)
                ActionChip(
                  label: Text(topic.name),
                  onPressed: () => _useTopic(topic),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
