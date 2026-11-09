#!/usr/bin/env python3
"""Regenerate the website part of lib/src/i18n/vi.dart from the website's vi.ts.

The website keeps every user-facing string in one object, `vi`, in
packages/i18n/src/vi.ts. The app keeps the same keys in one Dart file, so
`vi.pageLogin.dangNhapVnlfSocial` reads the same in both code bases. Only the
regions between the GENERATED markers are rewritten; the native-only `ViApp`
section is edited by hand and kept as is.

Objects become Dart classes, except lookup tables, which become
`Map<String, String>`: objects the website declares on one line or casts
`as Record`, objects whose keys are not Dart names, and objects the website's
code indexes with `vi.path[key]`. Arrays become lists of strings or of
string pairs.

Usage: python3 tool/sync_vi_strings.py [--web ../vnlf-social] [--node node]
Requires Node 22.6+ (type stripping) or Bun to read vi.ts.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shutil
import subprocess

BEGIN = '// BEGIN GENERATED: python3 tool/sync_vi_strings.py'
END = '// END GENERATED'
VI_TS = 'packages/i18n/src/vi.ts'

DART_RESERVED = {
    'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case',
    'catch', 'class', 'const', 'continue', 'covariant', 'default', 'deferred',
    'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension',
    'external', 'factory', 'false', 'final', 'finally', 'for', 'Function',
    'get', 'hide', 'if', 'implements', 'import', 'in', 'interface', 'is',
    'late', 'library', 'mixin', 'new', 'null', 'of', 'on', 'operator', 'part',
    'required', 'rethrow', 'return', 'sealed', 'set', 'show', 'static',
    'super', 'switch', 'sync', 'this', 'throw', 'true', 'try', 'type',
    'typedef', 'var', 'void', 'when', 'while', 'with', 'yield',
    # Object members a field must not shadow.
    'hashCode', 'runtimeType', 'toString', 'noSuchMethod',
}
_DART_NAME = re.compile(r'^[a-z][A-Za-z0-9]*$')
_OPEN = re.compile(r'^("?)([\w-]+)\1: \{(.*)$')
_INDEXED = re.compile(r'\bvi((?:\.\w+)+)\[')


def load_vi(web: pathlib.Path, runtime: str) -> dict:
    """Evaluates vi.ts, keeping key order, with Node or Bun."""
    module = (web / VI_TS).resolve().as_uri()
    script = (f"import {{ vi }} from '{module}'; "
              "process.stdout.write(JSON.stringify(vi));")
    if pathlib.Path(runtime).name.startswith('bun'):
        command = [runtime, '-e', script]
    else:
        command = [runtime, '--input-type=module', '-e', script]
    result = subprocess.run(command, check=True, capture_output=True,
                            text=True)
    return json.loads(result.stdout)


def declared_tables(source: str) -> set[tuple[str, ...]]:
    """Objects written on one line or cast `as Record` in vi.ts."""
    tables = set()
    stack: list[str] = []
    for raw in source.splitlines():
        line = raw.strip()
        if line.startswith('export const vi = {'):
            stack = []
            continue
        if match := _OPEN.match(line):
            key, rest = match[2], match[3]
            if rest.strip().startswith('}') or '}' in rest:
                tables.add(tuple(stack + [key]))
            else:
                stack.append(key)
        elif line.startswith('}') and stack:
            if 'as Record' in line:
                tables.add(tuple(stack))
            stack.pop()
    return tables


def indexed_tables(web: pathlib.Path) -> set[tuple[str, ...]]:
    """Objects the website's code reads with `vi.path[key]`."""
    tables = set()
    for root in ('apps', 'packages'):
        for path in (web / root).rglob('*'):
            if path.suffix not in {'.ts', '.tsx'} or 'node_modules' in path.parts:
                continue
            if path.as_posix().endswith(VI_TS):
                continue
            for match in _INDEXED.finditer(path.read_text(encoding='utf-8')):
                tables.add(tuple(match[1].strip('.').split('.')))
    return tables


def dart_string(value: str) -> str:
    escaped = []
    for char in value:
        if char == '\\':
            escaped.append('\\\\')
        elif char == "'":
            escaped.append("\\'")
        elif char == '$':
            escaped.append('\\$')
        elif char == '\n':
            escaped.append('\\n')
        elif char == '\t':
            escaped.append('\\t')
        elif char == '\r':
            escaped.append('\\r')
        elif ord(char) < 0x20:
            escaped.append(f'\\u{{{ord(char):x}}}')
        else:
            escaped.append(char)
    return "'" + ''.join(escaped) + "'"


