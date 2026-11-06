import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';

const projectTypes = <String>['APP', 'TOOL', 'LIBRARY', 'DISTRO', 'CUSTOMIZE', 'EXTENSION', 'VIETNAMESE', 'SYSTEM', 'SELFHOST', 'GAME', 'LEARNING', 'OTHER'];
const projectRelations = <String>['AUTHOR', 'MAINTAINER', 'CONTRIBUTOR', 'SHARED'];
const projectLinkKinds = <String>['WEBSITE', 'DOCS', 'DOWNLOAD', 'AUR', 'FLATHUB', 'CHAT', 'VIDEO', 'REPO', 'OTHER'];

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
  final ssh = RegExp(r'^(?:ssh://)?git@github\.com[:/]([^/\s]+)/([^/\s]+?)/?$', caseSensitive: false).firstMatch(value);
  if (ssh != null) {
    owner = ssh[1];
    name = ssh[2];
  } else {
    final uri = Uri.tryParse(RegExp(r'^[a-z][a-z\d+.-]*://', caseSensitive: false).hasMatch(value) ? value : 'https://$value');
    if (uri == null || !{'http', 'https'}.contains(uri.scheme) || !{'github.com', 'www.github.com'}.contains(uri.host.toLowerCase()) || uri.userInfo.isNotEmpty || uri.hasPort) return null;
    final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (parts.length < 2) return null;
    owner = parts[0];
    name = parts[1];
  }
  name = name?.replaceFirst(RegExp(r'\.git$', caseSensitive: false), '');
  const pages = {'about', 'account', 'apps', 'codespaces', 'collections', 'contact', 'customer-stories', 'dashboard', 'enterprise', 'events', 'explore', 'features', 'issues', 'join', 'login', 'logout', 'marketplace', 'new', 'notifications', 'orgs', 'organizations', 'pricing', 'pulls', 'readme', 'search', 'security', 'settings', 'site', 'sponsors', 'team', 'topics', 'trending', 'users'};
  if (owner == null || name == null || pages.contains(owner.toLowerCase()) || !RegExp(r'^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$', caseSensitive: false).hasMatch(owner) || !RegExp(r'^[\w.-]{1,100}$').hasMatch(name) || name == '.' || name == '..') return null;
  return 'https://github.com/$owner/$name';
}

bool _validLink(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && {'http', 'https'}.contains(uri.scheme) && uri.userInfo.isEmpty && uri.host.contains('.');
}

final class ProjectSubmissionInput {
  const ProjectSubmissionInput({this.name = '', this.tagline = '', this.intro = '', this.type = '', this.relation = '', this.repoUrl = '', this.noRepo = false, this.links = const [], this.seeking = false, this.seekingNote = '', this.announce = true});
  final String name, tagline, intro, type, relation, repoUrl, seekingNote;
  final bool noRepo, seeking, announce;
  final List<ProjectSubmissionLink> links;

  Map<String, String> validate() {
    final errors = <String, String>{};
    if (name.trim().isEmpty || name.trim().length > 80) errors['name'] = 'Nhập tên dự án (tối đa 80 ký tự).';
    if (tagline.trim().isEmpty || tagline.trim().length > 160) errors['tagline'] = 'Nhập mô tả ngắn (tối đa 160 ký tự).';
    if (intro.trim().length < 30 || intro.trim().length > 10000) errors['intro'] = 'Giới thiệu cần từ 30 đến 10.000 ký tự.';
    if (!projectTypes.contains(type)) errors['type'] = 'Chọn thể loại.';
    if (!projectRelations.contains(relation)) errors['relation'] = 'Chọn vai trò của bạn.';
    if (!noRepo && projectRepositoryUrl(repoUrl) == null) errors['repo'] = 'Nhập liên kết GitHub hợp lệ hoặc chọn không có kho mã.';
    final used = links.where((link) => link.url.trim().isNotEmpty).toList();
    if (used.length > 8 || used.any((link) => !projectLinkKinds.contains(link.kind) || link.url.trim().length > 500 || !_validLink(link.url))) errors['links'] = 'Kiểm tra các liên kết (tối đa 8 liên kết HTTP hoặc HTTPS).';
    if (noRepo && used.isEmpty) errors['links'] = 'Thêm ít nhất một liên kết khi không có kho mã.';
    if (seekingNote.trim().length > 200) errors['seekingNote'] = 'Tối đa 200 ký tự.';
    return errors;
  }

