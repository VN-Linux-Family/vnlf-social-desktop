import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/providers.dart';
import '../../../../core/external_uri.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/components/vnlf_media_gallery.dart';
import '../../../../domain/models.dart';
import '../data/project_detail_repository.dart';
import '../domain/project_detail.dart';

final projectDetailRepositoryProvider = Provider<ProjectDetailRepository>((ref) => ApiProjectDetailRepository(ref.watch(apiClientProvider)));
final projectDetailProvider = StateNotifierProvider.autoDispose.family<ProjectDetailController, ProjectDetailState, String>((ref, slug) {
  final controller = ProjectDetailController(ref.watch(projectDetailRepositoryProvider), slug);
  final stop = ref.watch(apiClientProvider).observeSessionInvalidation(controller.resetSession);
  ref.onDispose(stop);
  return controller;
});

final class ProjectDetailController extends StateNotifier<ProjectDetailState> {
  ProjectDetailController(this.repository, this.slug) : super(const ProjectDetailLoading()) { load(); }
  final ProjectDetailRepository repository;
  final String slug;
  int _generation = 0;
  void resetSession() { load(refresh: true); }
  Future<void> load({bool refresh = false}) async {
    final generation = ++_generation;
    state = const ProjectDetailLoading();
    try {
      final project = await repository.fetch(slug, refresh: refresh);
      if (!mounted || generation != _generation) return;
      state = project.id.isEmpty || project.name.isEmpty ? const ProjectDetailEmpty() : ProjectDetailLoaded(project);
    } on HttpFailure catch (error) {
      if (!mounted || generation != _generation) return;
      state = error.statusCode == 404 ? const ProjectDetailEmpty() : ProjectDetailError(error);
    } on AppFailure catch (error) {
      if (!mounted || generation != _generation) return;
      state = ProjectDetailError(error);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = const ProjectDetailError(TransportFailure());
    }
  }
  @override
  void dispose() { _generation++; super.dispose(); }
}

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.slug});
  final String slug;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectDetailProvider(slug));
    final en = Localizations.localeOf(context).languageCode == 'en';
    return switch (state) {
      ProjectDetailLoading() => const Center(child: CircularProgressIndicator()),
      ProjectDetailEmpty() => Center(child: Text(en ? 'Project unavailable' : 'Không tìm thấy dự án')),
      ProjectDetailError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(en ? 'Could not load project' : 'Không tải được dự án'), TextButton(onPressed: () => ref.read(projectDetailProvider(slug).notifier).load(refresh: true), child: Text(en ? 'Retry' : 'Thử lại'))])),
      ProjectDetailLoaded(:final project) => _Detail(project: project, en: en),
    };
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.project, required this.en});
  final ProjectDetail project;
  final bool en;
  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final repo = project.repo;
    final images = project.media.where((m) => externalWebUri(m.fullUrl) != null).map((m) => PostMediaData(url: m.fullUrl, width: m.width, height: m.height, alt: '${en ? 'Screenshot' : 'Ảnh chụp'} · ${project.name}')).toList();
    final paragraphs = md.Document().parseLines(project.intro.split('\n')).map((node) => node.textContent).where((text) => text.trim().isNotEmpty);
    return SingleChildScrollView(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (project.status != 'APPROVED' && project.status.isNotEmpty) _section(context, en ? 'Review status' : 'Trạng thái duyệt', [Text(_status(project.status, en)), if (project.reviewNote != null && project.reviewNote!.isNotEmpty) Text(project.reviewNote!)]),
      if (project.hasPendingChanges) Text(en ? 'Changes awaiting review' : 'Thay đổi đang chờ duyệt'),
      if (repo?.unavailable == true) Text(en ? 'Repository unavailable' : 'Kho mã nguồn không còn khả dụng'),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 64, height: 64, child: externalWebUri(project.logoUrl) == null ? Icon(Icons.folder_outlined, color: colors.muted) : Image.network(project.logoUrl!, fit: BoxFit.cover, cacheWidth: 128, errorBuilder: (_, _, _) => const Icon(Icons.folder_outlined)))),
        const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_tier(project.tier, en)} · ${_type(project.type, en)}', style: VnlfTypography.meta(colors.muted)), Text(project.name, style: VnlfTypography.h1(colors.ink)), Text(project.tagline, style: VnlfTypography.body(colors.ink))])),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 4, children: [if (repo != null) _Link(label: 'GitHub', url: repo.url), if (repo?.homepage != null) _Link(label: en ? 'Website' : 'Trang web', url: repo!.homepage!), if (repo?.releaseUrl != null) _Link(label: '${en ? 'Release' : 'Bản phát hành'} ${repo!.releaseTag ?? ''}', url: repo.releaseUrl!)]),
      if (repo != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Wrap(spacing: 18, runSpacing: 6, children: [if (repo.stars != null) Text('★ ${repo.stars}'), if (repo.forks != null) Text('${repo.forks} forks'), if (repo.contributors != null) Text('${repo.contributors} ${en ? 'contributors' : 'người đóng góp'}'), if (repo.openIssues != null) Text('${repo.openIssues} issues'), if (repo.openPrs != null) Text('${repo.openPrs} PRs'), if (repo.languages.isNotEmpty) Text(repo.languages.join(' · '))])),
      LayoutBuilder(builder: (context, constraints) {
        final main = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (images.isNotEmpty) _section(context, en ? 'Screenshots' : 'Ảnh chụp', [VnlfMediaGallery(items: images)]),
          _section(context, en ? 'Introduction' : 'Giới thiệu', [if (project.intro.trim().isEmpty) Text(en ? 'No introduction' : 'Chưa có giới thiệu') else for (final paragraph in paragraphs) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(paragraph, style: VnlfTypography.body(colors.ink)))]),
          if (project.discussionSlug != null && project.discussionSlug!.isNotEmpty) _section(context, en ? 'Discussion' : 'Thảo luận', [TextButton(onPressed: () => context.push('/a/${Uri.encodeComponent(project.discussionSlug!)}'), child: Text(en ? 'Open discussion' : 'Mở bài thảo luận'))]),
        ]);
        final aside = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (project.status == 'APPROVED') _section(context, en ? 'Ratings' : 'Đánh giá', [Text(project.rating.average == null ? (en ? 'No ratings yet' : 'Chưa có đánh giá') : '★ ${project.rating.average!.toStringAsFixed(1)} · ${project.rating.count}'), if (project.myRating != null) Text('${en ? 'Your rating' : 'Đánh giá của bạn'}: ${project.myRating} / 5'), if (project.ratingDistribution.isNotEmpty) for (var i = 0; i < project.ratingDistribution.length && i < 5; i++) Text('${i + 1} ★  ${project.ratingDistribution[i]}')]),
          _section(context, en ? 'Posted by' : 'Người đăng', [Text(project.ownerName), if (project.ownerUsername.isNotEmpty) Text('@${project.ownerUsername} · ${_relation(project.relation, en)}')]),
          if (project.seeking) _section(context, en ? 'Seeking contributors' : 'Tìm người đóng góp', [Text(project.seekingNote)]),
          _section(context, en ? 'Information' : 'Thông tin', [if (repo != null) _Link(label: '${repo.owner}/${repo.name}', url: repo.url), if (repo?.license != null) Text('${en ? 'License' : 'Giấy phép'}: ${repo!.license}'), if (repo != null && repo.topics.isNotEmpty) Text(repo.topics.join(' · ')), for (final link in project.links) _Link(label: _linkKind(link.kind, en), url: link.url)]),
        ]);
        return constraints.maxWidth >= 750 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 2, child: main), const SizedBox(width: 24), Expanded(child: aside)]) : Column(children: [main, aside]);
      }),
    ])))));
  }
}

