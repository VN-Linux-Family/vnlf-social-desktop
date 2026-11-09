import '../../../../i18n/vi.dart';
import '../rating/project_rating_control.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../composer/domain/compose_document.dart';
import '../../../../design_system/components/vnlf_rich_content.dart';
import '../../../../core/external_uri.dart';
import '../../../../core/vnlf_navigation_helper.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/components/vnlf_media_gallery.dart';
import '../../../../domain/models.dart';
import '../data/project_detail_repository.dart';
import '../domain/project_detail.dart';

final projectDetailRepositoryProvider = Provider<ProjectDetailRepository>(
  (ref) => ApiProjectDetailRepository(ref.watch(apiClientProvider)),
);
final projectDetailProvider = StateNotifierProvider.autoDispose
    .family<ProjectDetailController, ProjectDetailState, String>((ref, slug) {
      final controller = ProjectDetailController(
        ref.watch(projectDetailRepositoryProvider),
        slug,
      );
      final stop = ref
          .watch(apiClientProvider)
          .observeSessionInvalidation(controller.resetSession);
      ref.onDispose(stop);
      return controller;
    });

final class ProjectDetailController extends StateNotifier<ProjectDetailState> {
  ProjectDetailController(this.repository, this.slug)
    : super(const ProjectDetailLoading()) {
    load();
  }
  final ProjectDetailRepository repository;
  final String slug;
  int _generation = 0;
  void resetSession() {
    load(refresh: true);
  }

  Future<void> load({bool refresh = false}) async {
    final generation = ++_generation;
    state = const ProjectDetailLoading();
    try {
      final project = await repository.fetch(slug, refresh: refresh);
      if (!mounted || generation != _generation) return;
      state = project.id.isEmpty || project.name.isEmpty
          ? const ProjectDetailEmpty()
          : ProjectDetailLoaded(project);
    } on HttpFailure catch (error) {
      if (!mounted || generation != _generation) return;
      state = error.statusCode == 404
          ? const ProjectDetailEmpty()
          : ProjectDetailError(error);
    } on AppFailure catch (error) {
      if (!mounted || generation != _generation) return;
      state = ProjectDetailError(error);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = const ProjectDetailError(TransportFailure());
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.slug});
  final String slug;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectDetailProvider(slug));
    return switch (state) {
      ProjectDetailLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      ProjectDetailEmpty() => Center(
        child: Text(vi.app.projects.khongTimThayDu),
      ),
      ProjectDetailError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vi.app.projects.khongTaiDuocDu),
            TextButton(
              onPressed: () => ref
                  .read(projectDetailProvider(slug).notifier)
                  .load(refresh: true),
              child: Text(vi.common.thuLai),
            ),
          ],
        ),
      ),
      ProjectDetailLoaded(:final project) => _Detail(
        project: project,
        onRefresh: () {
          ref.read(projectDetailProvider(slug).notifier).load(refresh: true);
        },
      ),
    };
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.project, required this.onRefresh});
  final ProjectDetail project;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final repo = project.repo;
    final images = project.media
        .where((m) => externalWebUri(m.fullUrl) != null)
        .map(
          (m) => PostMediaData(
            url: m.fullUrl,
            width: m.width,
            height: m.height,
            alt: '${vi.app.projects.anhChup} · ${project.name}',
          ),
        )
        .toList();
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (project.status != 'APPROVED' && project.status.isNotEmpty)
                  _section(context, vi.app.projects.trangThaiDuyet, [
                    Text(_status(project.status)),
                    if (project.reviewNote != null &&
                        project.reviewNote!.isNotEmpty)
                      Text(project.reviewNote!),
                  ]),
                if (project.hasPendingChanges)
                  Text(vi.app.projects.thayDoiDangCho),
                if (repo?.unavailable == true)
                  Text(vi.app.projects.khoMaNguonKhong),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: externalWebUri(project.logoUrl) == null
                            ? Icon(Icons.folder_outlined, color: colors.muted)
                            : Image.network(
                                project.logoUrl!,
                                fit: BoxFit.cover,
                                cacheWidth: 128,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.folder_outlined),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_tier(project.tier)} · ${_type(project.type)}',
                            style: VnlfTypography.meta(colors.muted),
                          ),
                          Text(
                            project.name,
                            style: VnlfTypography.h1(colors.ink),
                          ),
                          Text(
                            project.tagline,
                            style: VnlfTypography.body(colors.ink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (repo != null)
                      _Link(label: vi.app.projects.khoMaNguon, url: repo.url),
                    if (repo?.homepage != null)
                      _Link(
                        label: vi.app.common.trangWeb,
                        url: repo!.homepage!,
                      ),
                    if (repo?.releaseUrl != null)
                      _Link(
                        label:
                            '${vi.projects.banPhatHanh} ${repo!.releaseTag ?? ''}',
                        url: repo.releaseUrl!,
                      ),
                  ],
                ),
                if (repo != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 6,
                      children: [
                        if (repo.stars != null) Text('★ ${repo.stars}'),
                        if (repo.forks != null) Text('${repo.forks} forks'),
                        if (repo.contributors != null)
                          Text(
                            '${repo.contributors} ${vi.app.projects.nguoiDongGop2}',
                          ),
                        if (repo.openIssues != null)
                          Text('${repo.openIssues} issues'),
                        if (repo.openPrs != null) Text('${repo.openPrs} PRs'),
                        if (repo.languages.isNotEmpty)
                          Text(repo.languages.join(' · ')),
                      ],
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final main = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (images.isNotEmpty)
                          _section(context, vi.app.projects.anhChup, [
                            VnlfMediaGallery(items: images),
                          ]),
                        _section(context, vi.projects.gioiThieu, [
                          if (project.intro.trim().isEmpty)
                            Text(vi.app.projects.chuaCoGioiThieu)
                          else
                            VnlfRichContent(
                              document: composeDocument(project.intro),
                              selectable: true,
                            ),
                        ]),
                        if (project.discussionSlug != null &&
                            project.discussionSlug!.isNotEmpty)
                          _section(context, vi.projects.thaoLuan, [
                            _Link(
                              label: vi.app.projects.moBaiThaoLuan,
                              url:
                                  'https://vietnamlinuxfamily.net/a/${Uri.encodeComponent(project.discussionSlug!)}',
                            ),
                          ]),
                      ],
                    );
                    final aside = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (project.status == 'APPROVED')
                          _section(context, vi.projects.danhGia, [
                            ProjectRatingControl(
                              key: ObjectKey(project),
                              projectId: project.id,
                              initialAverage: project.rating.average,
                              initialCount: project.rating.count,
                              initialMyRating: project.myRating,
                              initialDistribution: project.ratingDistribution,
                              canRate: project.canRate,
                              onRefresh: onRefresh,
                            ),
                          ]),
                        _section(context, vi.projects.nguoiDang, [
                          Text(project.ownerName),
                          if (project.ownerUsername.isNotEmpty)
                            Text(
                              [
                                '@${project.ownerUsername}',
                                if (project.relation.isNotEmpty)
                                  _relation(project.relation),
                              ].join(' · '),
                            ),
                        ]),
                        if (project.seeking)
                          _section(context, vi.projects.timNguoiDongGop, [
                            Text(project.seekingNote),
                          ]),
                        if (repo != null || project.links.isNotEmpty)
                          _section(context, vi.projects.thongTin, [
                            if (repo != null)
                              _Link(
                                label: '${repo.owner}/${repo.name}',
                                url: repo.url,
                              ),
                            if (repo?.license != null)
                              Text(
                                '${vi.app.projects.giayPhep}: ${repo!.license}',
                              ),
                            if (repo != null && repo.topics.isNotEmpty)
                              Text(repo.topics.join(' · ')),
                            for (final link in project.links)
                              _Link(label: _linkKind(link.kind), url: link.url),
                          ]),
                      ],
                    );
                    return constraints.maxWidth >= 750
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: main),
                              const SizedBox(width: 24),
                              Expanded(child: aside),
                            ],
                          )
                        : Column(children: [main, aside]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _section(BuildContext context, String title, List<Widget> children) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VnlfTypography.h3(VnlfColors.of(context).ink)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.url});
  final String label, url;
  @override
  Widget build(BuildContext context) {
    final uri = externalWebUri(url);
    if (uri == null) return const SizedBox.shrink();
    return TextButton(
      onPressed: () async {
        var opened = false;
        try {
          opened = await openVnlfLink(context, url);
        } catch (_) {}
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(vi.app.common.khongMoDuocLien)),
          );
        }
      },
      child: Text(label),
    );
  }
}

