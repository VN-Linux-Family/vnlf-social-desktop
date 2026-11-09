import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../../../core/session_storage_contract.dart';
import '../../../i18n/vi.dart';

const projectTypes = <String>[
  'APP',
  'TOOL',
  'LIBRARY',
  'DISTRO',
  'CUSTOMIZE',
  'EXTENSION',
  'VIETNAMESE',
  'SYSTEM',
  'SELFHOST',
  'GAME',
  'LEARNING',
  'OTHER',
];

const projectRelations = <String>[
  'AUTHOR',
  'MAINTAINER',
  'CONTRIBUTOR',
  'SHARED',
];

const projectLinkKinds = <String>[
  'WEBSITE',
  'DOCS',
  'DOWNLOAD',
  'AUR',
  'FLATHUB',
  'CHAT',
  'VIDEO',
  'REPO',
  'OTHER',
];

const projectImageLimit = 10 * 1024 * 1024; // 10 MiB
const projectMaxMedia = 6;
const projectMediaMimes = <String>{
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
};

final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

final class ProjectSubmissionLink {
  const ProjectSubmissionLink(this.kind, this.url);
  final String kind;
  final String url;
}

String? projectRepositoryUrl(String text) {
  final value = text.trim();
  if (value.isEmpty || value.length > 300) return null;
  String? owner;
  String? name;
  final ssh = RegExp(
    r'^(?:ssh://)?git@github\.com[:/]([^/\s]+)/([^/\s]+?)/?$',
    caseSensitive: false,
  ).firstMatch(value);
  if (ssh != null) {
    owner = ssh[1];
    name = ssh[2];
  } else {
    final uri = Uri.tryParse(
      RegExp(r'^[a-z][a-z\d+.-]*://', caseSensitive: false).hasMatch(value)
          ? value
          : 'https://$value',
    );
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        !{'github.com', 'www.github.com'}.contains(uri.host.toLowerCase()) ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort) {
      return null;
    }
    final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (parts.length < 2) return null;
    owner = parts[0];
    name = parts[1];
  }
  name = name?.replaceFirst(RegExp(r'\.git$', caseSensitive: false), '');
  const pages = {
    'about',
    'account',
    'apps',
    'codespaces',
    'collections',
    'contact',
    'customer-stories',
    'dashboard',
    'enterprise',
    'events',
    'explore',
    'features',
    'issues',
    'join',
    'login',
    'logout',
    'marketplace',
    'new',
    'notifications',
    'orgs',
    'organizations',
    'pricing',
    'pulls',
    'readme',
    'search',
    'security',
    'settings',
    'site',
    'sponsors',
    'team',
    'topics',
    'trending',
    'users',
  };
  if (owner == null ||
      name == null ||
      pages.contains(owner.toLowerCase()) ||
      !RegExp(
        r'^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$',
        caseSensitive: false,
      ).hasMatch(owner) ||
      !RegExp(r'^[\w.-]{1,100}$').hasMatch(name) ||
      name == '.' ||
      name == '..') {
    return null;
  }
  return 'https://github.com/$owner/$name';
}

bool _validLink(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      {'http', 'https'}.contains(uri.scheme) &&
      uri.userInfo.isEmpty &&
      uri.host.contains('.');
}

final class ProjectMediaFile {
  const ProjectMediaFile({
    required this.name,
    required this.mime,
    required this.length,
    required this.openRead,
  });

  final String name;
  final String mime;
  final int length;
  final Stream<List<int>> Function() openRead;
}

typedef ProjectMediaTransfer = Future<void> Function(
  Uri url,
  ProjectMediaFile file,
  Map<String, String> headers,
);

final class PendingProjectMedia {
  const PendingProjectMedia({
    required this.assetId,
    required this.isLogo,
    required this.fileName,
    required this.uploadUrl,
    required this.headers,
    required this.file,
    required this.session,
    required this.ownerToken,
  });

  final String assetId;
  final bool isLogo;
  final String fileName;
  final Uri uploadUrl;
  final Map<String, String> headers;
  final ProjectMediaFile file;
  final ApiSessionScope session;
  final Object ownerToken;
}

final class ProjectSubmissionInput {
  const ProjectSubmissionInput({
    this.name = '',
    this.tagline = '',
    this.intro = '',
    this.type = '',
    this.relation = '',
    this.repoUrl = '',
    this.noRepo = false,
    this.links = const [],
    this.seeking = false,
    this.seekingNote = '',
    this.announce = true,
    this.logoAssetId,
    this.mediaAssetIds = const [],
  });

