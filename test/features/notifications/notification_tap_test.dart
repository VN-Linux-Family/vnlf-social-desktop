import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/notification_tap.dart';

void main() {
  test('routes stay in the app and website pages open outside', () {
    final routes = <String>[];
    final pages = <Uri>[];
    void open(String? payload) => openNotificationTarget(
      payload,
      go: routes.add,
      openWebsite: (page) async {
        pages.add(page);
        return true;
      },
    );

    open('/messages/conv-1');
    open('https://vietnamlinuxfamily.net/help');
    open('');
    open(null);

    expect(routes, ['/messages/conv-1']);
    expect(pages, [Uri.parse('https://vietnamlinuxfamily.net/help')]);
  });
}
