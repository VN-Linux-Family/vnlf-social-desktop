import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
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

  void _useTopic(SearchTopic topic) {
    _query.text = topic.name;
    _searchNow();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final mobile = MediaQuery.sizeOf(context).width < 840;
    final colors = VnlfColors.of(context);
    final labels = english
        ? ['All', 'Posts', 'Projects', 'Users', 'Topics']
        : ['Tất cả', 'Bài viết', 'Dự án', 'Thành viên', 'Chủ đề'];
    final query = _activeQuery;
    final results = query == null
        ? null
        : ref.watch(searchResultsProvider(query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VnlfCenterPageHeader(
          title: english ? 'Search' : 'Tìm kiếm',
          leading: !mobile && context.canPop()
              ? IconButton(
                  tooltip: english ? 'Back' : 'Quay lại',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                )
              : null,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('search-input'),
          controller: _query,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          onChanged: _changed,
          onSubmitted: (_) => _searchNow(),
          decoration: InputDecoration(
            labelText: english ? 'Search the community' : 'Tìm trong cộng đồng',
            counterText: '',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: english ? 'Clear search' : 'Xóa tìm kiếm',
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        const SizedBox(height: 12),
        if (offlineFeatures)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              english ? 'Sample community search' : 'Tìm kiếm cộng đồng mẫu',
            ),
          ),
        Expanded(
          child: results == null
              ? _query.text.trim().length >= 2
                    ? const Center(child: CircularProgressIndicator())
                    : _suggestions(english)
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

  Widget _suggestions(bool english) {
    final topics = ref.watch(popularTopicsProvider);
    return ListView(
      children: [
        Text(
          _query.text.trim().isEmpty
              ? english
                    ? 'Find posts, projects, members and topics.'
                    : 'Tìm bài viết, dự án, thành viên và chủ đề.'
              : english
              ? 'Enter at least 2 characters.'
              : 'Nhập ít nhất 2 ký tự.',
        ),
        const SizedBox(height: 16),
        Text(
          english ? 'Popular tags' : 'Chủ đề phổ biến',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        topics.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(popularTopicsProvider),
            child: Text(english ? 'Retry topics' : 'Tải lại chủ đề'),
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
