import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';

void expectOnboardingHome(WidgetTester tester) {
  expect(find.byType(MainShell), findsOneWidget);
  expect(find.text('Optional starting check'), findsNothing);
}
