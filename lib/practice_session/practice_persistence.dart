import '../domain/models/answer_attempt.dart';
import '../domain/models/practice_session.dart';
import '../domain/repositories/progress_repository.dart';

/// In-session retry queue. Exact attempt IDs/payloads are retained so the
/// repository's idempotent recording also handles a write whose response failed.
/// Nothing here survives process exit; the UI must disclose outstanding saves.
class PracticePersistence {
  PracticePersistence(this.repository);
  final ProgressRepository? repository;
  final Map<String, AnswerAttempt> _attempts = {};
  final Map<(String, String), bool> _bookmarks = {};
  PracticeSession? _session;
  Future<void> _tail = Future.value();
  bool _failed = false;

  bool get hasUnsavedChanges =>
      _failed &&
      (_session != null || _attempts.isNotEmpty || _bookmarks.isNotEmpty);

  Future<void> saveAttempt(AnswerAttempt attempt) {
    if (repository == null) return Future.value();
    _attempts[attempt.id] = attempt;
    return retry();
  }

  Future<void> saveBookmark(String examId, String questionId, bool value) {
    if (repository == null) return Future.value();
    _bookmarks[(examId, questionId)] = value;
    return retry();
  }

  Future<void> saveSession(PracticeSession session) {
    if (repository == null) return Future.value();
    _session = session;
    return retry();
  }

  Future<void> retry() {
    // Serializes bookmark read-modify-write with answer aggregation. A later
    // bookmark write reads the newly stored totals instead of overwriting them.
    _tail = _tail.then((_) => _flush());
    return _tail;
  }

  Future<void> _flush() async {
    final repo = repository;
    if (repo == null) return;
    try {
      final session = _session;
      if (session != null) {
        await repo.savePracticeSession(session);
        if (identical(_session, session)) _session = null;
      }
      // Stop on the first failure so a later answer is never saved ahead
      // of an older failed answer in this controller.
      for (final attempt in _attempts.values.toList()) {
        await repo.recordAnswerAttempt(attempt);
        _attempts.remove(attempt.id);
      }
      for (final entry in _bookmarks.entries.toList()) {
        final (examId, questionId) = entry.key;
        final current = await repo.questionState(examId, questionId);
        await repo.saveQuestionState(current.copyWith(bookmarked: entry.value));
        if (_bookmarks[entry.key] == entry.value) _bookmarks.remove(entry.key);
      }
      _failed = false;
    } on Object {
      _failed = true;
    }
  }
}