String _status(String value) => switch (value) {
  'PENDING' => vi.app.projects.dangChoDuyet,
  'REJECTED' => vi.app.projects.daBiTuChoi,
  'HIDDEN' => vi.app.projects.daBiAn,
  _ => value,
};
String _tier(String value) => switch (value) {
  'VNLF' => 'VNLF',
  'PARTNER' => vi.app.projects.doiTac,
  'COMMUNITY' => vi.projects.phanCongDong,
  _ => value,
};
String _relation(String value) => switch (value) {
  'AUTHOR' => vi.app.projects.tacGia,
  'MAINTAINER' => vi.app.projects.nguoiDuyTri,
  'CONTRIBUTOR' => vi.app.projects.nguoiDongGop,
  'SHARED' => vi.projects.gioiThieu,
  _ => value,
};
String _type(String value) => switch (value) {
  'APP' => vi.app.projects.ungDung,
  'TOOL' => vi.app.projects.congCu,
  'LIBRARY' => vi.app.projects.thuVien,
  'DISTRO' => 'Distro',
  'CUSTOMIZE' => vi.app.projects.tuyBien,
  'EXTENSION' => vi.app.projects.tienIch,
  'VIETNAMESE' => vi.app.projects.tiengViet,
  'SYSTEM' => vi.app.projects.heThong,
  'SELFHOST' => 'Self-host',
  'GAME' => vi.app.projects.troChoi,
  'LEARNING' => vi.app.projects.hocTap,
  'OTHER' => vi.projects.chiaSeKhac,
  _ => value,
};
String _linkKind(String value) => switch (value) {
  'WEBSITE' => vi.app.common.trangWeb,
  'DOCS' => vi.app.projects.taiLieu,
  'DOWNLOAD' => vi.app.projects.taiXuong,
  'CHAT' => vi.app.projects.troChuyen,
  'VIDEO' => 'Video',
  'REPO' => vi.app.projects.khoMaNguon,
  'OTHER' => vi.app.projects.lienKetKhac,
  _ => value,
};