  final String name, tagline, intro, type, relation, repoUrl, seekingNote;
  final bool noRepo, seeking, announce;
  final List<ProjectSubmissionLink> links;
  final String? logoAssetId;
  final List<String> mediaAssetIds;

  ProjectSubmissionInput copyWith({
    String? name,
    String? tagline,
    String? intro,
    String? type,
    String? relation,
    String? repoUrl,
    bool? noRepo,
    List<ProjectSubmissionLink>? links,
    bool? seeking,
    String? seekingNote,
    bool? announce,
    String? logoAssetId,
    bool clearLogo = false,
    List<String>? mediaAssetIds,
  }) => ProjectSubmissionInput(
    name: name ?? this.name,
    tagline: tagline ?? this.tagline,
    intro: intro ?? this.intro,
    type: type ?? this.type,
    relation: relation ?? this.relation,
    repoUrl: repoUrl ?? this.repoUrl,
    noRepo: noRepo ?? this.noRepo,
    links: links ?? this.links,
    seeking: seeking ?? this.seeking,
    seekingNote: seekingNote ?? this.seekingNote,
    announce: announce ?? this.announce,
    logoAssetId: clearLogo ? null : (logoAssetId ?? this.logoAssetId),
    mediaAssetIds: mediaAssetIds ?? this.mediaAssetIds,
  );

  Map<String, String> validate() {
    final errors = <String, String>{};
    if (name.trim().isEmpty || name.trim().length > 80) {
      errors['name'] = vi.app.projects.nhapTenDuAn;
    }
    if (tagline.trim().isEmpty || tagline.trim().length > 160) {
      errors['tagline'] = vi.app.projects.nhapMoTaNgan;
    }
    if (intro.trim().length < 30 || intro.trim().length > 10000) {
      errors['intro'] = vi.app.projects.gioiThieuCanTu;
    }
    if (!projectTypes.contains(type)) errors['type'] = vi.projects.canTheLoai;
    if (!projectRelations.contains(relation)) {
      errors['relation'] = vi.app.projects.chonVaiTroCua;
    }
    if (!noRepo && projectRepositoryUrl(repoUrl) == null) {
      errors['repo'] = vi.app.projects.nhapLienKetGithub;
    }
    final used = links.where((link) => link.url.trim().isNotEmpty).toList();
    if (used.length > 8 ||
        used.any(
          (link) =>
              !projectLinkKinds.contains(link.kind) ||
              link.url.trim().length > 500 ||
              !_validLink(link.url),
        )) {
      errors['links'] = vi.app.projects.kiemTraCacLien;
    }
    if (noRepo && used.isEmpty) {
      errors['links'] = vi.app.projects.themItNhatMot;
    }
    if (seekingNote.trim().length > 200) {
      errors['seekingNote'] = vi.app.projects.toiDa200Ky;
    }
    if (logoAssetId != null && !_uuidRegex.hasMatch(logoAssetId!)) {
      errors['logo'] = vi.app.projects.logoKhongHopLe;
    }
    if (mediaAssetIds.length > projectMaxMedia ||
        mediaAssetIds.any((id) => !_uuidRegex.hasMatch(id))) {
      errors['media'] = vi.app.projects.anhChupManHinh;
    }
    return errors;
  }

  Map<String, Object?> toJson() => {
    'name': name.trim(),
    'tagline': tagline.trim(),
    'intro': intro.trim(),
    'type': type,
    'relation': relation,
    'repoUrl': noRepo ? '' : projectRepositoryUrl(repoUrl),
    'links': [
      for (final link in links)
        if (link.url.trim().isNotEmpty)
          {'kind': link.kind, 'url': link.url.trim()},
    ],
    'logoAssetId': logoAssetId,
    'mediaAssetIds': mediaAssetIds,
    'seeking': seeking,
    'seekingNote': seeking ? seekingNote.trim() : '',
    'announce': announce,
  };
}

final class ProjectSubmissionDraft {
  const ProjectSubmissionDraft({
    this.name = '',
    this.tagline = '',
    this.intro = '',
    this.type = '',
    this.relation = '',
    this.repoUrl = '',
    this.noRepo = false,
    this.links = const [],
    this.seeking = false,
    this.seekingNote = '',
    this.announce = true,
    this.logoAssetId,
    this.logoFileName,
    this.mediaAssets = const [],
    this.uncertain = false,
  });

