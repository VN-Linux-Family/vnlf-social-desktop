import 'dart:convert';
import 'dart:io';

Map<String, Set<String>> shape(Object? root) {
  final paths = <String, Set<String>>{};
  void visit(Object? value, String path, {bool include = true}) {
    final type = switch (value) {
      null => 'null',
      bool _ => 'boolean',
      num _ => 'number',
      String _ => 'string',
      List<Object?> _ => 'array',
      Map<Object?, Object?> _ => 'object',
      _ => throw const FormatException('Unsupported JSON type'),
    };
    if (include) paths.putIfAbsent(path, () => <String>{}).add(type);
    if (value is Map<String, dynamic>) {
      for (final entry in value.entries) {
        final key = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(entry.key)
            ? '.${entry.key}'
            : '[${jsonEncode(entry.key)}]';
        visit(entry.value, '$path$key');
      }
    } else if (value is List) {
      for (final item in value) {
        visit(item, '$path[]');
      }
    }
  }

  visit(root, r'$', include: root is! Map);
  return paths;
}

String types(Set<String> values) => (values.toList()..sort()).join(' | ');

Future<void> main(List<String> args) async {
  final diff = args.length == 3 && args.first == '--diff';
  if (!(args.length == 1 || diff)) {
    stderr.writeln(
      'Usage: dart run tool/shape_check.dart [--diff] INPUT [FIXTURE]',
    );
    exitCode = 64;
    return;
  }
  try {
    final input = shape(
      jsonDecode(await File(args[diff ? 1 : 0]).readAsString()),
    );
    if (!diff) {
      for (final path in input.keys.toList()..sort()) {
        stdout.writeln('$path: ${types(input[path]!)}');
      }
      return;
    }
    final fixture = shape(jsonDecode(await File(args[2]).readAsString()));
    final paths = {...input.keys, ...fixture.keys}.toList()..sort();
    var changed = false;
    for (final path in paths) {
      final before = fixture[path];
      final after = input[path];
      if (before == null) {
        stdout.writeln('+ $path: ${types(after!)}');
      } else if (after == null) {
        stdout.writeln('- $path: ${types(before)}');
      } else if (types(before) != types(after)) {
        stdout.writeln('~ $path: ${types(before)} -> ${types(after)}');
      } else {
        continue;
      }
      changed = true;
    }
    if (changed) exitCode = 1;
  } on Object {
    stderr.writeln('Unable to read or parse JSON input');
    exitCode = 2;
  }
}
