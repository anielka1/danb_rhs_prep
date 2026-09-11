import 'controlled_random.dart';
import 'dart:async';
import 'package:danb_rhs_prep/debug/debug_demo_environment.dart';
import 'package:danb_rhs_prep/domain/models/mock_attempt.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_progress_repository.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/features/exams/domain/exam_config.dart';
import 'package:danb_rhs_prep/features/questions/domain/question.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';

ContentPackage mockPackage(
    {List<Question>? questions,
    List<DomainConfig>? domains,
    int count = 5,
    bool timed = false,
    bool back = true,
    double threshold = 70,
    String version = 'demo-1'}) {
  final base = DebugDemoEnvironment.demoContentPackage;
  final exam = base.exam;
  return ContentPackage(
      contentVersion: version,
      sourceVersion: base.sourceVersion,
      generatedAt: base.generatedAt,
      questions: questions ?? base.questions,
      exam: ExamConfig(
          id: exam.id,
          name: exam.name,
          provider: exam.provider,
          examVersion: exam.examVersion,
          contentVersion: version,
          domains: domains ?? exam.domains,
          mockExam: MockExamConfig(
              questionCount: count,
              durationMinutes: 10,
              practicePassingPercent: threshold,
              allowsBackNavigation: back,
              timed: timed),
          officialScoring: exam.officialScoring,
          readiness: exam.readiness,
          subscriptionProductIds: exam.subscriptionProductIds,
          freeTier: exam.freeTier,
          disclaimer: exam.disclaimer));
}

Question mockQuestion(
    {String id = 'demo-question-1',
    String domain = 'demo_domain',
    String topic = 'demo_topic',
    List<Answer>? answers,
    String correct = 'a',
    List<String> tags = const ['demo'],
    String text = '[Demo] What is 2 + 2?'}) {
  final base = DebugDemoEnvironment.demoQuestions.first;
  return Question(
      id: id,
      examId: base.examId,
      domainId: domain,
      topicId: topic,
      questionText: text,
      answers: answers ?? base.answers,
      correctAnswerId: correct,
      explanation: base.explanation,
      references: base.references,
      difficulty: base.difficulty,
      status: base.status,
      version: base.version,
      updatedAt: base.updatedAt,
      sourceVersion: base.sourceVersion,
      tags: tags);
}

class ControlledMockRepository extends InMemoryProgressRepository {
  bool failLoad = false;
  bool failSave = false;
  int saveCalls = 0;
  int loadCalls = 0;
  Completer<void>? saveGate;
  Completer<void>? loadGate;

  @override
  Future<void> saveMockAttempt(MockAttempt attempt) async {
    saveCalls++;
    await saveGate?.future;
    if (failSave) throw StateError('private storage diagnostic');
    await super.saveMockAttempt(attempt);
  }

  @override
  Future<List<MockAttempt>> mockAttemptsForExam(String examId) async {
    loadCalls++;
    await loadGate?.future;
    if (failLoad) throw StateError('private storage diagnostic');
    return super.mockAttemptsForExam(examId);
  }
}

Future<MockExamController> startedMock(
    {ControlledMockRepository? repository,
    ContentPackage? package,
    DateTime Function()? now}) async {
  final controller = MockExamController(
      blueprint: MockExamBlueprint.fromPackage(package ?? mockPackage()),
      repository: repository ?? ControlledMockRepository(),
      random: ControlledRandom(),
      now: now ?? () => DateTime.utc(2026, 1, 1, 12));
  await controller.load();
  await controller.start();
  return controller;
}
