import '../domain/models.dart';
import 'field_reader.dart';

/// The public author projection observed inside feed posts, not a profile API.
final class ProfileDto {
  const ProfileDto({
    required this.username,
    required this.displayName,
    this.id = '',
    this.avatarUrl = '',
    this.role = '',
    this.style,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final username = stringValue(json['username'], 'author.username');
    final displayName = stringValue(json['displayName'], 'author.displayName');
    return ProfileDto(
      id: stringValue(json['id'], 'author.id'),
      username: username,
      displayName: displayName.isEmpty ? username : displayName,
      avatarUrl: stringValue(json['avatarUrl'], 'author.avatarUrl'),
      role: stringValue(json['role'], 'author.role'),
      style: styleValue(json['style'], 'author.style'),
    );
  }
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String role;
  final AuthorStyle? style;
  Author toDomain() => Author(
    id: id,
    username: username,
    displayName: displayName,
    avatarUrl: avatarUrl,
    role: role,
    style: style,
  );
}
