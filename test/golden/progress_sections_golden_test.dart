import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/screens/progress_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/app_card.dart';
import '../study_plan/fixtures.dart';
import '../support/golden_probe.dart';

void main() {
  for (final dark in [false, true]) {
    for (final empty in [true, false]) {
      testWidgets('progress sections empty=$empty dark=$dark', (tester) async {
        final package = fixture(count: empty ? 0 : 8);
        final repo = InMemoryProgressRepository();
        if (!empty) {
          final day = DateTime(2026, 9, 13);
          await repo.recordAnswerAttempt(answer(package.questions[0], day));
          await repo.recordAnswerAttempt(
              answer(package.questions[1], day, correct: false));
        }
        await pumpGolden(tester,
            ProgressScreen(contentPackage: package, progressRepository: repo),
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            textScale: GoldenTextScale.normal);
        expect(find.byType(AppCard),
            findsNWidgets(1 + package.exam.domains.length));
        expect(
            find.ancestor(
                of: find.text('Progress by subject'),
                matching: find.byType(AppCard)),
            findsNothing);
        for (final domain in package.exam.domains) {
          expect(
              find.descendant(
                  of: find.byKey(ValueKey('subject-progress-${domain.id}')),
                  matching: find.text(domain.name)),
              findsOneWidget);
        }
        expect(
            find.text(
                'No approved questions available yet. Your history is preserved.'),
            empty ? findsOneWidget : findsNothing);
        expect(find.text('Daily activity'), findsOneWidget);
        expect(find.text('Practice More'), findsOneWidget);
        final bank = find.byKey(const ValueKey('bank-progress-counts'));
        Finder stat(String label) => find.descendant(
            of: bank,
            matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.label == label));
        final correct = stat(empty ? '0 Correct' : '1 Correct');
        final review = stat(empty ? '0 Needs review' : '1 Needs review');
        final unattempted = stat(empty ? '0 Not attempted' : '6 Not attempted');
        expect(tester.getTopLeft(correct).dy, tester.getTopLeft(review).dy);
        expect(
            tester.getTopLeft(correct).dy, tester.getTopLeft(unattempted).dy);
        expect(tester.getSize(correct).width,
            closeTo(tester.getSize(review).width, 0.01));
        expect(tester.getSize(correct).width,
            closeTo(tester.getSize(unattempted).width, 0.01));
        expect(tester.takeException(), isNull);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(goldenPath(
                screen: empty
                    ? 'progress_sections_empty'
                    : 'progress_sections_answered',
                brightness: dark ? Brightness.dark : Brightness.light,
                textScale: GoldenTextScale.normal)));
        await tester.ensureVisible(find
            .byKey(ValueKey('subject-progress-${package.exam.domains[1].id}')));
        await tester.pumpAndSettle();
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(goldenPath(
                screen: empty
                    ? 'progress_subjects_empty'
                    : 'progress_subjects_answered',
                brightness: dark ? Brightness.dark : Brightness.light,
                textScale: GoldenTextScale.normal)));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
