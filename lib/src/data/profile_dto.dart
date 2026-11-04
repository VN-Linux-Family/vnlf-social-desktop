import '../domain/models.dart';

/// The public author projection observed inside feed posts, not a profile API.
final class ProfileDto {
  const ProfileDto({required this.username, required this.displayName});

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    String read(String field) {
      final value = json[field];
      if (value == null) return '';
      if (value is! String) throw ParseFailure('author.$field');
      return value;
    }

    final username = read('username');
    final displayName = read('displayName');
    return ProfileDto(
      username: username,
      displayName: displayName.isEmpty ? username : displayName,
    );
  }

  final String username;
  final String displayName;
  Author toDomain() => Author(username: username, displayName: displayName);
}
