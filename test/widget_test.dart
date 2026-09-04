import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/main.dart';

void main() {
  testWidgets('App boots and shows the splash screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DanbRhsPrepApp());
    expect(find.text('DANB RHS Prep'), findsOneWidget);
  });
}
