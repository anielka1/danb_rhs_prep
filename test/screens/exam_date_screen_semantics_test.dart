import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/screens/exam_date_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

/// A real semantics-tree traversal test for `ExamDateScreen` — distinct
/// from `exam_date_screen_test.dart`'s widget-coordinate "visual layout
/// order" check, which proves top-to-bottom position, not what a screen
/// reader would actually announce or in what order. This file walks the
/// real [SemanticsNode] tree the framework builds, the same structure
/// VoiceOver/TalkBack read from. It is still not a substitute for
/// manually operating VoiceOver — that remains a separate, pending
/// manual verification step.
ExamConfig _fakeExamConfig() {
  return const ExamConfig(
    id: 'danb_rhs',
    name: 'DANB RHS Exam Prep',
    provider: 'Dental Assisting National Board',
    examVersion: 'v1',
    contentVersion: '1.0',
    domains: [],
    mockExam: MockExamConfig(
      questionCount: 10,
      durationMinutes: 30,
      practicePassingPercent: 0.7,
      allowsBackNavigation: true,
      timed: true,
    ),
    officialScoring: OfficialScoringConfig(
      scaleMinimum: 200,
      scaleMaximum: 800,
      passingScaledScore: 400,
      isComputerAdaptive: false,
    ),
    readiness: ReadinessConfig(
      weights: ReadinessWeights(
        recentAccuracy: 0.2,
        domainMastery: 0.2,
        mockPerformance: 0.2,
        repeatedMastery: 0.2,
        coverage: 0.2,
      ),
      thresholds: [],
      priorScore: 0,
      minimumEvidenceQuestions: 5,
      recencyHalfLifeDays: 14,
      weakDomainPenalty: 0.1,
    ),
    subscriptionProductIds: SubscriptionProductIds(
      weekly: 'w',
      monthly: 'm',
      threeMonths: '3m',
    ),
    freeTier: FreeTierConfig(
      dailyPracticeQuestions: 5,
      diagnosticQuestions: 10,
      includedMockExams: 1,
    ),
    disclaimer: '',
  );
}

BootstrapReady _readySnapshot({ExamDateSelection? examDateSelection}) {
  return BootstrapReady(
    selectedExamId: 'danb_rhs',
    contentPackage: ContentPackage(
      exam: _fakeExamConfig(),
      contentVersion: '1.0',
      sourceVersion: '1.0',
      generatedAt: DateTime.utc(2026, 1, 1),
      questions: const [],
    ),
    profile: null,
    themePreference: ThemePreference.system,
    readinessSnapshot: null,
    entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
    onboardingComplete: false,
    examDateSelection: examDateSelection,
  );
}

/// [writeExamDateSelection] never resolves on its own — lets a test hold
/// `ExamDateScreen` in its busy/loading state deterministically.
class _NeverCompletingLocalStore implements BootstrapLocalStore {
  _NeverCompletingLocalStore(this._delegate);
  final BootstrapLocalStore _delegate;
  final Completer<void> writeCompleter = Completer<void>();

  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) =>
      writeCompleter.future;

  @override
  Future<String?> readSelectedExamId() => _delegate.readSelectedExamId();
  @override
  Future<void> writeSelectedExamId(String examId) =>
      _delegate.writeSelectedExamId(examId);
  @override
  Future<bool?> readOnboardingComplete() => _delegate.readOnboardingComplete();
  @override
  Future<void> writeOnboardingComplete(bool complete) =>
      _delegate.writeOnboardingComplete(complete);
  @override
  Future<ThemePreference?> readThemePreference() =>
      _delegate.readThemePreference();
  @override
  Future<void> writeThemePreference(ThemePreference preference) =>
      _delegate.writeThemePreference(preference);
  @override
  Future<Entitlement?> readEntitlementSnapshot() =>
      _delegate.readEntitlementSnapshot();
  @override
  Future<void> writeEntitlementSnapshot(Entitlement entitlement) =>
      _delegate.writeEntitlementSnapshot(entitlement);
  @override
  Future<ReadinessSnapshot?> readLatestReadinessSnapshot(String examId) =>
      _delegate.readLatestReadinessSnapshot(examId);
  @override
  Future<void> writeLatestReadinessSnapshot(ReadinessSnapshot snapshot) =>
      _delegate.writeLatestReadinessSnapshot(snapshot);
  @override
  Future<ExamDateSelection?> readExamDateSelection() =>
      _delegate.readExamDateSelection();
}

