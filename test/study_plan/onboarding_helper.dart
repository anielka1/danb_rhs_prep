import 'package:flutter_test/flutter_test.dart';

Future<void> selectAvailability(WidgetTester tester,
    {bool skipDiagnostic = true}) async {
  await tester.ensureVisible(find.text('Monday'));
  await tester.tap(find.text('Monday'));
  await tester.ensureVisible(find.text('30 min'));
  await tester.tap(find.text('30 min'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Save availability'));
  await tester.tap(find.text('Save availability'));
  await tester.pumpAndSettle();
  if (skipDiagnostic) {
    await tester.ensureVisible(find.text('Skip for now'));
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
  }
}
