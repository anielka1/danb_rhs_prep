import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/answer_option_tile.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)));
  }

  testWidgets('renders letter and text under light and dark themes',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        wrap(
          const AnswerOptionTile(
              letter: 'A', text: '5 rem', state: AnswerOptionState.unselected),
          theme: theme,
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('5 rem'), findsOneWidget);
    }
  });

  testWidgets('correct state shows a check icon', (tester) async {
    await tester.pumpWidget(
      wrap(const AnswerOptionTile(
          letter: 'A', text: '5 rem', state: AnswerOptionState.correct)),
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('incorrect state shows a cancel icon', (tester) async {
    await tester.pumpWidget(
      wrap(const AnswerOptionTile(
          letter: 'B', text: '10 rem', state: AnswerOptionState.incorrect)),
    );
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
  });

  testWidgets('unselected and selected states show no state icon',
      (tester) async {
    await tester.pumpWidget(
      wrap(const AnswerOptionTile(
          letter: 'A', text: '5 rem', state: AnswerOptionState.unselected)),
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);
  });

  testWidgets('tap callback fires exactly once when interactive',
      (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      wrap(
        AnswerOptionTile(
          letter: 'A',
          text: '5 rem',
          state: AnswerOptionState.unselected,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(AnswerOptionTile));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('disabled state ignores taps even when onTap is provided',
      (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      wrap(
        AnswerOptionTile(
          letter: 'A',
          text: '5 rem',
          state: AnswerOptionState.disabled,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(AnswerOptionTile));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('meets the 44pt minimum interactive height', (tester) async {
    await tester.pumpWidget(
      wrap(const AnswerOptionTile(
          letter: 'A', text: '5 rem', state: AnswerOptionState.unselected)),
    );
    final Size size = tester.getSize(find.byType(AnswerOptionTile));
    expect(size.height, greaterThanOrEqualTo(AppTapTarget.minInteractive));
  });

  testWidgets('long answer text wraps without throwing a layout error',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const AnswerOptionTile(
          letter: 'D',
          text:
              'This is a deliberately long answer choice that should wrap across '
              'multiple lines instead of overflowing the tile boundaries.',
          state: AnswerOptionState.unselected,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scales with large text without throwing', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
        child: wrap(
          const AnswerOptionTile(
              letter: 'A', text: '5 rem', state: AnswerOptionState.selected),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('semantics per state', () {
    final cases = <AnswerOptionState, String>{
      AnswerOptionState.unselected: 'not selected',
      AnswerOptionState.selected: 'selected',
      AnswerOptionState.correct: 'correct answer',
      AnswerOptionState.incorrect: 'incorrect, your answer',
      AnswerOptionState.disabled: 'not available',
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} exposes "${entry.value}" in its semantic label',
          (tester) async {
        await tester.pumpWidget(
          wrap(AnswerOptionTile(letter: 'A', text: '5 rem', state: entry.key)),
        );
        expect(find.bySemanticsLabel(RegExp(entry.value)), findsOneWidget);
      });
    }
  });
}
