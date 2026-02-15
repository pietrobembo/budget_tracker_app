import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker_app/main.dart';

void main() {
  testWidgets('App renders Budget Tracker title', (WidgetTester tester) async {
    await tester.pumpWidget(const BudgetApp());
    expect(find.text('💰 Budget Tracker'), findsOneWidget);
  });
}
