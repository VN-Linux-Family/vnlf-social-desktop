import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    'sync_vi_strings', Path(__file__).parents[2] / 'tool/sync_vi_strings.py')
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)

SOURCE = '''// Toàn bộ chữ hiển thị.
export const vi = {
  common: {
    dangNhap: "Đăng nhập",
    loai: { APP: "Ứng dụng", TOOL: "Công cụ" } as Record<string, string>,
    nhom: {
      smile: "Mặt cười",
    } as Record<string, string>,
    hoSo: {
      xem: "Xem {name}",
    },
  },
} as const;
'''


class DeclaredTablesTest(unittest.TestCase):
    def test_finds_one_line_and_cast_objects(self):
        self.assertEqual(sync.declared_tables(SOURCE),
                         {('common', 'loai'), ('common', 'nhom')})


class EmitTest(unittest.TestCase):
    def test_namespaces_tables_and_lists(self):
        tree = {'common': {
            'dangNhap': "Đăng nhập",
            'loai': {'APP': 'Ứng dụng'},
            'sapXep': {'new': 'Mới', 'stars': 'Nhiều star'},
            'hoSo': {'xem': "Xem {name}"},
            'tranh': ['Spam', 'Link hỏng'],
            'cacBuoc': [['Cơ bản', 'Thông tin chính']],
            'mon': {'pet': {'tux': 'Tux'}},
        }}
        fields, classes = sync.emit(tree, {('common', 'loai'), ('common', 'mon')})

        self.assertEqual(fields, '  final common = const ViCommon._();')
        self.assertIn("  final dangNhap = 'Đăng nhập';", classes)
        self.assertIn("  final loai = const <String, String>{'APP': 'Ứng dụng'};",
                      classes)
        # `new` is a Dart keyword, so the object can only be a table.
        self.assertIn("final sapXep = const <String, String>{'new': 'Mới'",
                      classes)
        self.assertIn('  final hoSo = const ViCommonHoSo._();', classes)
        self.assertIn('final class ViCommonHoSo {', classes)
        self.assertIn("final tranh = const <String>['Spam', 'Link hỏng'];",
                      classes)
        self.assertIn("const <(String, String)>[('Cơ bản', 'Thông tin chính')]",
                      classes)
        self.assertIn("const <String, Map<String, String>>{'pet': {'tux': 'Tux'}}",
                      classes)

    def test_escapes_dart_string_syntax(self):
        self.assertEqual(sync.dart_string("It's $5\n\\"), "'It\\'s \\$5\\n\\\\'")

    def test_rejects_ambiguous_class_names(self):
        # aB.c and aBC would both become class ViABC.
        with self.assertRaises(ValueError):
            sync.emit({'aB': {'c': {'x': '1'}}, 'aBC': {'y': '2'}}, set())

    def test_rejects_unsupported_values(self):
        with self.assertRaises(ValueError):
            sync.emit({'common': {'count': 3}}, set())


class ReplaceRegionsTest(unittest.TestCase):
    def test_keeps_hand_written_code(self):
        dart = ('head\n' + sync.BEGIN + '\nold fields\n' + sync.END + '\nmiddle\n'
                + sync.BEGIN + '\nold classes\n' + sync.END + '\ntail\n')

        result = sync.replace_regions(dart, 'new fields', 'new classes')

        self.assertEqual(result, 'head\n' + sync.BEGIN + '\nnew fields\n'
                         + sync.END + '\nmiddle\n' + sync.BEGIN
                         + '\nnew classes\n' + sync.END + '\ntail\n')

    def test_requires_both_regions(self):
        with self.assertRaises(ValueError):
            sync.replace_regions('no markers', 'a', 'b')


if __name__ == '__main__':
    unittest.main()
