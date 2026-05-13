import 'package:flutter_test/flutter_test.dart';
import 'package:shipeast_customer/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShipEastApp());
    await tester.pump(); // initial frame
    // Advance past the 3-second splash timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
