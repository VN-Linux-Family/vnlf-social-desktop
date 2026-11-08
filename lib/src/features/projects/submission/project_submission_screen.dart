import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../design_system/tokens/vnlf_dimensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_client.dart';
import 'project_submission.dart';

final projectSubmissionDraftStoreProvider =
    Provider<ProjectSubmissionDraftStore>(
      (ref) => SessionStorageProjectSubmissionDraftStore(
        ref.watch(sessionStorageProvider),
      ),
    );

final projectSubmissionRepositoryProvider =
    Provider<ProjectSubmissionRepository>(
      (ref) => LiveProjectSubmissionRepository(ref.watch(apiClientProvider)),
    );

final projectFilePickerProvider =
    Provider<Future<ProjectMediaFile?> Function()>(
      (ref) => defaultProjectFilePicker,
    );

Future<ProjectMediaFile?> defaultProjectFilePicker() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
      ),
    ],
  );
  if (file == null) return null;
  const mimes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };
  final ext = file.name.split('.').last.toLowerCase();
  final mime = file.mimeType ?? mimes[ext] ?? 'application/octet-stream';
  return ProjectMediaFile(
    name: file.name,
    mime: mime,
    length: await file.length(),
    openRead: file.openRead,
  );
}

/// The caller can navigate to the returned slug after the server acknowledges it.
class ProjectSubmissionScreen extends ConsumerStatefulWidget {
  const ProjectSubmissionScreen({super.key, this.onSubmitted});
  final void Function(String slug)? onSubmitted;

  @override
  ConsumerState<ProjectSubmissionScreen> createState() =>
      _ProjectSubmissionScreenState();
}

