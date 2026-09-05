import 'package:flutter/material.dart';
import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';
import '../features/content/domain/content_package.dart';
import '../features/questions/domain/question.dart';
import '../practice_session/practice_session_controller.dart';
import '../practice_session/practice_session_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
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

  /// Null in production (no real adapter exists yet) — the session still
  /// starts and is fully interactive, just not persisted/resumable. See
  /// `PracticeSessionController`'s doc comment.
  final ProgressRepository? progressRepository;

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

  bool get _hasContent =>
      widget.contentPackage != null &&
      widget.contentPackage!.questions.isNotEmpty;

  Future<void> _startOrResumePractice() async {
    if (_starting || !_hasContent) return;
    setState(() => _starting = true);

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

    final PracticeSession session = existing ??
        PracticeSession(
          id: 'practice-$examId-${DateTime.now().toUtc().microsecondsSinceEpoch}',
          examId: examId,
          mode: PracticeMode.quickPractice,
          questionIds: package.questions.map((q) => q.id).toList(),
          status: SessionStatus.inProgress,
          startedAt: DateTime.now().toUtc(),
        );

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

    final PracticeSessionController controller = PracticeSessionController(
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
