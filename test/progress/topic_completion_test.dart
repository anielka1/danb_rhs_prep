import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/domain/models/question_state.dart';
import 'package:danb_rhs_prep/progress/topic_completion.dart';
import '../study_plan/fixtures.dart';

void main() {
  test('distinct answers survive database reopening, regardless of grade',
      () async {
    final dir = await Directory.systemTemp.createTemp('topic-progress-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/progress.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftProgressRepository(db);
    final package = fixture(count: 4);
    final questions = package.questions
        .where((q) => q.topicId == package.questions.first.topicId)
        .toList();
    var state = QuestionState.unseen(
        examId: package.exam.id, questionId: questions.first.id);
    for (var i = 0; i < 3; i++) {
      state =
          state.withAttempt(isCorrect: false, answeredAt: DateTime.utc(2026));
    }
    await repo.saveQuestionState(state);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftProgressRepository(db);
    addTearDown(db.close);
    var progress = TopicCompletion(
        package, await repo.questionStatesForExam(package.exam.id));
    expect(progress.completed[questions.first.topicId], 1);
    expect(progress.status(questions.first.topicId), 'In progress');
    await repo.saveQuestionState(QuestionState.unseen(
            examId: package.exam.id, questionId: questions.last.id)
        .withAttempt(isCorrect: false, answeredAt: DateTime.utc(2026)));
    progress = TopicCompletion(
        package, await repo.questionStatesForExam(package.exam.id));
    expect(progress.status(questions.first.topicId), 'Completed');
  });
}
