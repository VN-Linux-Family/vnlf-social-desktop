import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/i18n/vi.dart';

void main() {
  test('copy matches the website\'s vi.ts keys', () {
    expect(vi.pageLogin.dangNhapVnlfSocial, 'Đăng nhập VNLF Social.');
    expect(
      vi.api.auth.emailHoacMatKhauKhong,
      'Email/username hoặc mật khẩu không đúng.',
    );
    expect(
      vi.miscViews.chuaKetNoiDuocMayChu,
      'Chưa kết nối được máy chủ. Kiểm tra mạng rồi thử lại.',
    );
  });

  test('lookup tables are read by key, as on the website', () {
    expect(vi.projects.loai['APP'], 'Ứng dụng');
    expect(vi.wardrobe.mon['pet']?['tux'], 'Tux');
  });

  test('format fills placeholders and keeps unknown ones visible', () {
    expect(
      format(vi.common.yeuCauThatBai, {'status': 500}),
      'Có lỗi xảy ra (mã 500). Thử lại sau ít phút.',
    );
    expect(format('{a} và {b}', {'a': 1}), '1 và {b}');
  });
}
