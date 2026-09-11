import 'package:flutter_test/flutter_test.dart';

Future<void> skipStartingCheck(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Skip for now'));
  await tester.tap(find.text('Skip for now'));
  await tester.pumpAndSettle();
}
