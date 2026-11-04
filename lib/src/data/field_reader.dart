import '../domain/models.dart';

String? nullableString(Object? value, String field) {
  if (value == null) return null;
  if (value is! String) throw ParseFailure(field);
  return value;
}

String stringValue(Object? value, String field) =>
    nullableString(value, field) ?? '';
int? nullableInt(Object? value, String field) {
  if (value == null) return null;
  if (value is! int) throw ParseFailure(field);
  return value;
}

int intValue(Object? value, String field) => nullableInt(value, field) ?? 0;
bool boolValue(Object? value, String field) {
  if (value == null) return false;
  if (value is! bool) throw ParseFailure(field);
  return value;
}

DateTime? dateValue(Object? value, String field) {
  final source = nullableString(value, field);
  if (source == null) return null;
  final date = DateTime.tryParse(source);
  if (date == null) throw ParseFailure(field);
  return date;
}

Object? _freeze(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.unmodifiable(
      value.map((key, item) => MapEntry(key, _freeze(item))),
    );
  }
  if (value is List) return List<Object?>.unmodifiable(value.map(_freeze));
  return value;
}

Map<String, dynamic>? objectValue(Object? value, String field) {
  if (value == null) return null;
  if (value is! Map<String, dynamic>) throw ParseFailure(field);
  return _freeze(value) as Map<String, dynamic>;
}

List<String> stringList(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List || value.any((item) => item is! String)) {
    throw ParseFailure(field);
  }
  return List<String>.unmodifiable(value.cast<String>());
}

List<Map<String, dynamic>> objectList(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) throw ParseFailure(field);
  return value
      .map((item) => objectValue(item, field) ?? (throw ParseFailure(field)))
      .toList(growable: false);
}

AuthorStyle? styleValue(Object? value, String field) {
  final style = objectValue(value, field);
  if (style == null) return null;
  return AuthorStyle(
    frame: objectValue(style['frame'], '$field.frame'),
    icon: objectValue(style['icon'], '$field.icon'),
    distroBadge: nullableString(style['distroBadge'], '$field.distroBadge'),
    nameplate: objectValue(style['nameplate'], '$field.nameplate'),
    status: objectValue(style['status'], '$field.status'),
  );
}
