import 'dart:async';
import 'package:flutter/material.dart';
import '../mock_exam/mock_exam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_option_tile.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/primary_button.dart';
import 'mock_exam_results_screen.dart';

class MockExamQuestionScreen extends StatefulWidget {
  static const route = '/mock-exam/questions';
  const MockExamQuestionScreen({super.key, required this.controller});
  final MockExamController controller;
  @override
  State<MockExamQuestionScreen> createState() => _MockExamQuestionScreenState();
}

class _MockExamQuestionScreenState extends State<MockExamQuestionScreen> {
  Timer? _timer;
  bool _busy = false;
  bool _confirming = false;
  bool _showNavigator = false;
  Future<void> Function()? _retry;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.blueprint.config.timed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _retry = null;
    });
    try {
      await action();
      if (!mounted) return;
      if (!widget.controller.inProgress) {
        setState(() => _busy = false);
        await Navigator.of(context).push(MaterialPageRoute<void>(
          settings: const RouteSettings(name: MockExamResultsScreen.route),
          builder: (_) =>
              MockExamResultsScreen(result: widget.controller.result),
        ));
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() => _busy = false);
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _retry = action;
      });
    }
  }

  Future<void> _move(int index) async {
    await _perform(() => widget.controller.moveTo(index));
    if (mounted && _retry == null) {
      setState(() => _showNavigator = false);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  Future<void> _finish() async {
    if (_confirming || _busy) return;
    _confirming = true;
    final unanswered = widget.controller.unansweredCount;
    final confirmed = await AppDialog.show<bool>(
        context: context,
        title: 'Finish mock exam?',
        message:
            '$unanswered unanswered question${unanswered == 1 ? '' : 's'} will count as incorrect. '
            'Answers cannot be changed after finishing.',
        actions: const [
          AppDialogAction(
              label: 'Keep answering',
              value: false,
              style: AppDialogActionStyle.cancel),
          AppDialogAction(label: 'Finish exam', value: true),
        ]);
    _confirming = false;
    if (mounted && confirmed == true) await _perform(widget.controller.finish);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final question = controller.currentQuestion;
    final attempt = controller.attempt!;
    final flagged = attempt.flaggedQuestionIds.contains(question.id);
    final text = context.textStyles;
    Widget body;
    if (_busy) {
      body = const LoadingState(message: 'Saving exam');
    } else if (_retry != null) {
      body = SingleChildScrollView(
          child: Column(children: [
        ErrorState(
            title: 'Could not save this change',
            message:
                'Your previous answers and flags are unchanged. Try again.',
            onRetry: () => _perform(_retry!)),
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(
            label: 'Back to exam',
            onPressed: () => setState(() => _retry = null)),
      ]));
    } else {
      final remainingSeconds =
          (controller.remaining.inMilliseconds / 1000).ceil();
      body = SingleChildScrollView(
        controller: _scroll,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: AppSpacing.md),
          if (controller.blueprint.isDemo)
            Text('Demo · synthetic questions', style: text.label),
          Semantics(
              liveRegion: true,
              child: Text(
                  'Question ${controller.currentIndex + 1} of ${controller.questions.length}',
                  style: text.h3)),
          Text(
              '${attempt.answeredCount} answered · ${attempt.flaggedQuestionIds.length} flagged',
              style: text.body),
          if (controller.blueprint.config.timed)
            Text(
                'Time remaining: ${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: text.body),
          if (controller.isExpired)
            Semantics(
                liveRegion: true,
                child: const Text(
                    'Time is up. Finish the exam to see your practice result.')),
          const SizedBox(height: AppSpacing.lg),
          Text(question.questionText, style: text.h3),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < question.answers.length; i++) ...[
            AnswerOptionTile(
                letter: String.fromCharCode(65 + i),
                text: question.answers[i].text,
                state: attempt.answers[question.id] == question.answers[i].id
                    ? AnswerOptionState.selected
                    : AnswerOptionState.unselected,
                onTap: controller.isExpired
                    ? null
                    : () => _perform(
                        () => controller.answer(question.answers[i].id))),
            const SizedBox(height: AppSpacing.sm),
          ],
          Semantics(
              toggled: flagged,
              child: SecondaryButton(
                  label: flagged ? 'Remove flag' : 'Flag question',
                  onPressed: () => _perform(controller.toggleFlag))),
          const SizedBox(height: AppSpacing.lg),
          if (controller.canMoveTo(controller.currentIndex - 1)) ...[
            SecondaryButton(
                label: 'Previous question',
                onPressed: () => _move(controller.currentIndex - 1)),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (controller.canMoveTo(controller.currentIndex + 1)) ...[
            PrimaryButton(
                label: 'Next question',
                onPressed: () => _move(controller.currentIndex + 1)),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          Semantics(
            expanded: _showNavigator,
            child: SecondaryButton(
              label: _showNavigator
                  ? 'Hide question navigator'
                  : 'Show question navigator',
              onPressed: () => setState(() => _showNavigator = !_showNavigator),
            ),
          ),
          if (_showNavigator) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
                'Choose a question to jump to. Check marks mean answered; '
                'flags mark questions to revisit.',
                style: text.body),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
              for (var i = 0; i < controller.questions.length; i++)
                _navigatorItem(i),
            ]),
          ],
          const SizedBox(height: AppSpacing.xl),
          SecondaryButton(label: 'Finish mock exam', onPressed: _finish),
          const SizedBox(height: AppSpacing.lg),
        ]),
      );
    }
    return PopScope(
        canPop: !_busy,
        child: AppScaffold(
            title: 'Mock Exam',
            leading: CircleIconButton(
                icon: Icons.close_rounded,
                semanticLabel: 'Exit exam',
                onPressed: _busy ? null : () => Navigator.of(context).pop()),
            body: body));
  }

  Widget _navigatorItem(int index) {
    final controller = widget.controller;
    final attempt = controller.attempt!;
    final id = controller.questions[index].id;
    final current = index == controller.currentIndex;
    final answered = attempt.answers.containsKey(id);
    final flagged = attempt.flaggedQuestionIds.contains(id);
    final label = 'Question ${index + 1}, ${current ? 'current, ' : ''}'
        '${answered ? 'answered' : 'unanswered'}${flagged ? ', flagged' : ''}';
    final visible = '${index + 1}${answered ? ' ✓' : ''}${flagged ? ' ⚑' : ''}';
    final canMove = controller.canMoveTo(index);
    return Semantics(
      label: label,
      selected: current,
      onTap: canMove ? () => _move(index) : null,
      button: canMove,
      child: ExcludeSemantics(
          child: canMove
              ? TextButton(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(AppTapTarget.minInteractive,
                          AppTapTarget.minInteractive)),
                  onPressed: () => _move(index),
                  child: Text(visible))
              : Container(
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(
                      minWidth: AppTapTarget.minInteractive,
                      minHeight: AppTapTarget.minInteractive),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(visible,
                      style: current
                          ? context.textStyles.label
                          : context.textStyles.body))),
    );
  }
}
