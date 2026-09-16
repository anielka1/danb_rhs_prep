import 'dart:convert';
import '../../domain/models/answer_attempt.dart';
import '../../subscription/free_practice_store.dart';
import '../local/app_database.dart';

/// Separate from deletable learning history. All writes use the same database
/// transaction as the answer/QuestionState write, including idempotent retries.
class DriftFreePracticeStore implements FreePracticeStore {
  DriftFreePracticeStore(this.db);
  final AppDatabase db;
  Future<Map<String, dynamic>> _data() async {
    final row = await db
        .customSelect('SELECT payload FROM free_practice_trial WHERE id = 1')
        .getSingleOrNull();
    return row == null
        ? <String, dynamic>{}
        : jsonDecode(row.read<String>('payload')) as Map<String, dynamic>;
  }

  Future<void> _save(Map<String, dynamic> data) => db.customStatement(
      'INSERT OR REPLACE INTO free_practice_trial (id, payload) VALUES (1, ?)',
      [jsonEncode(data)]);
  @override
  Future<FreePracticeState> read() async {
    final data = await _data();
    return FreePracticeState(
        answeredCount: (data['attempts'] as List? ?? []).length,
        completionPaywallShown: data['completionPaywallShown'] == true,
        sessionIds: Set<String>.from(data['sessions'] as List? ?? []));
  }

  @override
  Future<void> registerSession(String id) => db.transaction(() async {
        final data = await _data();
        final sessions = Set<String>.from(data['sessions'] as List? ?? []);
        sessions.add(id);
        data['sessions'] = sessions.toList();
        await _save(data);
      });
  @override
  Future<void> record(
          AnswerAttempt attempt, Future<void> Function() writeAnswer) =>
      db.transaction(() async {
        final data = await _data();
        final attempts = List<String>.from(data['attempts'] as List? ?? []);
        if (!List<String>.from(data['sessions'] as List? ?? [])
            .contains(attempt.sessionId)) {
          throw StateError('Trial session unavailable');
        }
        if (!attempts.contains(attempt.id) && attempts.length >= 5) {
          throw StateError('Free practice completed');
        }
        await writeAnswer();
        if (!attempts.contains(attempt.id)) attempts.add(attempt.id);
        data['attempts'] = attempts;
        data['answeredCount'] = attempts.length;
        data['trialCompleted'] = attempts.length >= 5;
        await _save(data);
      });
  @override
  Future<void> markCompletionPaywallShown() => db.transaction(() async {
        final data = await _data();
        data['completionPaywallShown'] = true;
        await _save(data);
      });
}