  final String name, tagline, intro, type, relation, repoUrl, seekingNote;
  final bool noRepo, seeking, announce;
  final List<ProjectSubmissionLink> links;
  final String? logoAssetId;
  final String? logoFileName;
  final List<({String assetId, String fileName})> mediaAssets;
  final bool uncertain;

  Map<String, Object?> toJson() => {
    'name': name,
    'tagline': tagline,
    'intro': intro,
    'type': type,
    'relation': relation,
    'repoUrl': repoUrl,
    'noRepo': noRepo,
    'links': [
      for (final l in links) {'kind': l.kind, 'url': l.url},
    ],
    'seeking': seeking,
    'seekingNote': seekingNote,
    'announce': announce,
    'logoAssetId': logoAssetId,
    'logoFileName': logoFileName,
    'mediaAssets': [
      for (final m in mediaAssets)
        {'assetId': m.assetId, 'fileName': m.fileName},
    ],
    'uncertain': uncertain,
  };

  static ProjectSubmissionDraft? fromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    try {
      final links = <ProjectSubmissionLink>[];
      final rawLinks = data['links'];
      if (rawLinks is List) {
        for (final item in rawLinks) {
          if (item is Map) {
            final k = item['kind'];
            final u = item['url'];
            if (k is String && u is String) {
              links.add(ProjectSubmissionLink(k, u));
            }
          }
        }
      }
      final mediaAssets = <({String assetId, String fileName})>[];
      final rawMedia = data['mediaAssets'];
      if (rawMedia is List) {
        for (final item in rawMedia) {
          if (item is Map) {
            final a = item['assetId'];
            final f = item['fileName'];
            if (a is String && f is String) {
              mediaAssets.add((assetId: a, fileName: f));
            }
          }
        }
      }
      return ProjectSubmissionDraft(
        name: data['name'] is String ? data['name'] as String : '',
        tagline: data['tagline'] is String ? data['tagline'] as String : '',
        intro: data['intro'] is String ? data['intro'] as String : '',
        type: data['type'] is String ? data['type'] as String : '',
        relation: data['relation'] is String ? data['relation'] as String : '',
        repoUrl: data['repoUrl'] is String ? data['repoUrl'] as String : '',
        noRepo: data['noRepo'] == true,
        links: links,
        seeking: data['seeking'] == true,
        seekingNote: data['seekingNote'] is String
            ? data['seekingNote'] as String
            : '',
        announce: data['announce'] != false,
        logoAssetId: data['logoAssetId'] is String
            ? data['logoAssetId'] as String
            : null,
        logoFileName: data['logoFileName'] is String
            ? data['logoFileName'] as String
            : null,
        mediaAssets: mediaAssets,
        uncertain: data['uncertain'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  ProjectSubmissionInput toInput() => ProjectSubmissionInput(
    name: name,
    tagline: tagline,
    intro: intro,
    type: type,
    relation: relation,
    repoUrl: repoUrl,
    noRepo: noRepo,
    links: links,
    seeking: seeking,
    seekingNote: seekingNote,
    announce: announce,
    logoAssetId: logoAssetId,
    mediaAssetIds: [for (final m in mediaAssets) m.assetId],
  );
}

abstract interface class ProjectSubmissionDraftStore {
  Future<ProjectSubmissionDraft?> read(String ownerId);
  Future<void> write(String ownerId, ProjectSubmissionDraft draft);
  Future<void> delete(String ownerId);
}

final class SessionStorageProjectSubmissionDraftStore
    implements ProjectSubmissionDraftStore {
  const SessionStorageProjectSubmissionDraftStore(this._storage);
  final SessionStorage _storage;

  String _key(String ownerId) =>
      'vnlf.project.submission.draft.${Uri.encodeComponent(ownerId)}';

  @override
  Future<ProjectSubmissionDraft?> read(String ownerId) async {
    if (ownerId.isEmpty) return null;
    final raw = await _storage.read(_key(ownerId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return ProjectSubmissionDraft.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String ownerId, ProjectSubmissionDraft draft) async {
    if (ownerId.isEmpty) return;
    await _storage.write(_key(ownerId), jsonEncode(draft.toJson()));
  }

  @override
  Future<void> delete(String ownerId) async {
    if (ownerId.isEmpty) return;
    await _storage.delete(_key(ownerId));
  }
}

final class ProjectSubmissionReceipt {
  const ProjectSubmissionReceipt(this.id, this.slug);
  final String id, slug;
}

final class ProjectRepositoryPreview {
  const ProjectRepositoryPreview({
    required this.url,
    required this.name,
    required this.stars,
    required this.forks,
    this.description,
    this.language,
    this.duplicateName,
  });
  final String url, name;
  final int stars, forks;
  final String? description, language, duplicateName;
}

abstract interface class ProjectSubmissionRepository {
  Future<ProjectSubmissionReceipt> create(ProjectSubmissionInput input);
  Future<ProjectRepositoryPreview> preview(String url);
  Future<PendingProjectMedia> presignMedia({
    required ProjectMediaFile file,
    bool logo = false,
  });
  Future<void> uploadMedia(PendingProjectMedia pending);
  Future<void> completeMedia(PendingProjectMedia pending);
}

final class LiveProjectSubmissionRepository
    implements ProjectSubmissionRepository {
  LiveProjectSubmissionRepository(
    this._client, {
    ProjectMediaTransfer? transfer,
  }) : _transfer = transfer ?? _uploadNative;

  final ApiClient _client;
  final ProjectMediaTransfer _transfer;

  static Future<void> _uploadNative(
    Uri url,
    ProjectMediaFile file,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.putUrl(url);
      request.bufferOutput = false;
      request.contentLength = file.length;
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value, preserveHeaderCase: true);
      }
      await request.addStream(file.openRead());
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpFailure(response.statusCode);
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<ProjectSubmissionReceipt> create(ProjectSubmissionInput input) {
    if (input.validate().isNotEmpty) throw const ParseFailure('project.input');
    return _client.request(
      'POST',
      '/api/v1/projects',
      body: jsonEncode(input.toJson()),
      decode: (json) {
        final id = json['id'];
        final slug = json['slug'];
        if (id is! String ||
            !_uuidRegex.hasMatch(id) ||
            slug is! String ||
            slug.isEmpty ||
            slug.length > 80 ||
            !RegExp(r'^[a-z0-9-]+$').hasMatch(slug) ||
            json['status'] != 'PENDING') {
          throw const ParseFailure('project.acknowledgement');
        }
        return ProjectSubmissionReceipt(id, slug);
      },
    );
  }

  @override
  Future<ProjectRepositoryPreview> preview(String url) {
    final normalized = projectRepositoryUrl(url);
    if (normalized == null) throw const ParseFailure('project.repo');
    return _client.request(
      'POST',
      '/api/v1/projects/repo-preview',
      body: jsonEncode({'url': normalized}),
      decode: (json) {
        final duplicate = json['duplicate'];
        if (json['provider'] != 'GITHUB' ||
            json['url'] is! String ||
            projectRepositoryUrl(json['url'] as String)?.toLowerCase() !=
                normalized.toLowerCase() ||
            json['name'] is! String ||
            json['stars'] is! int ||
            json['forks'] is! int ||
            (duplicate != null &&
                (duplicate is! Map || duplicate['name'] is! String))) {
          throw const ParseFailure('project.repoPreview');
        }
        return ProjectRepositoryPreview(
          url: normalized,
          name: json['name'] as String,
          stars: json['stars'] as int,
          forks: json['forks'] as int,
          description: json['description'] is String
              ? json['description'] as String
              : null,
          language: json['language'] is String
              ? json['language'] as String
              : null,
          duplicateName: duplicate is Map ? duplicate['name'] as String : null,
        );
      },
    );
  }

  @override
  Future<PendingProjectMedia> presignMedia({
    required ProjectMediaFile file,
    bool logo = false,
  }) async {
    if (file.name.isEmpty ||
        file.name.length > 200 ||
        !projectMediaMimes.contains(file.mime) ||
        file.length < 1 ||
        file.length > projectImageLimit) {
      throw const ParseFailure('project.upload.file');
    }
    final session = _client.captureSession();
    final body = <String, Object?>{
      'fileName': file.name,
      'mime': file.mime,
      'size': file.length,
      if (logo) 'logo': true,
    };
    final response = await _client.request<Map<String, dynamic>>(
      'POST',
      '/api/v1/project-images/presign',
      body: jsonEncode(body),
    );
    session.ensureCurrent();
    final assetId = response['assetId'];
    final rawUrl = response['uploadUrl'];
    final uploadUrl = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    final expiresIn = response['expiresIn'];
    final rawHeaders = response['headers'];
    if (assetId is! String ||
        !_uuidRegex.hasMatch(assetId) ||
        uploadUrl == null ||
        uploadUrl.scheme != 'https' ||
        uploadUrl.host.isEmpty ||
        uploadUrl.userInfo.isNotEmpty ||
        uploadUrl.hasFragment ||
        expiresIn is! int ||
        expiresIn <= 0 ||
        rawHeaders is! Map<String, dynamic>) {
      throw const ParseFailure('project.upload.presign');
    }
    final headers = <String, String>{};
    final headerNameRegex = RegExp(r"^[!#\$%&'*+.^_`|~0-9a-zA-Z-]+$");
    for (final entry in rawHeaders.entries) {
      final name = entry.key;
      final lower = name.toLowerCase();
      final value = entry.value;
      if (!headerNameRegex.hasMatch(name) ||
          value is! String ||
          value.contains('\r') ||
          value.contains('\n') ||
          lower == 'cookie' ||
          lower == 'authorization' ||
          lower == 'x-csrf-token' ||
          lower == 'host' ||
          lower == 'content-length') {
        throw const ParseFailure('project.upload.headers');
      }
      headers[name] = value;
    }
    return PendingProjectMedia(
      assetId: assetId,
      isLogo: logo,
      fileName: file.name,
      uploadUrl: uploadUrl,
      headers: Map.unmodifiable(headers),
      file: file,
      session: session,
      ownerToken: this,
    );
  }

  @override
  Future<void> uploadMedia(PendingProjectMedia pending) async {
    if (!identical(pending.ownerToken, this)) {
      throw const ParseFailure('project.upload.owner');
    }
    pending.session.ensureCurrent();
    final original = pending.file;
    final guarded = ProjectMediaFile(
      name: original.name,
      mime: original.mime,
      length: original.length,
      openRead: () => original.openRead().map((chunk) {
        pending.session.ensureCurrent();
        return chunk;
      }),
    );
    await _transfer(pending.uploadUrl, guarded, pending.headers);
    pending.session.ensureCurrent();
  }

  @override
  Future<void> completeMedia(PendingProjectMedia pending) async {
    if (!identical(pending.ownerToken, this)) {
      throw const ParseFailure('project.upload.owner');
    }
    pending.session.ensureCurrent();
    final response = await _client.request<Map<String, dynamic>>(
      'POST',
      '/api/v1/project-images/${Uri.encodeComponent(pending.assetId)}/complete',
    );
    pending.session.ensureCurrent();
    if (response['assetId'] != pending.assetId ||
        response['status'] != 'READY') {
      throw const ParseFailure('project.upload.complete');
    }
  }
}

final class ProjectSubmissionController extends ChangeNotifier {
  ProjectSubmissionController({
    required this.repository,
    required this.ownerId,
    required this.currentOwner,
    this.draftStore,
  });

  final ProjectSubmissionRepository repository;
  final String ownerId;
  final String? Function() currentOwner;
  final ProjectSubmissionDraftStore? draftStore;

  ProjectSubmissionInput input = const ProjectSubmissionInput();
  String? logoFileName;
  List<({String assetId, String fileName})> mediaAssets = [];
  bool busy = false;
  bool uploadingMedia = false;
  bool uncertain = false;
  bool draftRestored = false;
  String? error;
  ProjectSubmissionReceipt? receipt;
  bool _disposed = false;

  bool get isOwner => currentOwner() == ownerId;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> init() async {
    if (draftStore == null || !isOwner) return;
    final saved = await draftStore!.read(ownerId);
    if (!isOwner || _disposed || saved == null) return;
    input = saved.toInput();
    logoFileName = saved.logoFileName;
    mediaAssets = List.of(saved.mediaAssets);
    uncertain = saved.uncertain;
    draftRestored = true;
    _notify();
  }

  Future<void> persistDraft() async {
    if (draftStore == null || !isOwner || receipt != null) return;
    final draft = ProjectSubmissionDraft(
      name: input.name,
      tagline: input.tagline,
      intro: input.intro,
      type: input.type,
      relation: input.relation,
      repoUrl: input.repoUrl,
      noRepo: input.noRepo,
      links: input.links,
      seeking: input.seeking,
      seekingNote: input.seekingNote,
      announce: input.announce,
      logoAssetId: input.logoAssetId,
      logoFileName: logoFileName,
      mediaAssets: mediaAssets,
      uncertain: uncertain,
    );
    await draftStore!.write(ownerId, draft);
  }

  Future<void> uploadLogo(ProjectMediaFile file) async {
    if (busy || uploadingMedia || !isOwner || uncertain || receipt != null) {
      return;
    }
    uploadingMedia = true;
    error = null;
    _notify();
    try {
      final pending = await repository.presignMedia(file: file, logo: true);
      if (!isOwner) throw StateError('account changed');
      await repository.uploadMedia(pending);
      if (!isOwner) throw StateError('account changed');
      await repository.completeMedia(pending);
      if (!isOwner) throw StateError('account changed');
      input = input.copyWith(logoAssetId: pending.assetId);
      logoFileName = file.name;
      await persistDraft();
    } on HttpFailure catch (e) {
      error = format(vi.app.projects.khongTheTaiLogo, {
        'statusCode': e.statusCode,
      });
    } catch (_) {
      error = vi.app.projects.taiLogoKhongThanh;
    } finally {
      uploadingMedia = false;
      _notify();
    }
  }

  Future<void> removeLogo() async {
    if (busy || uploadingMedia || !isOwner || uncertain || receipt != null) {
      return;
    }
    input = input.copyWith(clearLogo: true);
    logoFileName = null;
    await persistDraft();
    _notify();
  }

  Future<void> uploadScreenshot(ProjectMediaFile file) async {
    if (busy || uploadingMedia || !isOwner || uncertain || receipt != null) {
      return;
    }
    if (mediaAssets.length >= projectMaxMedia) {
      error = vi.app.projects.toiDa6Anh;
      _notify();
      return;
    }
    uploadingMedia = true;
    error = null;
    _notify();
    try {
      final pending = await repository.presignMedia(file: file, logo: false);
      if (!isOwner) throw StateError('account changed');
      await repository.uploadMedia(pending);
      if (!isOwner) throw StateError('account changed');
      await repository.completeMedia(pending);
      if (!isOwner) throw StateError('account changed');
      mediaAssets.add((assetId: pending.assetId, fileName: file.name));
      input = input.copyWith(
        mediaAssetIds: [for (final m in mediaAssets) m.assetId],
      );
      await persistDraft();
    } on HttpFailure catch (e) {
      error = format(vi.app.projects.khongTheTaiAnh, {
        'statusCode': e.statusCode,
      });
    } catch (_) {
      error = vi.app.projects.taiAnhKhongThanh;
    } finally {
      uploadingMedia = false;
      _notify();
    }
  }

  Future<void> removeScreenshot(int index) async {
    if (busy || uploadingMedia || !isOwner || uncertain || receipt != null) {
      return;
    }
    if (index >= 0 && index < mediaAssets.length) {
      mediaAssets.removeAt(index);
      input = input.copyWith(
        mediaAssetIds: [for (final m in mediaAssets) m.assetId],
      );
      await persistDraft();
      _notify();
    }
  }

  Future<void> submit() async {
    if (busy || uploadingMedia || uncertain || receipt != null || !isOwner) {
      return;
    }
    final problems = input.validate();
    if (problems.isNotEmpty) {
      error = problems.values.first;
      _notify();
      return;
    }
    busy = true;
    error = null;
    _notify();
    try {
      final result = await repository.create(input);
      if (!isOwner) {
        uncertain = true;
        await persistDraft();
      } else {
        receipt = result;
        if (draftStore != null) {
          try {
            await draftStore!.delete(ownerId);
          } catch (_) {}
        }
      }
    } on HttpFailure catch (failure) {
      if (isOwner &&
          failure.statusCode >= 400 &&
          failure.statusCode < 500 &&
          failure.statusCode != 401 &&
          failure.statusCode != 408 &&
          failure.statusCode != 429) {
        error = format(vi.app.projects.mayChuTuChoi, {
          'statusCode': failure.statusCode,
        });
      } else {
        uncertain = true;
        await persistDraft();
      }
    } catch (_) {
      uncertain = true;
      await persistDraft();
    } finally {
      busy = false;
      _notify();
    }
  }
}
