import 'dart:math';
import '../domain/models/answer_attempt.dart';
import '../domain/models/practice_session.dart';
import '../study_plan/study_schedule_service.dart';
import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../practice_session/practice_generator.dart';
import '../practice_session/practice_session_controller.dart';
import '../study_plan/planned_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key, required this.session, this.random});
  final Random? random;
  final BootstrapSessionController session;
  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  PracticeSessionController? _controller;
  String? _message, _selection;
  bool _busy = false, _done = false;
  bool _checking = true, _resume = false, _checkFailed = false;
  List<AnswerAttempt> _recorded = const [];
  // Eligibility failures require content/state changes; storage failures
  // can be retried without discarding an existing diagnostic.
  bool _startUnavailable = false, _retryStart = false;
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() {
      _checking = true;
      _message = null;
      _checkFailed = false;
    });
    try {
      final repo = widget.session.progressRepository;
      if (repo == null) throw StateError('Storage unavailable');
      final snapshot = widget.session.snapshot;
      final active =
          await repo.inProgressPracticeSession(snapshot.selectedExamId);
      if (active?.mode == PracticeMode.diagnostic) {
        _resume = true;
      } else {
        final history =
            await repo.answerAttemptsForExam(snapshot.selectedExamId);
        _recorded = history
            .where((a) => a.sessionType == AttemptSessionType.diagnostic)
            .toList();
        if (_recorded.isNotEmpty) {
          _done = true;
        } else {
          const PlannedSessionService()
              .diagnosticQuestions(snapshot.contentPackage, {});
        }
      }
    } on PracticeGenerationUnavailable catch (e) {
      _startUnavailable = true;
      _message = widget.session.snapshot.contentPackage.questions
              .any((q) => q.isApproved)
          ? e.message
          : 'No approved questions are available for the starting check. You can skip it and continue to your plan.';
    } catch (_) {
      _checkFailed = true;
      _message = 'Could not read your diagnostic. Please retry.';
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _start() async {
    if (_busy || _startUnavailable) return;
    setState(() {
      _busy = true;
      _message = null;
      _retryStart = false;
    });
    try {
      final repo = widget.session.progressRepository;
      if (repo == null) throw StateError('Storage unavailable');
      final snap = widget.session.snapshot;
      final reserve = await effectiveMockReserve(
          repository: repo,
          package: snap.contentPackage,
          entitlement: snap.entitlement,
          now: DateTime.now(),
          examDate: snap.examDateSelection?.date);
      final controller = await const PlannedSessionService().start(
          package: snap.contentPackage,
          repository: repo,
          entitlement: snap.entitlement,
          now: DateTime.now,
          diagnostic: true,
          random: widget.random,
          reservedIds: reserve);
      if (controller.answeredCount == controller.questions.length) {
        await controller.complete();
      }
      if (mounted) {
        setState(() {
          _controller = controller;
          _done = controller.answeredCount == controller.questions.length &&
              !controller.hasUnsavedChanges;
        });
      }
    } on PracticeGenerationUnavailable catch (e) {
      if (mounted) {
        setState(() {
          _startUnavailable = true;
          _message = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _retryStart = true;
          _message = 'Could not start the diagnostic. Please retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _answer() async {
    if (_selection == null || _busy) return;
    setState(() => _busy = true);
    final c = _controller!;
    if (c.feedbackFor(c.currentQuestion.id) == null) {
      await c.submitAnswer(_selection!);
    }
    if (c.hasUnsavedChanges) {
      if (mounted) {
        setState(() {
          _message = 'Your answer has not saved. Retry before continuing.';
          _busy = false;
        });
      }
      return;
    }
    if (c.currentIndex == c.questions.length - 1) {
      await c.complete();
      _done = !c.hasUnsavedChanges;
    } else {
      c.moveTo(c.currentIndex + 1);
    }
    if (mounted) {
      setState(() {
        _selection = null;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final snap = widget.session.snapshot;
    return PopScope(
        canPop: !_busy && !(c?.hasUnsavedChanges ?? false),
        child: AppScaffold(
            body: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Text(_done ? 'Your starting point' : 'Optional starting check',
                  style: context.textStyles.h1),
              Text('A learning snapshot, not a prediction of passing the exam.',
                  style: context.textStyles.body),
              const SizedBox(height: AppSpacing.lg),
              if (_message != null)
                Text(_message!, style: context.textStyles.body),
              if (_checking)
                const CircularProgressIndicator()
              else if (_checkFailed)
                Column(children: [
                  PrimaryButton(label: 'Retry diagnostic', onPressed: _prepare),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Skip for now'))
                ])
              else if (_done) ...[
                for (final domain in snap.contentPackage.exam.domains)
                  AppCard(
                      child: Text(
                          c != null
                              ? '${domain.name}: ${c.questions.where((q) => q.domainId == domain.id && c.feedbackFor(q.id)?.isCorrect == true).length} / ${c.questions.where((q) => q.domainId == domain.id).length}'
                              : '${domain.name}: ${_recorded.where((a) => a.domainId == domain.id && a.isCorrect).length} / ${_recorded.where((a) => a.domainId == domain.id).length}',
                          style: context.textStyles.body)),
                PrimaryButton(
                    label: 'Continue to my plan',
                    onPressed: () => Navigator.pop(context)),
              ] else if (c == null) ...[
                Text(
                    '${snap.contentPackage.exam.freeTier.diagnosticQuestions} questions across the exam areas. You can skip this and begin your plan.'),
                if (!_startUnavailable)
                  PrimaryButton(
                      label: _retryStart
                          ? 'Retry diagnostic'
                          : _resume
                              ? 'Resume diagnostic'
                              : 'Start diagnostic',
                      onPressed: _busy ? null : _start,
                      isLoading: _busy),
                TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Skip for now')),
              ] else ...[
                TextButton(
                    onPressed: _busy || c.hasUnsavedChanges
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Continue later')),
                Text('Question ${c.currentIndex + 1} of ${c.questions.length}',
                    style: context.textStyles.label),
                Text(c.currentQuestion.questionText,
                    style: context.textStyles.h3),
                for (final a in c.currentQuestion.answers)
                  ListTile(
                      selected: _selection == a.id,
                      leading: Icon(_selection == a.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                      title: Text(a.text),
                      onTap: _busy
                          ? null
                          : () => setState(() => _selection = a.id)),
                if (c.hasUnsavedChanges)
                  TextButton(
                      onPressed: () async {
                        await c.retrySaving();
                        if (!c.hasUnsavedChanges &&
                            c.answeredCount == c.questions.length) {
                          await c.complete();
                        }
                        if (mounted) {
                          setState(() {
                            _message = c.hasUnsavedChanges
                                ? 'Could not save. Retry.'
                                : null;
                            if (!c.hasUnsavedChanges &&
                                c.answeredCount == c.questions.length) {
                              _done = true;
                            }
                          });
                        }
                      },
                      child: const Text('Retry saving')),
                PrimaryButton(
                    label: 'Save and continue',
                    isLoading: _busy,
                    onPressed: _selection == null ? null : _answer),
              ],
            ]))));
  }
}