class _ProjectSubmissionScreenState
    extends ConsumerState<ProjectSubmissionScreen> {
  final name = TextEditingController();
  final tagline = TextEditingController();
  final intro = TextEditingController();
  final repo = TextEditingController();
  final seekingNote = TextEditingController();
  final links = <({String kind, TextEditingController text})>[];
  ProjectSubmissionController? controller;
  String? owner, type, relation;
  bool noRepo = false,
      seeking = false,
      announce = true,
      previewBusy = false,
      repoMissing = false;
  int step = 0, previewRevision = 0;
  ProjectRepositoryPreview? preview;
  String? previewError;
  Map<String, String> errors = {};

  @override
  void dispose() {
    for (final field in [name, tagline, intro, repo, seekingNote]) {
      field.dispose();
    }
    for (final link in links) {
      link.text.dispose();
    }
    controller?.dispose();
    super.dispose();
  }

  void _initController(String ownerId) {
    final draftStore = ref.read(projectSubmissionDraftStoreProvider);
    final repository = ref.read(projectSubmissionRepositoryProvider);
    final ctrl = ProjectSubmissionController(
      repository: repository,
      ownerId: ownerId,
      currentOwner: () =>
          (ref.read(sessionStateProvider) ??
                  ref.read(sessionProvider).valueOrNull)
              ?.userId,
      draftStore: draftStore,
    );
    controller = ctrl;
    ctrl.init().then((_) {
      if (!mounted || controller != ctrl || !ctrl.draftRestored) return;
      final draft = ctrl.input;
      setState(() {
        name.text = draft.name;
        tagline.text = draft.tagline;
        intro.text = draft.intro;
        repo.text = draft.repoUrl;
        type = draft.type.isEmpty ? null : draft.type;
        relation = draft.relation.isEmpty ? null : draft.relation;
        noRepo = draft.noRepo;
        seeking = draft.seeking;
        seekingNote.text = draft.seekingNote;
        announce = draft.announce;
        links.clear();
        for (final link in draft.links) {
          links.add((
            kind: link.kind,
            text: TextEditingController(text: link.url),
          ));
        }
      });
    });
  }

  ProjectSubmissionInput get input => ProjectSubmissionInput(
    name: name.text,
    tagline: tagline.text,
    intro: intro.text,
    type: type ?? '',
    relation: relation ?? '',
    repoUrl: repo.text,
    noRepo: noRepo,
    links: [
      for (final link in links)
        ProjectSubmissionLink(link.kind, link.text.text),
    ],
    seeking: seeking,
    seekingNote: seekingNote.text,
    announce: announce,
    logoAssetId: controller?.input.logoAssetId,
    mediaAssetIds: controller?.input.mediaAssetIds ?? const [],
  );

  void refresh() => setState(() {});

  void _syncDraft() {
    if (controller != null &&
        controller!.isOwner &&
        !controller!.busy &&
        !controller!.uncertain &&
        controller!.receipt == null) {
      controller!.input = input;
      controller!.persistDraft();
    }
  }

  void changeRepo() {
    previewRevision++;
    preview = null;
    previewError = null;
    repoMissing = false;
    refresh();
    _syncDraft();
  }

  Future<void> loadPreview() async {
    final url = projectRepositoryUrl(repo.text);
    if (url == null || owner == null || previewBusy) return;
    final revision = ++previewRevision;
    final originalOwner = owner;
    setState(() {
      previewBusy = true;
      preview = null;
      previewError = null;
    });
    try {
      final result = await ref
          .read(projectSubmissionRepositoryProvider)
          .preview(url);
      if (!mounted ||
          revision != previewRevision ||
          (ref.read(sessionStateProvider) ??
                      ref.read(sessionProvider).valueOrNull)
                  ?.userId !=
              originalOwner) {
        return;
      }
      setState(() {
        preview = result;
      });
    } on HttpFailure catch (failure) {
      if (!mounted ||
          revision != previewRevision ||
          (ref.read(sessionStateProvider) ??
                      ref.read(sessionProvider).valueOrNull)
                  ?.userId !=
              originalOwner) {
        return;
      }
      setState(() {
        previewError = failure.code == 'PROJECT_REPO_NOT_FOUND'
            ? 'Không tìm thấy kho mã công khai này.'
            : 'Không thể xem kho mã lúc này. Bạn vẫn có thể gửi để máy chủ kiểm tra.';
        repoMissing = failure.code == 'PROJECT_REPO_NOT_FOUND';
      });
    } catch (_) {
      if (!mounted ||
          revision != previewRevision ||
          (ref.read(sessionStateProvider) ??
                      ref.read(sessionProvider).valueOrNull)
                  ?.userId !=
              originalOwner) {
        return;
      }
      setState(() {
        previewError = 'Không thể xem kho mã lúc này. Bạn vẫn có thể gửi để máy chủ kiểm tra.';
      });
    } finally {
      if (mounted) {
        setState(() {
          previewBusy = false;
        });
      }
    }
  }

  Future<void> submit() async {
    final current = controller!;
    final problems = input.validate();
    if (repoMissing && !noRepo) {
      problems['repo'] = 'Không tìm thấy kho mã công khai này.';
    }
    if (preview?.duplicateName != null &&
        projectRepositoryUrl(repo.text) == preview?.url &&
        !noRepo) {
      problems['repo'] = 'Kho mã này đã có trên VNLF.';
    }
    setState(() {
      errors = problems;
    });
    if (problems.isNotEmpty) {
      setState(() {
        step = problems.containsKey('links') ? 1 : 0;
      });
      return;
    }
    current.input = input;
    await current.submit();
    if (!mounted) return;
    setState(() {});
    if (current.receipt != null && current.isOwner) {
      widget.onSubmitted?.call(current.receipt!.slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session =
        ref.watch(sessionStateProvider) ??
        ref.watch(sessionProvider).valueOrNull;
    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('Đăng nhập để gửi dự án.')),
      );
    }
    if (owner == null) {
      owner = session.userId;
      _initController(session.userId);
    } else if (owner != session.userId) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Tài khoản đã thay đổi. Quay lại tài khoản ban đầu để xem bản nhập.',
          ),
        ),
      );
    }
    final state = controller!;
    final locked = state.busy || state.uncertain || state.receipt != null;
    final mobile =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    return Scaffold(
      appBar: mobile ? null : AppBar(title: const Text('Giới thiệu dự án')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Dự án sẽ được kiểm duyệt trước khi hiển thị với cộng đồng.',
                ),
                const SizedBox(height: 16),
                Text(
                  'Bước ${step + 1} / 3',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                if (state.uncertain)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Chưa xác định được kết quả gửi. Dữ liệu vẫn còn ở đây. Hãy kiểm tra danh sách dự án của bạn trước khi thử lại để tránh gửi trùng.',
                      ),
                    ),
                  ),
                if (state.receipt != null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Đã gửi dự án và đang chờ duyệt.'),
                    ),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                IgnorePointer(
                  ignoring: locked,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (step == 0) ..._details(locked),
                      if (step == 1) ..._links(),
                      if (step == 2) ..._review(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (step > 0)
                            TextButton(
                              onPressed: () => setState(() {
                                step--;
                              }),
                              child: const Text('Quay lại'),
                            ),
                          const Spacer(),
                          if (step < 2)
                            FilledButton(
                              onPressed: () {
                                final all = input.validate();
                                final keys = step == 0
                                    ? {
                                        'name',
                                        'tagline',
                                        'intro',
                                        'type',
                                        'relation',
                                        'repo',
                                        'logo',
                                        'media',
                                      }
                                    : {'links', 'seekingNote'};
                                final selected =
                                    Map<String, String>.fromEntries(
                                      all.entries.where(
                                        (e) => keys.contains(e.key),
                                      ),
                                    );
                                if (step == 0 && !noRepo && repoMissing) {
                                  selected['repo'] =
                                      'Không tìm thấy kho mã công khai này.';
                                }
                                if (step == 0 &&
                                    !noRepo &&
                                    preview?.duplicateName != null &&
                                    preview?.url ==
                                        projectRepositoryUrl(repo.text)) {
                                  selected['repo'] =
                                      'Kho mã này đã có trên VNLF.';
                                }
                                setState(() {
                                  errors = selected;
                                  if (selected.isEmpty) step++;
                                });
                              },
                              child: const Text('Tiếp tục'),
                            )
                          else
                            FilledButton(
                              onPressed: submit,
                              child: const Text('Gửi duyệt'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (state.busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget field(
    TextEditingController value,
    String label,
    String key, {
    int? maxLength,
    int lines = 1,
    VoidCallback? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: value,
      maxLength: maxLength,
      minLines: lines,
      maxLines: lines,
      onChanged: (_) {
        onChanged?.call();
        refresh();
        _syncDraft();
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: errors[key],
      ),
    ),
  );

  Widget choice(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> changed,
    String key,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: errors[key],
      ),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(_label(item))),
      ],
      onChanged: (v) {
        changed(v);
        _syncDraft();
      },
    ),
  );

  List<Widget> _details(bool locked) {
    final state = controller;
    return [
      choice(
        'Vai trò của bạn',
        relation,
        projectRelations,
        (v) => setState(() {
          relation = v;
        }),
        'relation',
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Dự án không có kho mã công khai'),
        value: noRepo,
        onChanged: (v) => setState(() {
          noRepo = v;
          previewRevision++;
          preview = null;
          _syncDraft();
        }),
      ),
      if (!noRepo) ...[
        field(
          repo,
          'Liên kết kho mã GitHub',
          'repo',
          maxLength: 300,
          onChanged: changeRepo,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: previewBusy || projectRepositoryUrl(repo.text) == null
                ? null
                : loadPreview,
            child: Text(previewBusy ? 'Đang kiểm tra…' : 'Xem kho mã'),
          ),
        ),
        if (previewError != null) Text(previewError!),
        if (preview != null)
          Card(
            child: ListTile(
              title: Text(preview!.name),
              subtitle: Text(
                '${preview!.description ?? ''}\n★ ${preview!.stars}  ·  Fork ${preview!.forks}${preview!.language == null ? '' : '  ·  ${preview!.language}'}${preview!.duplicateName == null ? '' : '\nĐã có trên VNLF: ${preview!.duplicateName}'}',
              ),
            ),
          ),
      ],
      field(name, 'Tên dự án', 'name', maxLength: 80),
      field(tagline, 'Mô tả ngắn', 'tagline', maxLength: 160),
      choice(
        'Thể loại',
        type,
        projectTypes,
        (v) => setState(() {
          type = v;
        }),
        'type',
      ),
      field(intro, 'Giới thiệu dự án', 'intro', maxLength: 10000, lines: 5),
      const SizedBox(height: 8),
      Text('Logo dự án', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(
        'Định dạng PNG, JPG, WebP, GIF (tối đa 10 MB)',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      if (state?.input.logoAssetId != null || state?.logoFileName != null)
        Card(
          child: ListTile(
            leading: const Icon(Icons.image),
            title: Text(state?.logoFileName ?? 'Logo đã tải lên'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa logo',
              onPressed: locked ? null : () => state?.removeLogo(),
            ),
          ),
        )
      else
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: locked || state?.uploadingMedia == true
                ? null
                : () async {
                    final picker = ref.read(projectFilePickerProvider);
                    final file = await picker();
                    if (file != null) await state?.uploadLogo(file);
                  },
            icon: const Icon(Icons.upload_file),
            label: const Text('Tải lên logo'),
          ),
        ),
      if (errors['logo'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            errors['logo']!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 16),
      Text(
        'Ảnh chụp màn hình (${state?.mediaAssets.length ?? 0}/$projectMaxMedia)',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      Text(
        'Tối đa 6 ảnh chụp màn hình minh họa ứng dụng (tối đa 10 MB mỗi ảnh)',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < (state?.mediaAssets.length ?? 0); i++)
        Card(
          child: ListTile(
            leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
            title: Text(state!.mediaAssets[i].fileName),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa ảnh',
              onPressed: locked ? null : () => state.removeScreenshot(i),
            ),
          ),
        ),
      if ((state?.mediaAssets.length ?? 0) < projectMaxMedia)
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: locked || state?.uploadingMedia == true
                ? null
                : () async {
                    final picker = ref.read(projectFilePickerProvider);
                    final file = await picker();
                    if (file != null) await state?.uploadScreenshot(file);
                  },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Thêm ảnh chụp màn hình'),
          ),
        ),
      if (state?.uploadingMedia == true)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Đang tải ảnh lên…'),
            ],
          ),
        ),
      if (errors['media'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            errors['media']!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ];
  }

  List<Widget> _links() => [
    Text('Liên kết', style: Theme.of(context).textTheme.titleMedium),
    if (errors['links'] != null)
      Text(
        errors['links']!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    for (var i = 0; i < links.length; i++) ...[
      Row(
        children: [
          Expanded(
            child: choice(
              'Loại liên kết',
              links[i].kind,
              projectLinkKinds,
              (v) => setState(() {
                links[i] = (kind: v!, text: links[i].text);
              }),
              '',
            ),
          ),
          IconButton(
            tooltip: 'Xóa liên kết',
            onPressed: () => setState(() {
              links.removeAt(i).text.dispose();
              _syncDraft();
            }),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      field(links[i].text, 'URL', '', maxLength: 500),
    ],
    if (links.length < 8)
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => setState(() {
            links.add((kind: 'WEBSITE', text: TextEditingController()));
            _syncDraft();
          }),
          icon: const Icon(Icons.add),
          label: const Text('Thêm liên kết'),
        ),
      ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Tìm người đóng góp'),
      value: seeking,
      onChanged: (v) => setState(() {
        seeking = v;
        _syncDraft();
      }),
    ),
    if (seeking)
      field(seekingNote, 'Bạn cần giúp gì?', 'seekingNote', maxLength: 200),
  ];

  List<Widget> _review() {
    final state = controller;
    return [
      Text('Xem trước', style: Theme.of(context).textTheme.titleMedium),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.text, style: Theme.of(context).textTheme.titleLarge),
              Text(tagline.text),
              const SizedBox(height: 8),
              Text('${_label(type ?? '')} · ${_label(relation ?? '')}'),
              if (state?.logoFileName != null ||
                  state?.input.logoAssetId != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Logo: ${state?.logoFileName ?? "Đã chọn"}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
              if ((state?.mediaAssets.length ?? 0) > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Ảnh chụp màn hình: ${state!.mediaAssets.length} ảnh',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 8),
              Text(intro.text),
              if (!noRepo) Text(repo.text),
              for (final link in links)
                if (link.text.text.trim().isNotEmpty)
                  Text('${_label(link.kind)}: ${link.text.text}'),
            ],
          ),
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Đăng bài giới thiệu khi được duyệt'),
        value: announce,
        onChanged: (v) => setState(() {
          announce = v;
          _syncDraft();
        }),
      ),
      const Text('Dự án mới sẽ ở trạng thái chờ duyệt.'),
    ];
  }
}

String _label(String value) =>
    const {
      'AUTHOR': 'Tác giả',
      'MAINTAINER': 'Người duy trì',
      'CONTRIBUTOR': 'Người đóng góp',
      'SHARED': 'Giới thiệu',
      'APP': 'Ứng dụng',
      'TOOL': 'Công cụ',
      'LIBRARY': 'Thư viện',
      'DISTRO': 'Bản phân phối',
      'CUSTOMIZE': 'Tùy biến',
      'EXTENSION': 'Tiện ích mở rộng',
      'VIETNAMESE': 'Tiếng Việt',
      'SYSTEM': 'Hệ thống',
      'SELFHOST': 'Tự lưu trữ',
      'GAME': 'Trò chơi',
      'LEARNING': 'Học tập',
      'OTHER': 'Khác',
      'WEBSITE': 'Trang web',
      'DOCS': 'Tài liệu',
      'DOWNLOAD': 'Tải xuống',
      'AUR': 'AUR',
      'FLATHUB': 'Flathub',
      'CHAT': 'Trò chuyện',
      'VIDEO': 'Video',
      'REPO': 'Kho mã',
    }[value] ??
    value;
