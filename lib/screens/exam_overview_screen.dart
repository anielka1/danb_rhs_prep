import '../subscription/premium_access.dart';
import '../practice_session/resumable_session.dart';
import 'main_shell.dart';
import '../widgets/app_bottom_navigation.dart';
import '../progress/learning_progress.dart';
import 'dart:math';
import '../domain/models/answer_order.dart';
import '../study_plan/study_schedule_service.dart';
import 'package:flutter/material.dart';
import '../domain/models/entitlement.dart';
import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';
import '../features/content/domain/content_package.dart';
import '../features/questions/domain/question.dart';
import '../practice_session/practice_generator.dart';
import '../practice_session/practice_session_controller.dart';
import '../practice_session/practice_session_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_card.dart';
import '../widgets/study_page_heading.dart';
import '../widgets/app_dialog.dart';
import '../widgets/error_state.dart';
import '../widgets/primary_button.dart';
import 'practice_question_screen.dart';

enum PracticeLaunch { random, quick10, timed, mistakes, topic }

class ExamOverviewScreen extends StatefulWidget {
  static const String route = '/exam-overview';

  const ExamOverviewScreen({
    super.key,
    this.contentPackage,
    this.progressRepository,
    this.entitlement,
    this.now,
    this.random,
    this.autoStart = false,
    this.launch,
  });

  /// Real, already-loaded questions for the active exam — threaded in as
  /// a plain constructor param (from `BootstrapSessionScope`, read once
  /// by whichever tab pushes this screen) rather than read from an
  /// `InheritedWidget` here, since a screen pushed via `Navigator.push`
  /// becomes a sibling route in the `Overlay`, not a descendant of the
  /// tab that pushed it, so it cannot see that tab's ambient scope.
  ///
  /// Null when reached without real content threaded through yet (e.g.
  /// the static named-route fallback in `main.dart`) — "Start Practice
  /// Exam" is disabled with a clear reason in that case, never started
  /// with zero real questions.
  final ContentPackage? contentPackage;

  /// A real `DriftProgressRepository` in production, forwarded here by
  /// whichever tab pushed this screen (see [PracticeSessionController]'s
  /// doc comment for how it's used). Null only when reached without real
  /// content threaded through either (e.g. the static named-route
  /// fallback in `main.dart`) — the session then still starts and is
  /// fully interactive, just not persisted/resumable.
  final ProgressRepository? progressRepository;

  /// The user's current subscription state, threaded in the same way as
  /// [progressRepository] (from `BootstrapSessionScope`, by whichever tab
  /// pushed this screen). Used to enforce the free-tier daily practice
  /// limit (`exam.freeTier.dailyPracticeQuestions`) via
  /// [maxFreePracticeQuestionsToday] before starting a fresh session — a
  /// premium (active) entitlement means no cap, checked first and without
  /// ever reading attempt history (see [_startOrResumePractice]).
  ///
  /// Null only alongside a null [progressRepository] (the static
  /// named-route fallback in `main.dart`), in which case no cap is
  /// enforced: there's no persisted attempt history to check against
  /// there either, so failing open here matches the same "session still
  /// starts and is fully interactive, just not persisted" behavior
  /// already documented on [progressRepository]. This is distinct from —
  /// and must not be confused with — a free user whose attempt history
  /// fails to *load*: that case is a real repository present but
  /// unreadable, and fails **closed** (see [_limitCheckFailed]), not
  /// open, because unlike this genuinely-absent-entitlement case, there
  /// a free-tier limit demonstrably applies and simply couldn't be
  /// checked.
  final Entitlement? entitlement;

  /// Injected for tests that need a fixed "today" to make free-tier
  /// day-boundary behavior deterministic; defaults to [DateTime.now] in
  /// production.
  final DateTime Function()? now;

  /// Controlled in tests; production draws once when creating a session.
  final Random? random;
  final bool autoStart;
  final PracticeLaunch? launch;

  @override
  State<ExamOverviewScreen> createState() => _ExamOverviewScreenState();
}

