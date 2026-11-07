import '../domain/search_results.dart';

final class FixtureSearchRepository implements SearchRepository {
  const FixtureSearchRepository(this._load);
  final Future<SearchResults> Function() _load;

  @override
  Future<SearchResults> search(String query) async =>
      (await _load()).matching(query);

  @override
  Future<List<SearchTopic>> popularTopics() async => const [
    SearchTopic(name: 'Arch Linux', slug: 'arch-linux', count: 2),
    SearchTopic(name: 'Wayland', slug: 'wayland', count: 1),
    SearchTopic(name: 'CachyOS', slug: 'cachyos', count: 1),
    SearchTopic(name: 'Hyprland', slug: 'hyprland', count: 1),
    SearchTopic(name: 'Kernel', slug: 'kernel', count: 1),
    SearchTopic(name: 'Rust', slug: 'rust', count: 1),
  ];
}
