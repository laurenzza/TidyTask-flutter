import 'package:flutter_test/flutter_test.dart';
import 'package:tidytask/main.dart'; // sesuaikan dengan nama project kamu

void main() {
  testWidgets('App renders with home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(
      find.text('TidyTask'),
      findsOneWidget,
    ); // atau sesuaikan dengan tampilan awal kamu
  });
}
