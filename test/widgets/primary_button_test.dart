import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/primary_button.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)));
  }

  group('PrimaryButton', () {
    testWidgets('renders under light and dark themes', (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(wrap(
            PrimaryButton(label: 'Continue', onPressed: () {}),
            theme: theme));
        expect(find.text('Continue'), findsOneWidget);
      }
    });

    testWidgets('tap callback fires exactly once per tap', (tester) async {
      int taps = 0;
      await tester.pumpWidget(
          wrap(PrimaryButton(label: 'Go', onPressed: () => taps++)));
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(wrap(const PrimaryButton(label: 'Go')));
      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('loading state disables the button and shows a spinner',
        (tester) async {
      int taps = 0;
      await tester.pumpWidget(
        wrap(PrimaryButton(
            label: 'Submit', isLoading: true, onPressed: () => taps++)),
      );

      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull,
          reason: 'loading must prevent duplicate activation');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('loading does not change the button width', (tester) async {
      await tester.pumpWidget(wrap(const PrimaryButton(label: 'Submit')));
      final double idleWidth = tester.getSize(find.byType(PrimaryButton)).width;

      await tester.pumpWidget(wrap(
          PrimaryButton(label: 'Submit', isLoading: true, onPressed: () {})));
      final double loadingWidth =
          tester.getSize(find.byType(PrimaryButton)).width;

      expect(loadingWidth, idleWidth);
    });

    testWidgets('meets the 44pt minimum interactive height', (tester) async {
      await tester
          .pumpWidget(wrap(PrimaryButton(label: 'Go', onPressed: () {})));
      final Size size = tester.getSize(find.byType(PrimaryButton));
      expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
    });

    testWidgets('exposes button semantics with a loading-aware label',
        (tester) async {
      await tester.pumpWidget(wrap(
          PrimaryButton(label: 'Submit', isLoading: true, onPressed: () {})));
      expect(find.bySemanticsLabel(RegExp('Submit.*loading')), findsOneWidget);
    });

    testWidgets('long label does not overflow (renders without a layout error)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryButton(
            label:
                'This is a very long button label that could overflow a fixed-width button',
            onPressed: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('scales with large text without throwing', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
          child: wrap(PrimaryButton(label: 'Get Started', onPressed: () {})),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Get Started'), findsOneWidget);
    });
  });

  group('SecondaryButton', () {
    testWidgets('tap callback fires exactly once per tap', (tester) async {
      int taps = 0;
      await tester.pumpWidget(
          wrap(SecondaryButton(label: 'Review', onPressed: () => taps++)));
      await tester.tap(find.byType(SecondaryButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('loading state disables the button', (tester) async {
      await tester.pumpWidget(wrap(
          SecondaryButton(label: 'Review', isLoading: true, onPressed: () {})));
      final OutlinedButton button = tester.widget(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('meets the 44pt minimum interactive height', (tester) async {
      await tester
          .pumpWidget(wrap(SecondaryButton(label: 'Review', onPressed: () {})));
      final Size size = tester.getSize(find.byType(SecondaryButton));
      expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
    });
  });

  group('CircleIconButton', () {
    testWidgets('meets the 44x44 minimum interactive size', (tester) async {
      await tester.pumpWidget(
          wrap(CircleIconButton(icon: Icons.close_rounded, onPressed: () {})));
      final Size size = tester.getSize(find.byType(CircleIconButton));
      expect(size.width, greaterThanOrEqualTo(AppTapTarget.minInteractive));
      expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
    });

    testWidgets('tap callback fires exactly once per tap', (tester) async {
      int taps = 0;
      await tester.pumpWidget(wrap(CircleIconButton(
          icon: Icons.close_rounded, onPressed: () => taps++)));
      await tester.tap(find.byType(CircleIconButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('exposes an explicit semantic label when provided',
        (tester) async {
      await tester.pumpWidget(
        wrap(CircleIconButton(
            icon: Icons.close_rounded,
            onPressed: () {},
            semanticLabel: 'Close')),
      );
      expect(find.bySemanticsLabel('Close'), findsOneWidget);
    });
  });
}