def class_name(path: list[str]) -> str:
    return 'Vi' + ''.join(part[0].upper() + part[1:] for part in path)


def _is_name(key: str) -> bool:
    return bool(_DART_NAME.match(key)) and key not in DART_RESERVED


def _value(path: list[str], value, tables: set[tuple[str, ...]]) -> str:
    where = '.'.join(path)
    if isinstance(value, str):
        return dart_string(value)
    if isinstance(value, list):
        if all(isinstance(item, str) for item in value):
            return ('const <String>['
                    + ', '.join(dart_string(item) for item in value) + ']')
        if all(isinstance(item, list) and len(item) == 2
               and all(isinstance(part, str) for part in item)
               for item in value):
            pairs = ', '.join(f'({dart_string(a)}, {dart_string(b)})'
                              for a, b in value)
            return f'const <(String, String)>[{pairs}]'
        raise ValueError(f'{where}: unsupported array')
    if isinstance(value, dict):
        if all(isinstance(item, str) for item in value.values()):
            return 'const <String, String>' + _table(value)
        if all(isinstance(item, dict)
               and all(isinstance(text, str) for text in item.values())
               for item in value.values()):
            # e.g. vi.wardrobe.mon[slot][item]
            entries = ', '.join(f'{dart_string(key)}: {_table(item)}'
                                for key, item in value.items())
            return f'const <String, Map<String, String>>{{{entries}}}'
        raise ValueError(f'{where}: unsupported lookup table')
    raise ValueError(f'{where}: unsupported value {value!r}')


def _table(value: dict) -> str:
    return '{' + ', '.join(f'{dart_string(key)}: {dart_string(item)}'
                           for key, item in value.items()) + '}'


def emit(tree: dict, tables: set[tuple[str, ...]]) -> tuple[str, str]:
    """Returns the generated root fields and the generated classes."""
    names: dict[str, list[str]] = {}
    classes: list[str] = []

    def is_namespace(path: list[str], value) -> bool:
        return (isinstance(value, dict) and tuple(path) not in tables
                and all(_is_name(key) for key in value))

    def visit(path: list[str], node: dict) -> None:
        name = class_name(path)
        if name in names:
            raise ValueError(f'class {name} is used by both '
                             f'{".".join(names[name])} and {".".join(path)}')
        names[name] = path
        body = [f'final class {name} {{', f'  const {name}._();']
        nested = []
        for key, value in node.items():
            child = path + [key]
            if is_namespace(child, value):
                body.append(f'  final {key} = const {class_name(child)}._();')
                nested.append((child, value))
            else:
                body.append(f'  final {key} = {_value(child, value, tables)};')
        body.append('}')
        classes.append('\n'.join(body))
        for child, value in nested:
            visit(child, value)

    fields = []
    for key, value in tree.items():
        if not is_namespace([key], value):
            raise ValueError(f'top-level {key} must be a namespace object')
        fields.append(f'  final {key} = const {class_name([key])}._();')
        visit([key], value)
    return '\n'.join(fields), '\n\n'.join(classes)


def replace_regions(dart: str, fields: str, classes: str) -> str:
    parts = dart.split(BEGIN)
    if len(parts) != 3 or any(END not in part for part in parts[1:]):
        raise ValueError(f'{BEGIN!r} must open exactly two regions')
    rebuilt = parts[0]
    for part, content in zip(parts[1:], (fields, classes)):
        rebuilt += f'{BEGIN}\n{content}\n{END}{part.split(END, 1)[1]}'
    return rebuilt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--web', default='../vnlf-social',
                        help='checkout of the website repository')
    parser.add_argument('--node', default=shutil.which('node')
                        or shutil.which('bun') or 'node',
                        help='Node 22.6+ or Bun executable')
    parser.add_argument('--out', default='lib/src/i18n/vi.dart')
    args = parser.parse_args()
    web = pathlib.Path(args.web)
    tree = load_vi(web, args.node)
    tables = declared_tables((web / VI_TS).read_text(encoding='utf-8'))
    tables |= indexed_tables(web)
    fields, classes = emit(tree, tables)
    out = pathlib.Path(args.out)
    out.write_text(replace_regions(out.read_text(encoding='utf-8'), fields,
                                   classes), encoding='utf-8')
    if dart := shutil.which('dart'):
        subprocess.run([dart, 'format', str(out)], check=True,
                       stdout=subprocess.DEVNULL)
    else:
        print(f'Run `dart format {out}`; dart is not on PATH.')


if __name__ == '__main__':
    main()
