import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:danb_rhs_prep/data/local/app_database.dart';
import 'package:danb_rhs_prep/data/repositories/drift_progress_repository.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_blueprint.dart';
import 'package:danb_rhs_prep/mock_exam/mock_exam_controller.dart';
import 'package:danb_rhs_prep/practice_session/practice_session_controller.dart';
import '../../support/mock_exam_test_support.dart';
import '../../support/controlled_random.dart';

void main() {
  test(
      'frozen schema 4 -> 5 preserves every row and legacy active answer order',
      () async {
    final dir = Directory.systemTemp.createTempSync('migration-v5');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final old = sqlite3.open(file.path);
    old.execute(File('test/data/local/schema_v4.sql').readAsStringSync());
    final package = mockPackage();
    final ids = jsonEncode(package.questions.map((q) => q.id).toList());
    old.execute(
        "INSERT INTO practice_sessions VALUES ('2026-09-11','[]','practice','demo_exam','quickPractice',?,'inProgress',100,NULL,'demo-1')",
        [ids]);
    for (final completed in [false, true]) {
      old.execute(
          'INSERT INTO mock_attempts VALUES (2,?,?,?, ?,?, ?,100,10,0,?, ?,?)',
          [
            completed ? 'done' : 'active',
            'demo_exam',
            ids,
            '{"demo-question-1":"a"}',
            '["demo-question-1"]',
            completed ? 'completed' : 'inProgress',
            'demo-1',
            completed ? 200 : null,
            completed ? 1 : null
          ]);
    }
    old.execute(
        "INSERT INTO answer_attempts VALUES (1,12,'2026-09-11','answer','demo_exam','demo-question-1','demo_domain','demo_topic',1,'practice','practice','a',1,100,'demo-1',1,'a','Historical explanation')");
    old.execute(
        "INSERT INTO question_states VALUES ('demo_exam','demo-question-1',1,1,1,0,1,100)");
    old.execute(
        "INSERT INTO study_schedules VALUES ('demo_exam','2026-09-12','mock',30,'[]')");
    old.execute(
        "INSERT INTO user_profiles VALUES (NULL,'demo_exam','beginner','unknown',NULL,10,0,'system',1,100,100)");
    old.execute(
        "INSERT INTO readiness_snapshots VALUES ('snapshot','demo_exam',100,40,'low',40,40,40,40,40,0.5,1)");
    final tables = old
        .select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
        .map((r) => r['name'] as String)
        .toList();
    final before = {
      for (final table in tables)
        table: old
            .select('SELECT * FROM $table')
            .map((r) => Map<String, dynamic>.from(r))
            .toList()
    };
    old.dispose();
    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    for (final table in tables) {
      final rows = await db.customSelect('SELECT * FROM $table').get();
      final after = rows
          .map((r) =>
              Map<String, dynamic>.from(r.data)..remove('answer_order_json'))
          .toList();
      expect(after, before[table],
          reason: 'All historical columns of $table survive unchanged');
    }
    expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .data
            .values
            .single,
        5);
    final repo = DriftProgressRepository(db);
    final session = (await repo.inProgressPracticeSession('demo_exam'))!;
    expect(session.answerOrder, isNull);
    final practice = await PracticeSessionController.resume(
        session: session,
        questions: package.questions,
        progressRepository: repo);
    expect(practice.questions.first.answers.map((a) => a.id),
        package.questions.first.answers.map((a) => a.id));
    expect(practice.answeredCount, 1);
    final mock = MockExamController(
        blueprint: MockExamBlueprint.fromPackage(package),
        repository: repo,
        random: ControlledRandom(forbid: true));
    await mock.load();
    await mock.start();
    expect(mock.attempt!.answerOrder, isNull);
    expect(mock.currentQuestion.answers.map((a) => a.id),
        package.questions.first.answers.map((a) => a.id));
    await mock.answer('b');
    expect((await repo.mockAttempt('active'))!.answerOrder, isNull);
    expect((await repo.mockAttempt('done'))!.correctCount, 1);
    expect((await repo.answerAttemptsForExam('demo_exam')).single.explanation,
        'Historical explanation');
  });
}
