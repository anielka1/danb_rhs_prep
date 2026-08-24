import '../models/entitlement.dart';
import '../models/exam_date_selection.dart';
import '../models/readiness_snapshot.dart';
import '../models/user_profile.dart';

/// A small local key-value cache for the handful of fields app startup
/// needs before any full persistence layer exists (Phase 5 assigns real
/// `ContentRepository`/`ProgressRepository`/`UserSettingsRepository`
/// implementations; nothing here duplicates that work).
///
/// Deliberately narrow: only the selected exam, whether onboarding is
/// complete, the theme preference, the last known entitlement snapshot,
/// and the latest readiness snapshot — never full practice history,
/// answer attempts, or question state, which belong in a real database,
/// not a preferences store.
///
/// Every read is nullable and every method is independent: a missing or
/// corrupt value for one key must never prevent reading (or writing) any
/// other key, and must never crash startup.
abstract interface class BootstrapLocalStore {
  Future<String?> readSelectedExamId();
  Future<void> writeSelectedExamId(String examId);

  Future<bool?> readOnboardingComplete();
  Future<void> writeOnboardingComplete(bool complete);

  Future<ThemePreference?> readThemePreference();
  Future<void> writeThemePreference(ThemePreference preference);

  /// The last locally-cached entitlement snapshot, if any. Nothing
  /// currently writes one in production (Phase 9 adds real StoreKit
  /// verification) — always absent today, which is the correct, honest
  /// state for a user who has never purchased premium.
  ///
  /// This value is a cache only, never authoritative: it is plain,
  /// user-editable local storage, not a verified receipt. Callers must
  /// treat a missing, corrupt, or expired value as free tier and must
  /// never claim a purchase was "verified" from this alone.
  Future<Entitlement?> readEntitlementSnapshot();
  Future<void> writeEntitlementSnapshot(Entitlement entitlement);

  /// The most recently calculated readiness snapshot for [examId], if
  /// any. Nothing currently writes one in production (Phase 7 adds the
  /// readiness algorithm) — always absent today.
  Future<ReadinessSnapshot?> readLatestReadinessSnapshot(String examId);
  Future<void> writeLatestReadinessSnapshot(ReadinessSnapshot snapshot);

  /// The onboarding exam-date screen's saved selection, if any — stored
  /// and read as one atomic value (precision and date together), never
  /// as separate keys that could drift apart from each other or be read
  /// half-written. Like every other key here: a missing or corrupt value
  /// returns null rather than throwing, and never affects any other key.
  Future<ExamDateSelection?> readExamDateSelection();
  Future<void> writeExamDateSelection(ExamDateSelection selection);
}
