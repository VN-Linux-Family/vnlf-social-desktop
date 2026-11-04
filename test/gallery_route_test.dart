import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/main.dart';

void main() {
  testWidgets('opens the gallery at /gallery', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/gallery';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    expect(find.text('Thư viện giao diện'), findsOneWidget);
  });
}
