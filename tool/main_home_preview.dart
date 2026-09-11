// Isolated debug-only web preview of the real shell. No production storage.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_controller.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_precision.dart';
import 'package:danb_rhs_prep/domain/models/exam_date_selection.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_user_settings_repository.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/exam_date_screen.dart';
import 'package:danb_rhs_prep/screens/profile_settings_screen.dart';
import 'package:danb_rhs_prep/services/theme_mode_controller.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/domain/models/answer_attempt.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';

Future<void> main() async {
  if (!kDebugMode) throw UnsupportedError('Home preview requires debug mode.');
  WidgetsFlutterBinding.ensureInitialized();
  final package = fixtureFromJson(
      jsonDecode(await rootBundle.loadString(
          'assets/content/danb_rhs/content.json')) as Map<String, dynamic>,
      count: 200);
  final repo = InMemoryProgressRepository();
  final now = DateTime.now();
  await repo
      .recordAnswerAttempt(answer(package.questions.first, now, seconds: 43));
  await repo.recordAnswerAttempt(
      answer(package.questions[1], now, correct: false, seconds: 62));
  await repo.recordAnswerAttempt(answer(
      package.questions[2], now.subtract(const Duration(days: 1)),
      seconds: 90));
  final date = ExamDateSelection(
      precision: ExamDatePrecision.exact,
      date: DateTime(now.year, now.month, now.day + 30));
  final local = InMemoryBootstrapLocalStore(
      onboardingComplete: true, examDateSelection: date);
  final settings = InMemoryUserSettingsRepository();
  final controller = BootstrapSessionController(
      BootstrapReady(
          profile: null,
          selectedExamId: package.exam.id,
          contentPackage: package,
          themePreference: ThemePreference.system,
          readinessSnapshot: null,
          entitlement: Entitlement.free(lastVerifiedAt: now),
          onboardingComplete: true,
          examDateSelection: date,
          experienceLevel: null),
      progressRepository: repo,
      userSettingsRepository: settings);
  final dark = Uri.base.queryParameters['theme'] == 'dark';
  final scale = double.tryParse(Uri.base.queryParameters['scale'] ?? '') ?? 1;
  runApp(MaterialApp(
    debugShowCheckedModeBanner: true,
    theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!),
    routes: {
      '/settings/exam-date': (_) => BootstrapSessionScope(
          controller: controller,
          child: ExamDateScreen(
              localStore: local,
              userSettingsRepository: settings,
              editing: true)),
      ProfileSettingsScreen.route: (_) => ProfileSettingsScreen(
          themeModeController: ThemeModeController(),
          session: controller,
          localStore: local,
          userSettingsRepository: settings),
    },
    home: BootstrapSessionScope(
        controller: controller, child: MainShell(progressRepository: repo)),
  ));
}

ContentPackage fixtureFromJson(Map<String, dynamic> raw,
    {int count = 80, QuestionStatus status = QuestionStatus.approved}) {
  final exam = ExamConfig.fromJson(raw['exam'] as Map<String, dynamic>);
  final questions = <Question>[];
  for (var i = 0; i < count; i++) {
    final domain = exam.domains[i % 4 < 2 ? 0 : i % 4 - 1];
    questions.add(Question(
        id: 'fixture-$i',
        examId: exam.id,
        domainId: domain.id,
        topicId: domain.topics[(i ~/ 4) % domain.topics.length].id,
        questionText: 'Synthetic test question number $i?',
        answers: const [
          Answer(id: 'a', text: 'Correct fixture answer'),
          Answer(id: 'b', text: 'Alternative one'),
          Answer(id: 'c', text: 'Alternative two'),
          Answer(id: 'd', text: 'Alternative three')
        ],
        correctAnswerId: 'a',
        explanation:
            'Synthetic explanation used exclusively to verify the application behavior in tests.',
        references: const [
          QuestionReference(
              title: 'Fixture reference',
              source: 'Test source',
              section: 'Test section')
        ],
        difficulty: i % 5 + 1,
        status: status,
        version: 1,
        updatedAt: DateTime.utc(2026, 1, 1),
        sourceVersion: exam.contentVersion,
        tags: const ['test-fixture']));
  }
  return ContentPackage(
      exam: exam,
      contentVersion: exam.contentVersion,
      sourceVersion: raw['sourceVersion'] as String,
      generatedAt: DateTime.utc(2026, 1, 1),
      questions: questions);
}

AnswerAttempt answer(Question q, DateTime day,
        {String? id,
        bool correct = true,
        bool? confident,
        int? seconds,
        String? localDay}) =>
    AnswerAttempt(
        id: id ?? '${q.id}-${day.toIso8601String()}',
        examId: q.examId,
        questionId: q.id,
        domainId: q.domainId,
        topicId: q.topicId,
        difficulty: q.difficulty,
        sessionId: 'session-${day.day}',
        sessionType: AttemptSessionType.practice,
        selectedAnswerId: correct ? 'a' : 'b',
        isCorrect: correct,
        answeredAt: day,
        confident: confident,
        activeDurationSeconds: seconds,
        localAnsweredDate: localDay ?? day.toIso8601String().substring(0, 10),
        questionVersion: 1,
        correctAnswerId: 'a',
        explanation: q.explanation,
        contentVersion: 'fixture');
