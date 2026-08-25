import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/experience_level.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/screens/experience_level_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

/// A real semantics-tree traversal test for `ExperienceLevelScreen` —
/// distinct from `experience_level_screen_test.dart`'s widget-coordinate
/// "visual layout order" check, which proves top-to-bottom position, not
/// what a screen reader would actually announce or in what order. This
/// walks the real [SemanticsNode] tree the framework builds — the same
/// structure VoiceOver/TalkBack read from. It is still not a substitute
/// for manually operating VoiceOver, which remains a separate, pending
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

BootstrapReady _readySnapshot() {
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
    examDateSelection: null,
    experienceLevel: null,
  );
}

/// [writeExperienceLevel] never resolves on its own — lets a test hold
/// `ExperienceLevelScreen` in its busy/loading state deterministically.
class _NeverCompletingLocalStore implements BootstrapLocalStore {
  _NeverCompletingLocalStore(this._delegate);
  final BootstrapLocalStore _delegate;
  final Completer<void> writeCompleter = Completer<void>();

  @override
  Future<void> writeExperienceLevel(ExperienceLevel level) =>
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
  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) =>
      _delegate.writeExamDateSelection(selection);
  @override
  Future<ExperienceLevel?> readExperienceLevel() =>
      _delegate.readExperienceLevel();
}

/// [writeExperienceLevel] always fails — used to reach the recoverable
/// error state deterministically.
class _ThrowingSelectionLocalStore implements BootstrapLocalStore {
  _ThrowingSelectionLocalStore(this._delegate);
  final BootstrapLocalStore _delegate;

  @override
  Future<void> writeExperienceLevel(ExperienceLevel level) async {
    throw StateError('disk full');
  }

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
  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) =>
      _delegate.writeExamDateSelection(selection);
  @override
  Future<ExperienceLevel?> readExperienceLevel() =>
      _delegate.readExperienceLevel();
}

/// Finds the root [SemanticsNode] via the non-deprecated
/// [RendererBinding.rootPipelineOwner] tree (same pattern as
/// `test/screens/focus_order_test.dart` and
/// `exam_date_screen_semantics_test.dart`).
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
  Widget wrap({required BootstrapLocalStore localStore}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BootstrapSessionScope(
        controller: BootstrapSessionController(_readySnapshot()),
        child: ExperienceLevelScreen(localStore: localStore),
      ),
    );
  }

  testWidgets(
      'default state: heading, copy, all three choices, and Continue '
      'appear in the required semantic order, each exactly once',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

    final List<String> order = _labelOrder(_rootSemanticsNode(tester));

    final int headingIndex =
        order.indexOf('Where are you in your preparation?');
    final int copyIndex =
        order.indexOf('Choose the option that best describes you right now.');
    final int justStartingIndex =
        order.indexWhere((l) => l.startsWith('Just starting'));
    final int studyingIndex =
        order.indexWhere((l) => l.startsWith('Studying already'));
    final int retakingIndex =
        order.indexWhere((l) => l.startsWith('Taking the exam again'));
    final int continueIndex = order.indexOf('Continue');

    for (final index in [
      headingIndex,
      copyIndex,
      justStartingIndex,
      studyingIndex,
      retakingIndex,
      continueIndex,
    ]) {
      expect(index, greaterThanOrEqualTo(0));
    }
    expect(headingIndex, lessThan(copyIndex));
    expect(copyIndex, lessThan(justStartingIndex));
    expect(justStartingIndex, lessThan(studyingIndex));
    expect(studyingIndex, lessThan(retakingIndex));
    expect(retakingIndex, lessThan(continueIndex));

    // Each expected label is announced exactly once — no decorative
    // icon (the choice cards' radio icons carry no `semanticLabel`)
    // contributes a stray duplicate.
    expect(order.where((l) => l == 'Where are you in your preparation?').length,
        1);
    expect(
        order
            .where((l) =>
                l == 'Choose the option that best describes you right now.')
            .length,
        1);
    expect(order.where((l) => l.startsWith('Just starting')).length, 1);
    expect(order.where((l) => l.startsWith('Studying already')).length, 1);
    expect(order.where((l) => l.startsWith('Taking the exam again')).length, 1);

    handle.dispose();
  });

  testWidgets(
      'choice cards expose selected/unselected state in the real '
      'semantics tree', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

    await tester.tap(find.text('Studying already'));
    await tester.pump();

    final List<SemanticsNode> nodes = _labeledNodes(_rootSemanticsNode(tester));
    final SemanticsNode studying =
        nodes.firstWhere((n) => n.label.startsWith('Studying already'));
    final SemanticsNode justStarting =
        nodes.firstWhere((n) => n.label.startsWith('Just starting'));

    expect(studying.label, 'Studying already, selected');
    expect(studying.flagsCollection.isSelected, Tristate.isTrue);
    expect(justStarting.label, 'Just starting, not selected');
    expect(justStarting.flagsCollection.isSelected, isNot(Tristate.isTrue));

    handle.dispose();
  });

  testWidgets(
      'a save-failure error appears between the choices and Continue, as '
      'a live region announced exactly once (no duplicate from the '
      'decorative icon)', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final localStore =
        _ThrowingSelectionLocalStore(InMemoryBootstrapLocalStore());
    await tester.pumpWidget(wrap(localStore: localStore));

    await tester.tap(find.text('Just starting'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final List<String> order = _labelOrder(_rootSemanticsNode(tester));
    final int retakingIndex =
        order.indexWhere((l) => l.startsWith('Taking the exam again'));
    final int errorIndex =
        order.indexWhere((l) => l.contains("couldn't save this"));
    final int retryIndex = order.indexOf('Retry');

    expect(retakingIndex, greaterThanOrEqualTo(0));
    expect(errorIndex, greaterThanOrEqualTo(0));
    expect(retryIndex, greaterThanOrEqualTo(0));
    expect(retakingIndex, lessThan(errorIndex));
    expect(errorIndex, lessThan(retryIndex));

    expect(order.where((l) => l.contains("couldn't save this")).length, 1);

    final SemanticsNode errorNode = _labeledNodes(_rootSemanticsNode(tester))
        .firstWhere((n) => n.label.contains("couldn't save this"));
    expect(errorNode.flagsCollection.isLiveRegion, isTrue);

    handle.dispose();
  });

  testWidgets(
      'Continue exposes a disabled semantic state until a '
      'selection is made', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(localStore: InMemoryBootstrapLocalStore()));

    final SemanticsNode continueNode = _labeledNodes(_rootSemanticsNode(tester))
        .firstWhere((n) => n.label == 'Continue');
    expect(continueNode.flagsCollection.isEnabled, Tristate.isFalse);

    handle.dispose();
  });

  testWidgets(
      'Continue exposes a loading/busy semantic state while a save is '
      'in flight, and stays disabled', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final controlled =
        _NeverCompletingLocalStore(InMemoryBootstrapLocalStore());
    await tester.pumpWidget(wrap(localStore: controlled));
    await tester.tap(find.text('Just starting'));
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