  Map<String, Object?> toJson() => {
    'name': name.trim(), 'tagline': tagline.trim(), 'intro': intro.trim(), 'type': type, 'relation': relation,
    'repoUrl': noRepo ? '' : projectRepositoryUrl(repoUrl),
    'links': [for (final link in links) if (link.url.trim().isNotEmpty) {'kind': link.kind, 'url': link.url.trim()}],
    'logoAssetId': null, 'mediaAssetIds': <String>[], 'seeking': seeking,
    'seekingNote': seeking ? seekingNote.trim() : '', 'announce': announce,
  };
}

final class ProjectSubmissionReceipt {
  const ProjectSubmissionReceipt(this.id, this.slug);
  final String id, slug;
}

final class ProjectRepositoryPreview {
  const ProjectRepositoryPreview({required this.url, required this.name, required this.stars, required this.forks, this.description, this.language, this.duplicateName});
  final String url, name;
  final int stars, forks;
  final String? description, language, duplicateName;
}

abstract interface class ProjectSubmissionRepository {
  Future<ProjectSubmissionReceipt> create(ProjectSubmissionInput input);
  Future<ProjectRepositoryPreview> preview(String url);
}

final class LiveProjectSubmissionRepository implements ProjectSubmissionRepository {
  const LiveProjectSubmissionRepository(this._client);
  final ApiClient _client;
  @override
  Future<ProjectSubmissionReceipt> create(ProjectSubmissionInput input) {
    if (input.validate().isNotEmpty) throw const ParseFailure('project.input');
    return _client.request('POST', '/api/v1/projects', body: jsonEncode(input.toJson()), decode: (json) {
      final id = json['id'];
      final slug = json['slug'];
      if (id is! String || !RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id) || slug is! String || slug.isEmpty || slug.length > 80 || !RegExp(r'^[a-z0-9-]+$').hasMatch(slug) || json['status'] != 'PENDING') throw const ParseFailure('project.acknowledgement');
      return ProjectSubmissionReceipt(id, slug);
    });
  }
  @override
  Future<ProjectRepositoryPreview> preview(String url) {
    final normalized = projectRepositoryUrl(url);
    if (normalized == null) throw const ParseFailure('project.repo');
    return _client.request('POST', '/api/v1/projects/repo-preview', body: jsonEncode({'url': normalized}), decode: (json) {
      final duplicate = json['duplicate'];
      if (json['provider'] != 'GITHUB' || json['url'] is! String || projectRepositoryUrl(json['url'] as String)?.toLowerCase() != normalized.toLowerCase() || json['name'] is! String || json['stars'] is! int || json['forks'] is! int || (duplicate != null && (duplicate is! Map || duplicate['name'] is! String))) throw const ParseFailure('project.repoPreview');
      return ProjectRepositoryPreview(url: normalized, name: json['name'] as String, stars: json['stars'] as int, forks: json['forks'] as int, description: json['description'] is String ? json['description'] as String : null, language: json['language'] is String ? json['language'] as String : null, duplicateName: duplicate is Map ? duplicate['name'] as String : null);
    });
  }
}

final class ProjectSubmissionController extends ChangeNotifier {
  ProjectSubmissionController({required this.repository, required this.ownerId, required this.currentOwner});
  final ProjectSubmissionRepository repository;
  final String ownerId;
  final String? Function() currentOwner;
  ProjectSubmissionInput input = const ProjectSubmissionInput();
  bool busy = false, uncertain = false;
  bool _disposed = false;
  @override
  void dispose() { _disposed = true; super.dispose(); }
  void _notify() { if (!_disposed) notifyListeners(); }
  String? error;
  ProjectSubmissionReceipt? receipt;
  bool get isOwner => currentOwner() == ownerId;
  Future<void> submit() async {
    if (busy || uncertain || receipt != null || !isOwner) return;
    final problems = input.validate();
    if (problems.isNotEmpty) { error = problems.values.first; _notify(); return; }
    busy = true; error = null; _notify();
    try {
      final result = await repository.create(input);
      if (!isOwner) { uncertain = true; } else { receipt = result; }
    } on HttpFailure catch (failure) {
      if (isOwner && failure.statusCode >= 400 && failure.statusCode < 500 && failure.statusCode != 401 && failure.statusCode != 408 && failure.statusCode != 429) {
        error = 'Máy chủ từ chối yêu cầu (${failure.statusCode}). Dữ liệu vẫn được giữ lại.';
      } else { uncertain = true; }
    } catch (_) { uncertain = true; }
    busy = false; _notify();
  }
}
