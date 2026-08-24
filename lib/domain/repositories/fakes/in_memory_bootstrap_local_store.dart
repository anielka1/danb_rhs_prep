import '../../models/entitlement.dart';
import '../../models/exam_date_selection.dart';
import '../../models/readiness_snapshot.dart';
import '../../models/user_profile.dart';
import '../bootstrap_local_store.dart';

/// An in-memory [BootstrapLocalStore] for unit tests and previews.
/// Optional constructor arguments pre-seed a starting value for each key,
/// synchronously — convenient for a test that wants to start from "a
/// returning user" (e.g. `onboardingComplete: true`) without awaiting a
/// separate write first.
class InMemoryBootstrapLocalStore implements BootstrapLocalStore {
  InMemoryBootstrapLocalStore({
    String? selectedExamId,
    bool? onboardingComplete,
    ThemePreference? themePreference,
    Entitlement? entitlement,
    ReadinessSnapshot? readinessSnapshot,
    ExamDateSelection? examDateSelection,
  })  : _selectedExamId = selectedExamId,
        _onboardingComplete = onboardingComplete,
        _themePreference = themePreference,
        _entitlement = entitlement,
        _examDateSelection = examDateSelection {
    if (readinessSnapshot != null) {
      _readinessByExam[readinessSnapshot.examId] = readinessSnapshot;
    }
  }

  String? _selectedExamId;
  bool? _onboardingComplete;
  ThemePreference? _themePreference;
  Entitlement? _entitlement;
  ExamDateSelection? _examDateSelection;
  final Map<String, ReadinessSnapshot> _readinessByExam = {};

  @override
  Future<String?> readSelectedExamId() async => _selectedExamId;

  @override
  Future<void> writeSelectedExamId(String examId) async {
    _selectedExamId = examId;
  }

  @override
  Future<bool?> readOnboardingComplete() async => _onboardingComplete;

  @override
  Future<void> writeOnboardingComplete(bool complete) async {
    _onboardingComplete = complete;
  }

  @override
  Future<ThemePreference?> readThemePreference() async => _themePreference;

  @override
  Future<void> writeThemePreference(ThemePreference preference) async {
    _themePreference = preference;
  }

  @override
  Future<Entitlement?> readEntitlementSnapshot() async => _entitlement;

  @override
  Future<void> writeEntitlementSnapshot(Entitlement entitlement) async {
    _entitlement = entitlement;
  }

  @override
  Future<ReadinessSnapshot?> readLatestReadinessSnapshot(
    String examId,
  ) async {
    return _readinessByExam[examId];
  }

  @override
  Future<void> writeLatestReadinessSnapshot(ReadinessSnapshot snapshot) async {
    _readinessByExam[snapshot.examId] = snapshot;
  }

  @override
  Future<ExamDateSelection?> readExamDateSelection() async =>
      _examDateSelection;

  @override
  Future<void> writeExamDateSelection(ExamDateSelection selection) async {
    _examDateSelection = selection;
  }
}
