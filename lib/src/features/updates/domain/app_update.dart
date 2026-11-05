final class ReleaseVersion implements Comparable<ReleaseVersion> {
  ReleaseVersion._(this.numbers, this.prerelease);
  factory ReleaseVersion.parse(String value) {
    final match = RegExp(
      r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
    ).firstMatch(value);
    if (match == null) throw const FormatException('Invalid release version');
    final prerelease = match[4]?.split('.') ?? <String>[];
    if (prerelease.any(
      (part) => part.isEmpty || RegExp(r'^0\d+$').hasMatch(part),
    )) {
      throw const FormatException('Invalid prerelease identifier');
    }
    return ReleaseVersion._([
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    ], prerelease);
  }
  final List<int> numbers;
  final List<String> prerelease;
  @override
  int compareTo(ReleaseVersion other) {
    for (var i = 0; i < 3; i++) {
      final result = numbers[i].compareTo(other.numbers[i]);
      if (result != 0) return result;
    }
    if (prerelease.isEmpty || other.prerelease.isEmpty) {
      return prerelease.isEmpty ? (other.prerelease.isEmpty ? 0 : 1) : -1;
    }
    for (var i = 0; i < prerelease.length && i < other.prerelease.length; i++) {
      final a = prerelease[i], b = other.prerelease[i];
      final numericA = int.tryParse(a), numericB = int.tryParse(b);
      final result = numericA != null && numericB != null
          ? numericA.compareTo(numericB)
          : numericA != null
          ? -1
          : numericB != null
          ? 1
          : a.compareTo(b);
      if (result != 0) return result;
    }
    return prerelease.length.compareTo(other.prerelease.length);
  }
}

final class UpdatePlatform {
  const UpdatePlatform(this.os, this.arch, this.extension);
  final String os;
  final String arch;
  final String extension;
}

final class UpdateAsset {
  const UpdateAsset(this.name, this.url);
  final String name;
  final Uri url;
}

sealed class AppUpdate {
  const AppUpdate();
}

final class UpdateCurrent extends AppUpdate {
  const UpdateCurrent();
}

final class UpdateUnavailable extends AppUpdate {
  const UpdateUnavailable();
}

final class UpdateAvailable extends AppUpdate {
  const UpdateAvailable({
    required this.version,
    required this.releasePage,
    this.asset,
  });
  final String version;
  final Uri releasePage;
  final UpdateAsset? asset;
}

final class UpdateFailure implements Exception {
  const UpdateFailure([this.statusCode]);
  final int? statusCode;
}

abstract interface class UpdateRepository {
  Future<AppUpdate> check(String currentVersion, UpdatePlatform platform);
}
