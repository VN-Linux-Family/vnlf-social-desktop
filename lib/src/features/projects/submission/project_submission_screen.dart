import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_client.dart';
import 'project_submission.dart';

/// The caller can navigate to the returned slug after the server acknowledges it.
class ProjectSubmissionScreen extends ConsumerStatefulWidget {
  const ProjectSubmissionScreen({super.key, this.onSubmitted});
  final void Function(String slug)? onSubmitted;

  @override
  ConsumerState<ProjectSubmissionScreen> createState() => _ProjectSubmissionScreenState();
}

class _ProjectSubmissionScreenState extends ConsumerState<ProjectSubmissionScreen> {
  final name = TextEditingController();
  final tagline = TextEditingController();
  final intro = TextEditingController();
  final repo = TextEditingController();
  final seekingNote = TextEditingController();
  final links = <({String kind, TextEditingController text})>[];
  ProjectSubmissionController? controller;
  String? owner, type, relation;
  bool noRepo = false, seeking = false, announce = true, previewBusy = false, repoMissing = false;
  int step = 0, previewRevision = 0;
  ProjectRepositoryPreview? preview;
  String? previewError;
  Map<String, String> errors = {};

  @override
  void dispose() {
    for (final field in [name, tagline, intro, repo, seekingNote]) { field.dispose(); }
    for (final link in links) { link.text.dispose(); }
    controller?.dispose();
    super.dispose();
  }

  ProjectSubmissionInput get input => ProjectSubmissionInput(
    name: name.text, tagline: tagline.text, intro: intro.text,
    type: type ?? '', relation: relation ?? '', repoUrl: repo.text, noRepo: noRepo,
    links: [for (final link in links) ProjectSubmissionLink(link.kind, link.text.text)],
    seeking: seeking, seekingNote: seekingNote.text, announce: announce,
  );

  void refresh() => setState(() {});
  void changeRepo() { previewRevision++; preview = null; previewError = null; repoMissing = false; refresh(); }
  Future<void> loadPreview() async {
    final url = projectRepositoryUrl(repo.text);
    if (url == null || owner == null || previewBusy) return;
    final revision = ++previewRevision;
    final originalOwner = owner;
    setState(() { previewBusy = true; preview = null; previewError = null; });
    try {
      final result = await LiveProjectSubmissionRepository(ref.read(apiClientProvider)).preview(url);
      if (!mounted || revision != previewRevision || (ref.read(sessionStateProvider) ?? ref.read(sessionProvider).valueOrNull)?.userId != originalOwner) return;
      setState(() { preview = result; });
    } on HttpFailure catch (failure) {
      if (!mounted || revision != previewRevision || (ref.read(sessionStateProvider) ?? ref.read(sessionProvider).valueOrNull)?.userId != originalOwner) return;
      setState(() { previewError = failure.code == 'PROJECT_REPO_NOT_FOUND' ? 'Không tìm thấy kho mã công khai này.' : 'Không thể xem kho mã lúc này. Bạn vẫn có thể gửi để máy chủ kiểm tra.'; repoMissing = failure.code == 'PROJECT_REPO_NOT_FOUND'; });
    } catch (_) {
      if (!mounted || revision != previewRevision || (ref.read(sessionStateProvider) ?? ref.read(sessionProvider).valueOrNull)?.userId != originalOwner) return;
      setState(() { previewError = 'Không thể xem kho mã lúc này. Bạn vẫn có thể gửi để máy chủ kiểm tra.'; });
    } finally {
      if (mounted) setState(() { previewBusy = false; });
    }
  }

