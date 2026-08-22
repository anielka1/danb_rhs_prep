import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/subscription_product_card.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)));
  }

  testWidgets(
      'renders the caller-supplied localized price under light and dark themes',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        wrap(
          const SubscriptionProductCard(
            title: 'Monthly',
            priceText:
                'CA\$12.99', // a non-US-formatted string, proving it's caller-supplied, not hardcoded
            billingPeriodText: 'per month',
          ),
          theme: theme,
        ),
      );
      expect(find.textContaining('CA\$12.99'), findsOneWidget);
      expect(find.textContaining('per month'), findsOneWidget);
    }
  });

  testWidgets('shows the recommended badge only when explicitly set',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const SubscriptionProductCard(
          title: 'Monthly',
          priceText: '\$9.99',
          billingPeriodText: 'per month',
        ),
      ),
    );
    expect(find.text('RECOMMENDED'), findsNothing);

    await tester.pumpWidget(
      wrap(
        const SubscriptionProductCard(
          title: 'Monthly',
          priceText: '\$9.99',
          billingPeriodText: 'per month',
          recommended: true,
        ),
      ),
    );
    expect(find.text('RECOMMENDED'), findsOneWidget);
  });

  testWidgets('shows the optional introductory offer text', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SubscriptionProductCard(
          title: 'Monthly',
          priceText: '\$9.99',
          billingPeriodText: 'per month',
          introductoryOfferText: '3 days free, then \$9.99/month',
        ),
      ),
    );
    expect(find.text('3 days free, then \$9.99/month'), findsOneWidget);
  });

  testWidgets('select callback fires exactly once per tap', (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      wrap(
        SubscriptionProductCard(
          title: 'Monthly',
          priceText: '\$9.99',
          billingPeriodText: 'per month',
          onSelect: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(SubscriptionProductCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('loading state shows a spinner and blocks selection',
      (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      wrap(
        SubscriptionProductCard(
          title: 'Monthly',
          priceText: '\$9.99',
          billingPeriodText: 'per month',
          isLoading: true,
          onSelect: () => taps++,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(SubscriptionProductCard));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('disabled state blocks selection', (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      wrap(
        SubscriptionProductCard(
          title: 'Monthly',
          priceText: '\$9.99',
          billingPeriodText: 'per month',
          enabled: false,
          onSelect: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(SubscriptionProductCard));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('exposes selected state in semantics', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        SubscriptionProductCard(
          title: 'Monthly',
          priceText: '\$9.99',
          billingPeriodText: 'per month',
          selected: true,
          onSelect: () {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(SubscriptionProductCard)),
      matchesSemantics(
        label: 'Monthly, \$9.99, per month',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });
}