Widget _section(BuildContext context, String title, List<Widget> children) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: VnlfTypography.h3(VnlfColors.of(context).ink)), const SizedBox(height: 8), ...children]));
class _Link extends StatelessWidget {
  const _Link({required this.label, required this.url});
  final String label, url;
  @override
  Widget build(BuildContext context) {
    final uri = externalWebUri(url);
    if (uri == null) return const SizedBox.shrink();
    return TextButton(onPressed: () async { await launchUrl(uri, mode: LaunchMode.externalApplication); }, child: Text(label));
  }
}
String _status(String value, bool en) => switch (value) { 'PENDING' => en ? 'Awaiting review' : 'Đang chờ duyệt', 'REJECTED' => en ? 'Rejected' : 'Đã bị từ chối', 'HIDDEN' => en ? 'Hidden' : 'Đã bị ẩn', _ => value };
String _tier(String value, bool en) => switch (value) { 'VNLF' => 'VNLF', 'PARTNER' => en ? 'Partner' : 'Đối tác', 'COMMUNITY' => en ? 'Community' : 'Cộng đồng', _ => value };
String _relation(String value, bool en) => switch (value) { 'AUTHOR' => en ? 'Author' : 'Tác giả', 'MAINTAINER' => en ? 'Maintainer' : 'Người duy trì', 'CONTRIBUTOR' => en ? 'Contributor' : 'Người đóng góp', 'SHARED' => en ? 'Shared' : 'Giới thiệu', _ => value };
String _type(String value, bool en) => switch (value) { 'APP' => en ? 'App' : 'Ứng dụng', 'TOOL' => en ? 'Tool' : 'Công cụ', 'LIBRARY' => en ? 'Library' : 'Thư viện', 'DISTRO' => 'Distro', 'CUSTOMIZE' => en ? 'Customization' : 'Tùy biến', 'EXTENSION' => en ? 'Extension' : 'Tiện ích', 'VIETNAMESE' => en ? 'Vietnamese' : 'Tiếng Việt', 'SYSTEM' => en ? 'System' : 'Hệ thống', 'SELFHOST' => 'Self-host', 'GAME' => en ? 'Game' : 'Trò chơi', 'LEARNING' => en ? 'Learning' : 'Học tập', 'OTHER' => en ? 'Other' : 'Khác', _ => value };
String _linkKind(String value, bool en) => switch (value) { 'WEBSITE' => en ? 'Website' : 'Trang web', 'DOCS' => en ? 'Documentation' : 'Tài liệu', 'DOWNLOAD' => en ? 'Download' : 'Tải xuống', 'CHAT' => en ? 'Chat' : 'Trò chuyện', 'VIDEO' => 'Video', 'REPO' => en ? 'Repository' : 'Kho mã nguồn', 'OTHER' => en ? 'Other link' : 'Liên kết khác', _ => value };
