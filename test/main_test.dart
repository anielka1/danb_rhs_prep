import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/screens/login_screen.dart';
import 'package:danb_rhs_prep/services/fakes/fake_analytics_service.dart';

void main() {
  testWidgets('first launch goes Splash -> main shell -> Home, never Login',
      (tester) async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    await tester.pumpWidget(DanbRhsPrepApp(analytics: analytics));

    // Splash is shown first; Login must not appear on normal launch.
    expect(find.text('DANB RHS Prep'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    // Flush the splash screen's navigation timer so the test ends with no
    // pending timers.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Today'), findsOneWidget); // Home tab content
  });

  testWidgets('the initial Home view is reported exactly once on first launch',
      (tester) async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    await tester.pumpWidget(DanbRhsPrepApp(analytics: analytics));

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(analytics.screenViews.where((id) => id == 'home').length, 1);
  });
}
