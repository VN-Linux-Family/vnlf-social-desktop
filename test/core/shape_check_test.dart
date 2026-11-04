import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(
    () async => directory = await Directory.systemTemp.createTemp('shape_'),
  );
  tearDown(() async => directory.delete(recursive: true));

  test('prints paths and types without JSON values', () async {
    final file = File('${directory.path}/input.json');
    await file.writeAsString(
      '{"items":[{"name":"secret", "count":3},{"name":null}], "active":true}',
    );
    final result = await Process.run('dart', [
      'run',
      'tool/shape_check.dart',
      file.path,
    ]);
    expect(result.exitCode, 0);
    expect(result.stdout, r'''$.active: boolean
$.items: array
$.items[]: object
$.items[].count: number
$.items[].name: null | string
''');
    expect(result.stdout, isNot(contains('secret')));
  });

  test('diff reports missing paths and changed types without values', () async {
    final input = File('${directory.path}/input.json');
    final fixture = File('${directory.path}/fixture.json');
    await input.writeAsString('{"id":1,"new":false}');
    await fixture.writeAsString('{"id":"private","old":null}');
    final result = await Process.run('dart', [
      'run',
      'tool/shape_check.dart',
      '--diff',
      input.path,
      fixture.path,
    ]);
    expect(result.exitCode, 1);
    expect(result.stdout, r'''~ $.id: string -> number
+ $.new: boolean
- $.old: null
''');
    expect(result.stdout, isNot(contains('private')));
  });
}
