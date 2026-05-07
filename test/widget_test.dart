import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SeniorCareApp());
    expect(find.text('SeniorCare'), findsOneWidget);
  });
}