/// Finds the root [SemanticsNode] via the non-deprecated
/// [RendererBinding.rootPipelineOwner] tree: the root pipeline owner
/// itself has no [SemanticsOwner] in a multi-view test harness, so this
/// walks its children to find the per-view owner that does. (Same
/// pattern as `test/screens/focus_order_test.dart`.)
SemanticsNode _rootSemanticsNode(WidgetTester tester) {
  SemanticsNode? found;
  void visit(PipelineOwner owner) {
    found ??= owner.semanticsOwner?.rootSemanticsNode;
    if (found == null) owner.visitChildren(visit);
  }

  visit(tester.binding.rootPipelineOwner);
  return found!;
}

/// Depth-first, screen-reader-order list of every labeled node.
List<String> _labelOrder(SemanticsNode root) {
  final List<String> labels = [];
  void visit(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    final List<SemanticsNode> children =
        node.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder);
    for (final child in children) {
      visit(child);
    }
  }

  visit(root);
  return labels;
}

/// Depth-first list of every node carrying a non-empty label, alongside
/// the node itself — for tests that need to inspect a specific node's
/// flags (selected/enabled/live-region), not just its label text.
List<SemanticsNode> _labeledNodes(SemanticsNode root) {
  final List<SemanticsNode> nodes = [];
  void visit(SemanticsNode node) {
    if (node.label.isNotEmpty) nodes.add(node);
    final List<SemanticsNode> children =
        node.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder);
    for (final child in children) {
      visit(child);
    }
  }

  visit(root);
  return nodes;
}