  Future<void> submit() async {
    final current = controller!;
    final problems = input.validate();
    if (repoMissing && !noRepo) problems['repo'] = 'Không tìm thấy kho mã công khai này.';
    if (preview?.duplicateName != null && projectRepositoryUrl(repo.text) == preview?.url && !noRepo) {
      problems['repo'] = 'Kho mã này đã có trên VNLF.';
    }
    setState(() { errors = problems; });
    if (problems.isNotEmpty) { setState(() { step = problems.containsKey('links') ? 1 : 0; }); return; }
    current.input = input;
    await current.submit();
    if (!mounted) return;
    setState(() {});
    if (current.receipt != null && current.isOwner) widget.onSubmitted?.call(current.receipt!.slug);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionStateProvider) ?? ref.watch(sessionProvider).valueOrNull;
    if (session == null) return const Scaffold(body: Center(child: Text('Đăng nhập để gửi dự án.')));
    owner ??= session.userId;
    if (owner != session.userId) return const Scaffold(body: Center(child: Text('Tài khoản đã thay đổi. Quay lại tài khoản ban đầu để xem bản nhập.')));
    controller ??= ProjectSubmissionController(repository: LiveProjectSubmissionRepository(ref.read(apiClientProvider)), ownerId: owner!, currentOwner: () => (ref.read(sessionStateProvider) ?? ref.read(sessionProvider).valueOrNull)?.userId);
    final state = controller!;
    final locked = state.busy || state.uncertain || state.receipt != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu dự án')),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 780), child: ListenableBuilder(listenable: state, builder: (context, _) => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Dự án sẽ được kiểm duyệt trước khi hiển thị với cộng đồng.'),
        const SizedBox(height: 16),
        Text('Bước ${step + 1} / 3', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        if (state.uncertain) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Chưa xác định được kết quả gửi. Dữ liệu vẫn còn ở đây. Hãy kiểm tra danh sách dự án của bạn trước khi thử lại để tránh gửi trùng.'))),
        if (state.receipt != null) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Đã gửi dự án và đang chờ duyệt.'))),
        if (state.error != null) Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        IgnorePointer(ignoring: locked, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (step == 0) ..._details(),
          if (step == 1) ..._links(),
          if (step == 2) ..._review(),
          const SizedBox(height: 20),
          Row(children: [
            if (step > 0) TextButton(onPressed: () => setState(() { step--; }), child: const Text('Quay lại')),
            const Spacer(),
            if (step < 2) FilledButton(onPressed: () {
              final all = input.validate();
              final keys = step == 0 ? {'name', 'tagline', 'intro', 'type', 'relation', 'repo'} : {'links'};
              final selected = Map<String, String>.fromEntries(all.entries.where((e) => keys.contains(e.key)));
              if (step == 0 && !noRepo && repoMissing) selected['repo'] = 'Không tìm thấy kho mã công khai này.';
              if (step == 0 && !noRepo && preview?.duplicateName != null && preview?.url == projectRepositoryUrl(repo.text)) selected['repo'] = 'Kho mã này đã có trên VNLF.';
              setState(() { errors = selected; if (selected.isEmpty) step++; });
            }, child: const Text('Tiếp tục')) else FilledButton(onPressed: submit, child: const Text('Gửi duyệt')),
          ]),
        ])),
        if (state.busy) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
      ])))),
    );
  }

  Widget field(TextEditingController value, String label, String key, {int? maxLength, int lines = 1, VoidCallback? onChanged}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: value, maxLength: maxLength, minLines: lines, maxLines: lines, onChanged: (_) { onChanged?.call(); refresh(); }, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), errorText: errors[key])));
  Widget choice(String label, String? value, List<String> values, ValueChanged<String?> changed, String key) => Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(value: value, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), errorText: errors[key]), items: [for (final item in values) DropdownMenuItem(value: item, child: Text(_label(item)))], onChanged: changed));

  List<Widget> _details() => [
    choice('Vai trò của bạn', relation, projectRelations, (v) => setState(() { relation = v; }), 'relation'),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Dự án không có kho mã công khai'), value: noRepo, onChanged: (v) => setState(() { noRepo = v; previewRevision++; preview = null; })),
    if (!noRepo) ...[
      field(repo, 'Liên kết kho mã GitHub', 'repo', maxLength: 300, onChanged: changeRepo),
      Align(alignment: Alignment.centerLeft, child: OutlinedButton(onPressed: previewBusy || projectRepositoryUrl(repo.text) == null ? null : loadPreview, child: Text(previewBusy ? 'Đang kiểm tra…' : 'Xem kho mã'))),
      if (previewError != null) Text(previewError!),
      if (preview != null) Card(child: ListTile(title: Text(preview!.name), subtitle: Text('${preview!.description ?? ''}\n★ ${preview!.stars}  ·  Fork ${preview!.forks}${preview!.language == null ? '' : '  ·  ${preview!.language}'}${preview!.duplicateName == null ? '' : '\nĐã có trên VNLF: ${preview!.duplicateName}'}'))),
    ],
    field(name, 'Tên dự án', 'name', maxLength: 80),
    field(tagline, 'Mô tả ngắn', 'tagline', maxLength: 160),
    choice('Thể loại', type, projectTypes, (v) => setState(() { type = v; }), 'type'),
    field(intro, 'Giới thiệu dự án', 'intro', maxLength: 10000, lines: 5),
    const Text('Ảnh dự án và logo chưa hỗ trợ trên ứng dụng này.'),
  ];

  List<Widget> _links() => [
    Text('Liên kết', style: Theme.of(context).textTheme.titleMedium),
    if (errors['links'] != null) Text(errors['links']!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    for (var i = 0; i < links.length; i++) ...[
      Row(children: [Expanded(child: choice('Loại liên kết', links[i].kind, projectLinkKinds, (v) => setState(() { links[i] = (kind: v!, text: links[i].text); }), '')), IconButton(tooltip: 'Xóa liên kết', onPressed: () => setState(() { links.removeAt(i).text.dispose(); }), icon: const Icon(Icons.delete_outline))]),
      field(links[i].text, 'URL', '', maxLength: 500),
    ],
    if (links.length < 8) Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: () => setState(() { links.add((kind: 'WEBSITE', text: TextEditingController())); }), icon: const Icon(Icons.add), label: const Text('Thêm liên kết'))),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Tìm người đóng góp'), value: seeking, onChanged: (v) => setState(() { seeking = v; })),
    if (seeking) field(seekingNote, 'Bạn cần giúp gì?', 'seekingNote', maxLength: 200),
  ];

  List<Widget> _review() => [
    Text('Xem trước', style: Theme.of(context).textTheme.titleMedium),
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name.text, style: Theme.of(context).textTheme.titleLarge), Text(tagline.text), const SizedBox(height: 8), Text('${_label(type ?? '')} · ${_label(relation ?? '')}'), const SizedBox(height: 8), Text(intro.text), if (!noRepo) Text(repo.text), for (final link in links) if (link.text.text.trim().isNotEmpty) Text('${_label(link.kind)}: ${link.text.text}')]))),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Đăng bài giới thiệu khi được duyệt'), value: announce, onChanged: (v) => setState(() { announce = v; })),
    const Text('Dự án mới sẽ ở trạng thái chờ duyệt.'),
  ];
}

String _label(String value) => const {
  'AUTHOR': 'Tác giả', 'MAINTAINER': 'Người duy trì', 'CONTRIBUTOR': 'Người đóng góp', 'SHARED': 'Giới thiệu',
  'APP': 'Ứng dụng', 'TOOL': 'Công cụ', 'LIBRARY': 'Thư viện', 'DISTRO': 'Bản phân phối', 'CUSTOMIZE': 'Tùy biến', 'EXTENSION': 'Tiện ích mở rộng', 'VIETNAMESE': 'Tiếng Việt', 'SYSTEM': 'Hệ thống', 'SELFHOST': 'Tự lưu trữ', 'GAME': 'Trò chơi', 'LEARNING': 'Học tập', 'OTHER': 'Khác',
  'WEBSITE': 'Trang web', 'DOCS': 'Tài liệu', 'DOWNLOAD': 'Tải xuống', 'AUR': 'AUR', 'FLATHUB': 'Flathub', 'CHAT': 'Trò chuyện', 'VIDEO': 'Video', 'REPO': 'Kho mã',
}[value] ?? value;
