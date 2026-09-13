import 'main_shell.dart';
import '../widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_scope.dart';
import '../domain/models/entitlement.dart';
import '../domain/repositories/progress_repository.dart';
import '../features/content/domain/content_package.dart';
import '../mock_exam/mock_exam_blueprint.dart';
import '../mock_exam/mock_exam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/primary_button.dart';
import 'exam_overview_screen.dart';
import 'mock_exam_question_screen.dart';

/// Composition boundary for mock exams. Content and storage are injected;
/// no asset, persistence plugin, or demo fixture is imported by the UI.
class MockExamScreen extends StatefulWidget {
  static const String route = '/mock-exam';
  const MockExamScreen(
      {super.key, this.progressRepository, this.contentPackage, this.now});
  final ProgressRepository? progressRepository;
  final ContentPackage? contentPackage;
  final DateTime Function()? now;

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends State<MockExamScreen> {
  MockExamController? _controller;
  ContentPackage? _content;
  ProgressRepository? _repository;
  Entitlement? _entitlement;
  bool _initialized = false;
  bool _loading = true;
  bool _failed = false;
  String? _unavailable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final session = BootstrapSessionScope.maybeControllerOf(context);
    _content = widget.contentPackage ?? session?.snapshot.contentPackage;
    _repository = widget.progressRepository ?? session?.progressRepository;
    _entitlement = session?.snapshot.entitlement;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _unavailable = null;
    });
    if (_content == null || _repository == null) {
      setState(() {
        _loading = false;
        _unavailable =
            'A mock exam requires eligible content and local exam storage. '
            'No result will be generated without a completed exam.';
      });
      return;
    }
    try {
      final controller = MockExamController(
          blueprint: MockExamBlueprint.fromPackage(_content!),
          repository: _repository!,
          entitlement: _entitlement,
          now: widget.now ?? DateTime.now);
      await controller.load();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } on MockExamUnavailable catch (error) {
      if (!mounted) return;
      setState(() {
        _unavailable = error.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/mock-exam/instructions'),
      builder: (_) => _MockExamInstructionsScreen(controller: _controller!),
    ));
    if (mounted) {
      final shell = MainShellScope.maybeOf(context);
      if (shell != null) {
        shell.goToTab(AppTab.home, resetTab: shell.currentTab);
      } else {
        await _load();
      }
    }
  }

  void _openExamInfo() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      settings: const RouteSettings(name: ExamOverviewScreen.route),
      builder: (_) => ExamOverviewScreen(
          contentPackage: _content,
          progressRepository: _repository,
          entitlement: _entitlement),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const LoadingState(message: 'Loading mock exam');
    } else if (_failed) {
      body = ErrorState(
          title: 'Could not load your mock exam',
          message: 'Your saved exam has not been changed. Please try again.',
          onRetry: _load);
    } else if (_unavailable != null) {
      body = EmptyState(
          title: 'Mock Exam unavailable',
          message: _unavailable,
          primaryActionLabel: 'View Exam Info',
          onPrimaryAction: _openExamInfo);
    } else {
      final controller = _controller!;
      body = EmptyState(
          icon: Icons.assignment_rounded,
          title: 'Mock Exam',
          message: controller.inProgress
              ? 'Your answers and flags are saved. Resume your exam where you left off.'
              : '${controller.questions.length} questions. Read the instructions before you begin.',
          primaryActionLabel:
              controller.inProgress ? 'Resume Mock Exam' : 'Start Mock Exam',
          onPrimaryAction: _open);
    }
    return AppScaffold(
        title: 'Mock exam',
        leading: Navigator.of(context).canPop()
            ? CircleIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Back to Home',
                onPressed: () => Navigator.of(context).pop())
            : null,
        body: body);
  }
}

class _MockExamInstructionsScreen extends StatefulWidget {
  const _MockExamInstructionsScreen({required this.controller});
  final MockExamController controller;
  @override
  State<_MockExamInstructionsScreen> createState() =>
      _MockExamInstructionsScreenState();
}

class _MockExamInstructionsScreenState
    extends State<_MockExamInstructionsScreen> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _begin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.controller.start();
      if (!mounted) return;
      setState(() => _busy = false);
      await Navigator.of(context).push(MaterialPageRoute<void>(
        settings: const RouteSettings(name: MockExamQuestionScreen.route),
        builder: (_) => MockExamQuestionScreen(controller: widget.controller),
      ));
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blueprint = widget.controller.blueprint;
    final config = blueprint.config;
    final text = context.textStyles;
    return PopScope(
        canPop: !_busy,
        child: AppScaffold(
          title: 'Mock Exam Instructions',
          leading: CircleIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Back',
              onPressed: _busy ? null : () => Navigator.of(context).pop()),
          body: _busy
              ? const LoadingState(message: 'Opening mock exam')
              : SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Text('A focused practice exam.', style: text.h1),
                        const SizedBox(height: AppSpacing.xxl),
                        if (blueprint.isDemo)
                          Text('Demo exam · synthetic questions',
                              style: text.h3),
                        Text('${config.questionCount} questions',
                            style: text.h3),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                            config.timed
                                ? 'Time limit: ${config.durationMinutes} minutes.'
                                : 'Untimed exam.',
                            style: text.body),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                            config.allowsBackNavigation
                                ? 'You can revisit questions and change answers before finishing.'
                                : 'Forward navigation only. You cannot revisit earlier questions.',
                            style: text.body),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                            'Select an answer to save it. Flag questions to find them later. '
                            'Correct answers are not revealed during the exam. '
                            'Unanswered questions count as incorrect when you finish.',
                            style: text.body),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                            'Practice threshold: ${config.practicePassingPercent}% correct. '
                            'Reaching the threshold uses the Above practice threshold label.',
                            style: text.body),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                            blueprint.isDemo
                                ? 'Works offline. Answers are kept during this demo run. '
                                    'Closing the exam lets you resume; restarting the demo app resets its data.'
                                : 'Answers and flags are saved locally after every change.',
                            style: text.body),
                        const SizedBox(height: AppSpacing.lg),
                        Text(MockExamResult.disclaimer, style: text.body),
                        const SizedBox(height: AppSpacing.xl),
                        if (_failed) ...[
                          Semantics(
                              liveRegion: true,
                              child: const Text(
                                  'Could not open the exam. Please try again.')),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        PrimaryButton(
                            label: _failed
                                ? 'Try Again'
                                : widget.controller.inProgress
                                    ? 'Resume exam'
                                    : 'Begin exam',
                            onPressed: _begin),
                        const SizedBox(height: AppSpacing.lg),
                      ]),
                ),
        ));
  }
}