class _ExamOverviewScreenState extends State<ExamOverviewScreen> {
  @override
  void initState() {
    super.initState();
    _requestedCount = widget.launch == PracticeLaunch.random ? 1 : 10;
    if (widget.launch == PracticeLaunch.mistakes) {
      _focus = PracticeFocus.incorrectQuestions;
    }
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startOrResumePractice();
      });
    }
  }

  bool _starting = false;
  bool _choosingSession = false;
  int _requestedCount = 10;
  PracticeFocus _focus = PracticeFocus.any;
  String? _domainId;
  String? _topicId;

  void _updateSelection(VoidCallback update) {
    setState(() {
      update();
      _unavailableReason = null;
    });
  }

  /// Set only when a fresh (never-resumed) session could not be
  /// generated. Shown in the same caption slot as the "no content package
  /// at all" message below, cleared on every new attempt.
  ///
  /// **Current, known production state:** the real bundled DANB RHS
  /// content (`assets/content/danb_rhs/content.json`) has exactly 2
  /// questions today, and *both are drafts* — zero approved questions
  /// exist. [PracticeGenerator.select] deliberately excludes drafts
  /// (matching [MockExamBlueprint]'s already-accepted behavior for Mock
  /// Exam), so with today's content, tapping "Start Practice Exam" in a
  /// real production build *always* lands here with a "no eligible
  /// questions" reason — Quick Practice is unavailable end-to-end until
  /// content is approved (tracked separately, see
  /// `docs/PROTOTYPE_CONTENT_AUDIT.md`). This is not a generic/rare error
  /// state to shrug off: it is the expected, reproducible behavior of
  /// today's shipped content, verified by
  /// `test/screens/exam_overview_screen_test.dart`'s
  /// "no approved questions (PREP-667)" test against the real asset file.
  String? _unavailableReason;

  /// Set when a free user's daily practice limit could not be checked
  /// because reading their attempt history from [ExamOverviewScreen
  /// .progressRepository] threw — shown as a real [ErrorState] with a
  /// working retry (which simply calls [_startOrResumePractice] again),
  /// not folded into [_unavailableReason]'s plain caption, and never
  /// papered over by starting an unlimited session: a free user whose
  /// history is unreadable is a real "can't verify, don't know" state,
  /// not evidence they have no limit. A premium (active-entitlement)
  /// user never reaches this: their cap is `null` without ever reading
  /// history in the first place (see [entitlement]'s own doc comment).
  /// Cleared on every new attempt.
  bool _limitCheckFailed = false;

  bool get _hasContent => widget.contentPackage?.questions.isNotEmpty ?? false;

  Future<void> _startOrResumePractice() async {
    if (_starting ||
        !_hasContent ||
        (PremiumAccessScope.maybeOf(context)?.active == false)) {
      return;
    }
    final entitlement =
        PremiumAccessScope.maybeOf(context)?.entitlement ?? widget.entitlement;
    setState(() {
      _starting = true;
      _unavailableReason = null;
      _limitCheckFailed = false;
    });

    final ContentPackage package = widget.contentPackage!;
    final ProgressRepository? repository = widget.progressRepository;
    final String examId = package.exam.id;
    // Threaded into everything below that stamps or measures time —
    // PracticeSession.startedAt, PracticeSessionController's elapsed-time
    // clock, and the daily free-practice-limit check — so a caller
    // injecting a fixed clock (the demo entrypoint; any future test) gets
    // a session whose elapsed timer actually agrees with it, instead of
    // silently falling back to the real device clock partway through.
    final DateTime Function() nowFn = widget.now ?? DateTime.now;

    PracticeSession? existing;
    if (repository != null) {
      try {
        existing = await resumablePracticeSession(repository, examId);
      } catch (_) {
        if (mounted) {
          setState(() {
            _starting = false;
            _unavailableReason =
                'Could not read your saved session. Please try again.';
          });
        }
        return;
      }
    }

    if (!mounted) return;
    if (existing != null &&
        (widget.launch != null ||
            _focus != PracticeFocus.any ||
            _domainId != null ||
            _requestedCount != 10)) {
      setState(() => _choosingSession = true);
      final startNew = await AppDialog.show<bool?>(
        context: context,
        title: 'You have an unfinished session',
        message:
            'Resume it, or start a new session using your selected filters. Your previous session stays saved.',
        actions: const [
          AppDialogAction(label: 'Resume session', value: false),
          AppDialogAction(label: 'Start selected practice', value: true),
          AppDialogAction<bool?>(
              label: 'Cancel', value: null, style: AppDialogActionStyle.cancel),
        ],
      );
      if (!mounted) return;
      setState(() => _choosingSession = false);
      if (startNew == null) {
        setState(() => _starting = false);
        return;
      }
      if (startNew) existing = null;
    }

    final PracticeSession session;
    if (existing != null) {
      session = existing;
    } else {
      // Filtered practice reads persisted question history; the default
      // selection needs only the content package.
      int? maxCount;
      if (entitlement != null && repository != null) {
        final DateTime nowValue = nowFn();
        if (entitlement.isActiveAt(nowValue)) {
          // Premium: no cap, and deliberately no attempt-history read at
          // all — an active entitlement never needs to know "how many
          // today", so it can never be blocked by a history read failure
          // either.
          maxCount = null;
        } else {
          try {
            final answeredToday = practiceAttemptsAnsweredToday(
              attempts: await repository.answerAttemptsForExam(examId),
              now: nowValue,
            );
            maxCount = maxFreePracticeQuestionsToday(
              entitlement: entitlement,
              now: nowValue,
              answeredToday: answeredToday,
              dailyLimit: package.exam.freeTier.dailyPracticeQuestions,
            );
          } catch (_) {
            // Fail CLOSED, not open: a free user's limit demonstrably
            // applies here, it simply couldn't be checked — unlike
            // recoverable new-write failures, which retain their payload
            // for retry. Resume history must also be read successfully,
            // before displaying the saved session. Silently
            // treating "couldn't read" as "no limit" would let a free
            // user bypass their daily cap merely by having a temporarily
            // broken local database. See [_limitCheckFailed]'s own doc
            // comment.
            if (!mounted) return;
            setState(() {
              _starting = false;
              _limitCheckFailed = true;
            });
            return;
          }
        }
      }

      final PracticeGenerator generator;
      try {
        generator = PracticeGenerator.select(
          package: package,
          excludedQuestionIds: repository != null && entitlement != null
              ? await effectiveMockReserve(
                  repository: repository,
                  package: package,
                  entitlement: entitlement,
                  now: nowFn())
              : const {},
          questionStates: _focus == PracticeFocus.any || repository == null
              ? const []
              : await repository.questionStatesForExam(examId),
          requestedCount: _requestedCount,
          focus: _focus,
          currentIncorrectIds: _focus == PracticeFocus.incorrectQuestions &&
                  repository != null
              ? LearningProgress.fromHistory(
                      package: package,
                      attempts: await repository.answerAttemptsForExam(examId),
                      mocks: await repository.mockAttemptsForExam(examId))
                  .incorrectIds
              : const {},
          domainId: _domainId,
          topicId: _topicId,
          random: widget.launch == PracticeLaunch.random
              ? (widget.random ?? Random())
              : null,
          maxCount: maxCount,
        );
      } on PracticeGenerationUnavailable catch (error) {
        if (!mounted) return;
        setState(() {
          _starting = false;
          _unavailableReason = error.message;
        });
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _starting = false;
          _unavailableReason =
              'Could not load your practice history. Please try again.';
        });
        return;
      }
      if (!mounted) return;
      if (widget.launch == PracticeLaunch.quick10 &&
          generator.questions.length < 10) {
        final count = generator.questions.length;
        setState(() => _choosingSession = true);
        final proceed = await AppDialog.show<bool>(
          context: context,
          title: '$count questions available',
          message:
              'Your available questions and current allowance permit $count of 10 questions. Start this shorter session?',
          actions: [
            AppDialogAction(label: 'Start $count questions', value: true),
            const AppDialogAction(
                label: 'Cancel',
                value: false,
                style: AppDialogActionStyle.cancel)
          ],
        );
        if (!mounted) return;
        setState(() => _choosingSession = false);
        if (proceed != true) {
          setState(() => _starting = false);
          return;
        }
      }
      session = PracticeSession(
        id: 'practice-$examId-${nowFn().toUtc().microsecondsSinceEpoch}',
        examId: examId,
        mode: widget.launch == PracticeLaunch.timed
            ? PracticeMode.timedQuiz
            : switch (_focus) {
                PracticeFocus.any => _domainId == null
                    ? PracticeMode.quickPractice
                    : PracticeMode.browseDomain,
                PracticeFocus.weakAreas => PracticeMode.weakAreas,
                PracticeFocus.incorrectQuestions =>
                  PracticeMode.incorrectQuestions,
                PracticeFocus.bookmarkedQuestions => PracticeMode.bookmarked,
              },
        questionIds: generator.questions.map((q) => q.id).toList(),
        answerOrder: AnswerOrder.shuffled(
            generator.questions, widget.random ?? Random()),
        status: SessionStatus.inProgress,
        startedAt: nowFn().toUtc(),
        contentVersion: package.contentVersion,
      );
    }

    // A resumed (`existing != null`) session's questionIds were recorded
    // against whatever content existed when it was first created; a
    // freshly-generated one's ids always resolve, since they were just
    // read from this exact `package`. If content has changed since a
    // resumed session was created — a question retired from the current
    // package — this is a real, reachable gap: `firstWhere` would throw
    // and crash the interactive flow rather than something recoverable.
    //
    // This guard only stops that crash with an honest error state; it
    // does not resolve the underlying stuck session (there's still no
    // way to start a fresh one while a broken in-progress session keeps
    // being returned by `inProgressPracticeSession`) — deciding how to
    // do that (abandon and replace? drop just the missing question and
    // keep going?) is a real product decision, tracked as separate,
    // later work, not silently absorbed into this fix.
    final Map<String, Question> questionsById = {
      for (final q in package.questions) q.id: q,
    };
    final List<Question> questions = [];
    for (final id in session.questionIds) {
      final Question? question = questionsById[id];
      if (question == null) {
        if (!mounted) return;
        setState(() {
          _starting = false;
          _unavailableReason = "This session's content has changed and "
              "can't be resumed right now.";
        });
        return;
      }
      questions.add(question);
    }

    // A resumed session (PREP-665) needs its per-question answered state
    // restored from repository history — the plain constructor always
    // starts empty, which is only correct for the brand-new-session
    // branch below. See PracticeSessionController.resume's own doc
    // comment.
    final PracticeSessionController controller;
    try {
      controller = existing != null && repository != null
          ? await PracticeSessionController.resume(
              session: session,
              questions: questions,
              progressRepository: repository,
              now: nowFn,
            )
          : PracticeSessionController(
              session: session,
              questions: questions,
              progressRepository: repository,
              now: nowFn,
            );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _unavailableReason =
            'Could not restore your saved answers. Please try again.';
      });
      return;
    }

    if (existing == null && repository != null) {
      try {
        await repository.savePracticeSession(session);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _starting = false;
          _unavailableReason = 'Could not save your session. Please try again.';
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() => _starting = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: PracticeQuestionScreen.route),
        builder: (_) => PracticeSessionScope(
          controller: controller,
          child: const PracticeQuestionScreen(),
        ),
      ),
    );
    if (mounted) {
      final shell = MainShellScope.maybeOf(context);
      if (shell != null) {
        shell.goToTab(AppTab.home, resetTab: shell.currentTab);
      }
    }
  }

  Widget _buildLaunch(BuildContext context) {
    final title = switch (widget.launch!) {
      PracticeLaunch.random => 'Random question',
      PracticeLaunch.quick10 => 'Quick 10',
      PracticeLaunch.timed => 'Timed quiz',
      PracticeLaunch.mistakes => 'Review mistakes',
      PracticeLaunch.topic => 'Practice by topic',
    };
    final package = widget.contentPackage;
    return AppScaffold(
      title: title,
      leading: CircleIconButton(
          icon: Icons.chevron_left_rounded,
          semanticLabel: 'Back',
          onPressed: () => Navigator.of(context).maybePop()),
      body: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
            widget.launch == PracticeLaunch.timed
                ? 'Up to 10 questions with an answering stopwatch. It pauses in the background and while you read explanations, and stops counting after two minutes without interaction. No automatic submission. Saved answer times return when you resume; time on an unfinished answer resets.'
                : widget.launch == PracticeLaunch.topic
                    ? 'Choose a topic for a focused session of up to 10 questions.'
                    : widget.launch == PracticeLaunch.mistakes
                        ? 'Practise questions you have previously answered incorrectly. Your earlier results stay unchanged.'
                        : 'Your session uses available questions and your current practice allowance.',
            style: context.textStyles.body),
        const SizedBox(height: 24),
        if (widget.launch == PracticeLaunch.topic && package != null) ...[
          for (final domain in package.exam.domains) ...[
            Text(domain.name, style: context.textStyles.h3),
            for (final topic in domain.topics)
              ListTile(
                  selected: _topicId == topic.id,
                  leading: Icon(_topicId == topic.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off),
                  title: Text(topic.name),
                  onTap: _starting
                      ? null
                      : () => setState(() {
                            _topicId = topic.id;
                            _domainId = domain.id;
                          })),
            const SizedBox(height: 16),
          ]
        ],
        if (_limitCheckFailed)
          const Text('Could not check your practice allowance. Please retry.'),
        if (_unavailableReason != null)
          Semantics(liveRegion: true, child: Text(_unavailableReason!)),
        const SizedBox(height: 16),
        PrimaryButton(
            label: _unavailableReason != null || _limitCheckFailed
                ? 'Retry'
                : 'Start $title',
            isLoading: _starting && !_choosingSession,
            onPressed: !_hasContent ||
                    widget.launch == PracticeLaunch.topic && _topicId == null
                ? null
                : _startOrResumePractice),
        if (!_hasContent)
          const Text('No approved questions are available yet.'),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocked = premiumBlock(context);
    if (blocked != null) return blocked;
    if (widget.launch != null) return _buildLaunch(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final ContentPackage? package = widget.contentPackage;
    return AppScaffold(
      leading: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Back',
      ),
      title: 'Practice setup',
      // The whole screen scrolls (rather than only the topics list, with
      // a fixed button pinned below it) so the button is never clipped
      // when its label wraps to multiple lines at large Dynamic Type
      // sizes on a small device.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MAKE IT YOURS', style: textStyles.label),
            const SizedBox(height: AppSpacing.md),
            const StudyPageHeading(
              title: 'Let’s practice.',
              subtitle: 'Choose a short session that fits your day.',
              icon: Icons.auto_stories_rounded,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('Session length', style: textStyles.h3),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
              for (final count in [5, 10, 20])
                ChoiceChip(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    selectedColor: colors.primaryContainer,
                    checkmarkColor: colors.onPrimaryContainer,
                    labelStyle: textStyles.body.copyWith(
                      color: _requestedCount == count
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: colors.surfaceContainer,
                    side: BorderSide(color: colors.outlineVariant),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    label: Text('$count questions'),
                    selected: _requestedCount == count,
                    onSelected: _starting
                        ? null
                        : (_) =>
                            _updateSelection(() => _requestedCount = count)),
            ]),
            const SizedBox(height: AppSpacing.xxl),
            Text('Focus', style: textStyles.h3),
            const SizedBox(height: AppSpacing.md),
            for (final entry in const {
              PracticeFocus.any: 'All questions',
              PracticeFocus.weakAreas: 'My weak areas',
              PracticeFocus.incorrectQuestions: 'Missed questions',
              PracticeFocus.bookmarkedQuestions: 'Saved questions',
            }.entries) ...[
              AppCard(
                  backgroundColor: _focus == entry.key
                      ? colors.primaryContainer
                      : colors.surfaceContainer,
                  selected: _focus == entry.key,
                  onTap: _starting
                      ? null
                      : () => _updateSelection(() => _focus = entry.key),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadii.smallIcon)),
                      child: Icon(
                          switch (entry.key) {
                            PracticeFocus.any => Icons.auto_stories_outlined,
                            PracticeFocus.weakAreas => Icons.insights_rounded,
                            PracticeFocus.incorrectQuestions =>
                              Icons.replay_rounded,
                            PracticeFocus.bookmarkedQuestions =>
                              Icons.bookmark_border_rounded,
                          },
                          color: colors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(entry.value, style: textStyles.h3)),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                        _focus == entry.key
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: colors.primary),
                  ])),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (package != null) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _domainId ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Topic'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All topics')),
                  for (final domain in package.exam.domains)
                    DropdownMenuItem(
                        value: domain.id, child: Text(domain.name)),
                ],
                onChanged: _starting
                    ? null
                    : (value) => _updateSelection(
                        () => _domainId = value == '' ? null : value),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Start Practice Exam',
              isLoading: _starting && !_choosingSession,
              onPressed: _hasContent ? _startOrResumePractice : null,
            ),
            if (!_hasContent) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Practice questions aren't available from here yet.",
                style: textStyles.bodySmall,
              ),
            ],
            if (_unavailableReason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              // A live region: unlike the static caption above (present
              // from this screen's very first frame), this one appears
              // only after the user taps Start — VoiceOver/TalkBack must
              // be told about it explicitly, not merely rely on it being
              // discoverable in the visual tree.
              Semantics(
                liveRegion: true,
                child: Text(
                  _unavailableReason!,
                  style: textStyles.bodySmall,
                ),
              ),
            ],
            if (_limitCheckFailed) ...[
              const SizedBox(height: AppSpacing.lg),
              ErrorState(
                title: "Can't check your practice limit",
                message: "We couldn't verify today's free practice "
                    'allowance. Please try again.',
                onRetry: _startOrResumePractice,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
