import 'dart:convert';

/// Stable names are persisted; retaking an exam remains separate from stage.
enum StudyStage { learning, mostlyReviewing }

class StudyPlanPreferences {
  StudyPlanPreferences(
      {required Iterable<int> weekdays,
      required this.minutes,
      this.stage = StudyStage.learning})
      : weekdays = Set.unmodifiable(weekdays) {
    if (this.weekdays.isEmpty ||
        this.weekdays.any((d) => d < 1 || d > 7) ||
        !const [15, 30, 45].contains(minutes)) {
      throw ArgumentError(
          'Choose at least one weekday and 15, 30 or 45 minutes.');
    }
  }
  final Set<int> weekdays;
  final int minutes;
  final StudyStage stage;
  String encode() => jsonEncode({
        'version': 1,
        'weekdays': weekdays.toList()..sort(),
        'minutes': minutes,
        'stage': stage.name
      });
  static StudyPlanPreferences? decode(String? raw) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['version'] != 1) return null;
      return StudyPlanPreferences(
          weekdays: (data['weekdays'] as List).cast<int>(),
          minutes: data['minutes'] as int,
          stage: StudyStage.values.firstWhere((s) => s.name == data['stage'],
              orElse: () => StudyStage.learning));
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is StudyPlanPreferences && encode() == other.encode();
  @override
  int get hashCode => encode().hashCode;
}