void main() {
  Widget wrap({
    required BootstrapLocalStore localStore,
    ExamDateSelection? restoredSelection,
    DateTime Function()? now,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BootstrapSessionScope(
        snapshot: _readySnapshot(examDateSelection: restoredSelection),
        child: ExamDateScreen(
          localStore: localStore,
          now: now ?? (() => DateTime(2026, 3, 10)),
        ),
      ),
    );
  }

  testWidgets(
      'default state: heading, copy, all three choices, and Continue '
      'appear in the required semantic order, with nothing extra',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

    final List<String> order = _labelOrder(_rootSemanticsNode(tester));

    final int headingIndex = order.indexOf('When is your exam?');
    final int copyIndex = order.indexOf(
        'This helps us shape your study plan. You can change it later.');
    final int exactIndex =
        order.indexWhere((l) => l.startsWith('I know the exact date'));
    final int approximateIndex =
        order.indexWhere((l) => l.startsWith('I have an approximate date'));
    final int unscheduledIndex =
        order.indexWhere((l) => l.startsWith("I haven't scheduled it yet"));
    final int continueIndex = order.indexOf('Continue');

    for (final index in [
      headingIndex,
      copyIndex,
      exactIndex,
      approximateIndex,
      unscheduledIndex,
      continueIndex,
    ]) {
      expect(index, greaterThanOrEqualTo(0));
    }
    expect(headingIndex, lessThan(copyIndex));
    expect(copyIndex, lessThan(exactIndex));
    expect(exactIndex, lessThan(approximateIndex));
    expect(approximateIndex, lessThan(unscheduledIndex));
    expect(unscheduledIndex, lessThan(continueIndex));

    // The heading, copy, and each choice are announced exactly once —
    // none of this screen's decorative icons (choice-card radio icons;
    // none are present yet in this no-error state) contribute a stray
    // duplicate. (The screen's own back button also appears, ahead of
    // the heading, which is expected chrome, not part of this order.)
    expect(order.where((l) => l == 'When is your exam?').length, 1);
    expect(
        order
            .where((l) =>
                l ==
                'This helps us shape your study plan. You can change it '
                    'later.')
            .length,
        1);
    expect(order.where((l) => l.startsWith('I know the exact date')).length, 1);
    expect(
        order.where((l) => l.startsWith('I have an approximate date')).length,
        1);
    expect(
        order.where((l) => l.startsWith("I haven't scheduled it yet")).length,
        1);

    handle.dispose();
  });

  testWidgets(
      'choice cards expose selected/unselected state in the real '
      'semantics tree', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

    await tester.tap(find.text('I know the exact date'));
    await tester.pump();

    final List<SemanticsNode> nodes = _labeledNodes(_rootSemanticsNode(tester));
    final SemanticsNode exact =
        nodes.firstWhere((n) => n.label.startsWith('I know the exact date'));
    final SemanticsNode approximate = nodes
        .firstWhere((n) => n.label.startsWith('I have an approximate date'));

    expect(exact.label, 'I know the exact date, selected');
    expect(exact.flagsCollection.isSelected, Tristate.isTrue);
    expect(approximate.label, 'I have an approximate date, not selected');
    expect(approximate.flagsCollection.isSelected, isNot(Tristate.isTrue));

    handle.dispose();
  });

  testWidgets(
      'selecting exact reveals a date selector after the three choices '
      'and before Continue', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

    await tester.tap(find.text('I know the exact date'));
    await tester.pump();

    final List<String> order = _labelOrder(_rootSemanticsNode(tester));
    final int unscheduledIndex =
        order.indexWhere((l) => l.startsWith("I haven't scheduled it yet"));
    final int dateSelectorIndex =
        order.indexWhere((l) => l.startsWith('Exam date,'));
    final int continueIndex = order.indexOf('Continue');

    expect(dateSelectorIndex, greaterThanOrEqualTo(0));
    expect(unscheduledIndex, lessThan(dateSelectorIndex));
    expect(dateSelectorIndex, lessThan(continueIndex));

    handle.dispose();
  });

  testWidgets(
      'selecting unscheduled means the date selector is entirely absent '
      'from the semantics tree, not merely visually hidden', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

    await tester.tap(find.text("I haven't scheduled it yet"));
    await tester.pump();

    final List<String> order = _labelOrder(_rootSemanticsNode(tester));
    expect(order.any((l) => l.startsWith('Exam date,')), isFalse);
    expect(order.any((l) => l.startsWith('Choose a date')), isFalse);

    handle.dispose();
  });

  testWidgets(
      'a stale restored date shows a live-region error between the date '
      'selector and Continue, and is announced exactly once (no '
      'duplicate from the decorative icon)', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final staleSelection = ExamDateSelection(
        precision: ExamDatePrecision.exact,
        date: DateTime(2026, 3, 1)); // before the injected "today" (Mar 10)
    await tester.pumpWidget(wrap(
      localStore: InMemoryBootstrapLocalStore(),
      restoredSelection: staleSelection,
    ));

    final List<String> order = _labelOrder(_rootSemanticsNode(tester));
    final int dateSelectorIndex =
        order.indexWhere((l) => l.startsWith('Exam date,'));
    final int errorIndex =
        order.indexWhere((l) => l.contains('already passed'));
    // The button stays labeled "Continue" (just disabled) for a stale
    // *restored* date — "Retry" is reserved for an actual save failure,
    // a distinct state this test isn't triggering.
    final int continueIndex = order.indexOf('Continue');

    expect(dateSelectorIndex, greaterThanOrEqualTo(0));
    expect(errorIndex, greaterThanOrEqualTo(0));
    expect(continueIndex, greaterThanOrEqualTo(0));
    expect(dateSelectorIndex, lessThan(errorIndex));
    expect(errorIndex, lessThan(continueIndex));

    // Exactly one node carries the error message — the decorative
    // warning icon beside it (no `semanticLabel`) does not add a second,
    // duplicate announcement.
    expect(order.where((l) => l.contains('already passed')).length, 1);

    final SemanticsNode errorNode = _labeledNodes(_rootSemanticsNode(tester))
        .firstWhere((n) => n.label.contains('already passed'));
    expect(errorNode.flagsCollection.isLiveRegion, isTrue);

    handle.dispose();
  });

  testWidgets(
      'Continue exposes a disabled semantic state until a valid '
      'selection is made', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

    final SemanticsNode continueNode = _labeledNodes(_rootSemanticsNode(tester))
        .firstWhere((n) => n.label == 'Continue');
    expect(continueNode.flagsCollection.isEnabled, Tristate.isFalse);

    handle.dispose();
  });

  testWidgets(
      'Continue exposes a loading/busy semantic state while a save is in '
      'flight, and stays disabled', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final controlled =
        _NeverCompletingLocalStore(InMemoryBootstrapLocalStore());
    await tester.pumpWidget(wrap(localStore: controlled));
    await tester.tap(find.text("I haven't scheduled it yet"));
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pump();

    final SemanticsNode busyNode = _labeledNodes(_rootSemanticsNode(tester))
        .firstWhere((n) => n.label.startsWith('Continue'));
    expect(busyNode.label, 'Continue, loading');
    expect(busyNode.flagsCollection.isEnabled, Tristate.isFalse);

    controlled.writeCompleter.complete();
    await tester.pumpAndSettle();
    handle.dispose();
  });
}
