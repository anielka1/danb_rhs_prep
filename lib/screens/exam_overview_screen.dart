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
import '../widgets/error_state.dart';
import '../widgets/primary_button.dart';
import 'practice_question_screen.dart';

class _Topic {
  final String title;
  final int questions;
  const _Topic(this.title, this.questions);
}

class ExamOverviewScreen extends StatefulWidget {
  static const String route = '/exam-overview';

  const ExamOverviewScreen({
    super.key,
    this.contentPackage,
    this.progressRepository,
    this.entitlement,
    this.now,
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

  // Topic names and per-topic question counts mirror the real DANB RHS exam
  // blueprint (see assets/content/danb_rhs/content.json) but are not yet
  // sourced from it — only 2 draft sample questions exist there so far.
  // Documented as a prototype placeholder pending real content authoring;
  // see docs/PROTOTYPE_CONTENT_AUDIT.md. Out of this task's scope, which
  // only wires the "Start Practice Exam" action itself to real state.
  static const List<_Topic> _topics = [
    _Topic('Radiation Physics & Characteristics', 15),
    _Topic('Radiation Biology & Safety', 25),
    _Topic('Radiation Protection Standards', 30),
    _Topic('Equipment Operation & Imaging', 20),
    _Topic('Patient Management & Procedures', 10),
  ];

  @override
  State<ExamOverviewScreen> createState() => _ExamOverviewScreenState();
}

class _ExamOverviewScreenState extends State<ExamOverviewScreen> {
  bool _starting = false;

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

  /// The question-set size for the single "Quick Practice" button.
  ///
  /// This is a current, deliberate product decision for this screen's one
  /// entry point — not a stand-in value that needs replacing — chosen as
  /// the middle of the 5/10/20 range `PracticeGenerator` itself already
  /// supports via `requestedCount`, so a meaningful session starts without
  /// assuming the larger 20 is always available or wanted. Letting the
  /// user pick 5/10/20 directly is a separate, later UI feature (a
  /// count-picker control), tracked apart from this ticket, not a
  /// prerequisite for this constant being correct today.
  static const int _defaultQuickPracticeCount = 10;

  bool get _hasContent =>
      widget.contentPackage != null &&
      widget.contentPackage!.questions.isNotEmpty;

  Future<void> _startOrResumePractice() async {
    if (_starting || !_hasContent) return;
    setState(() {
      _starting = true;
      _unavailableReason = null;
      _limitCheckFailed = false;
    });

    final ContentPackage package = widget.contentPackage!;
    final ProgressRepository? repository = widget.progressRepository;
    final String examId = package.exam.id;

    PracticeSession? existing;
    if (repository != null) {
      try {
        existing = await repository.inProgressPracticeSession(examId);
      } catch (_) {
        existing = null;
      }
    }

    final PracticeSession session;
    if (existing != null) {
      session = existing;
    } else {
      // No progress history is threaded in for this default "Quick
      // Practice" entry point — PracticeFocus.any never reads it. A future
      // weak-areas/incorrect-questions picker UI would fetch real
      // QuestionState history before calling this.
      int? maxCount;
      if (widget.entitlement != null && repository != null) {
        final DateTime nowValue = (widget.now ?? DateTime.now)();
        if (widget.entitlement!.isActiveAt(nowValue)) {
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
              entitlement: widget.entitlement!,
              now: nowValue,
              answeredToday: answeredToday,
              dailyLimit: package.exam.freeTier.dailyPracticeQuestions,
            );
          } catch (_) {
            // Fail CLOSED, not open: a free user's limit demonstrably
            // applies here, it simply couldn't be checked — unlike
            // history-read failures elsewhere in this method (resuming,
            // saving), which are allowed to be best-effort because
            // nothing they guard is a hard business rule. Silently
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
          questionStates: const [],
          requestedCount: _defaultQuickPracticeCount,
          maxCount: maxCount,
        );
      } on PracticeGenerationUnavailable catch (error) {
        if (!mounted) return;
        setState(() {
          _starting = false;
          _unavailableReason = error.message;
        });
        return;
      }
      session = PracticeSession(
        id: 'practice-$examId-${DateTime.now().toUtc().microsecondsSinceEpoch}',
        examId: examId,
        mode: PracticeMode.quickPractice,
        questionIds: generator.questions.map((q) => q.id).toList(),
        status: SessionStatus.inProgress,
        startedAt: DateTime.now().toUtc(),
        contentVersion: package.contentVersion,
      );
    }

    if (existing == null && repository != null) {
      try {
        await repository.savePracticeSession(session);
      } catch (_) {
        // Best-effort: an unsaved session still runs fully in-memory below.
      }
    }

    final List<Question> byId = package.questions;
    final List<Question> questions = [
      for (final id in session.questionIds) byId.firstWhere((q) => q.id == id),
    ];

    // A resumed session (PREP-665) needs its per-question answered state
    // restored from repository history — the plain constructor always
    // starts empty, which is only correct for the brand-new-session
    // branch below. See PracticeSessionController.resume's own doc
    // comment.
    final PracticeSessionController controller =
        existing != null && repository != null
            ? await PracticeSessionController.resume(
                session: session,
                questions: questions,
                progressRepository: repository,
              )
            : PracticeSessionController(
                session: session,
                questions: questions,
                progressRepository: repository,
              );

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
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return AppScaffold(
      leading: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Back',
      ),
      title: 'Exam Info',
      // The whole screen scrolls (rather than only the topics list, with
      // a fixed button pinned below it) so the button is never clipped
      // when its label wraps to multiple lines at large Dynamic Type
      // sizes on a small device.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Practice Exam Prep', style: textStyles.h2),
                  const SizedBox(height: 6),
                  Text(
                    '1.5 Hours · 100 Questions · Intermediate',
                    style: textStyles.body.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text('About Certification', style: textStyles.h3),
            const SizedBox(height: 10),
            Text(
              'This simulator prepares you comprehensively for the official '
              'Dental Assisting National Board Radiation Health & Safety exam. '
              'Complete each module with 80% correct score.',
              style: textStyles.body,
            ),
            const SizedBox(height: 26),
            Text('Topics Covered', style: textStyles.h3),
            const SizedBox(height: AppSpacing.md + 2),
            ...ExamOverviewScreen._topics.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _TopicRow(topic: t),
                )),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Start Practice Exam',
              isLoading: _starting,
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

class _TopicRow extends StatelessWidget {
  final _Topic topic;
  const _TopicRow({required this.topic});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          // No per-topic unlock/completion tracking exists yet — every
          // topic uses the same neutral icon rather than a fake locked or
          // completed state. See docs/PROTOTYPE_CONTENT_AUDIT.md.
          child: Icon(
            Icons.menu_book_rounded,
            size: AppIconSize.small + 2,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.onSurface),
              ),
              const SizedBox(height: 2),
              Text('${topic.questions} Questions',
                  style: context.textStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
