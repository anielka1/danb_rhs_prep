import 'package:flutter/material.dart';
import '../bootstrap/bootstrap_session_controller.dart';
import '../domain/models/study_plan_preferences.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/user_settings_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';

class StudyAvailabilityScreen extends StatefulWidget {
  const StudyAvailabilityScreen(
      {super.key,
      required this.session,
      this.repository,
      this.now = DateTime.now});
  final DateTime Function() now;
  final BootstrapSessionController session;
  final UserSettingsRepository? repository;
  @override
  State<StudyAvailabilityScreen> createState() =>
      _StudyAvailabilityScreenState();
}

class _StudyAvailabilityScreenState extends State<StudyAvailabilityScreen> {
  final Set<int> _days = {};
  int? _minutes;
  bool _review = false, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final prefs = widget.session.snapshot.profile?.studyPlanPreferences;
    if (prefs != null) {
      _days.addAll(prefs.weekdays);
      _minutes = prefs.minutes;
      _review = prefs.stage == StudyStage.mostlyReviewing;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = widget.repository ?? widget.session.userSettingsRepository;
      if (repo == null) throw StateError('Storage is unavailable');
      final snap = widget.session.snapshot;
      final previous = await repo.loadProfile(snap.selectedExamId);
      final date = snap.examDateSelection, experience = snap.experienceLevel;
      if (date == null || experience == null) {
        throw StateError('Complete your exam preferences first');
      }
      final profile = UserProfile.fromOnboarding(
              examId: snap.selectedExamId,
              experienceLevel: experience,
              examDateSelection: date,
              themePreference: snap.themePreference,
              now: widget.now(),
              existing: previous)
          .copyWith(
              studyPlanPreferences: StudyPlanPreferences(
                  weekdays: _days,
                  minutes: _minutes!,
                  stage: _review
                      ? StudyStage.mostlyReviewing
                      : StudyStage.learning));
      await repo.saveProfile(profile);
      widget.session.update(widget.session.snapshot.copyWith(profile: profile));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not save your availability. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
          body: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const BackButton(),
            Text('Make room for learning', style: context.textStyles.h1),
            const SizedBox(height: AppSpacing.md),
            Text(
                'Choose a routine that fits your week. Your previous progress and question goal stay saved.',
                style: context.textStyles.body),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Study days', style: context.textStyles.h3),
                  Wrap(spacing: AppSpacing.sm, children: [
                    for (var i = 1; i <= 7; i++)
                      FilterChip(
                          label: Text(const [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday'
                          ][i - 1]),
                          selected: _days.contains(i),
                          onSelected: _saving
                              ? null
                              : (selected) => setState(() =>
                                  selected ? _days.add(i) : _days.remove(i)))
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Time per study day', style: context.textStyles.h3),
                  Wrap(spacing: AppSpacing.sm, children: [
                    for (final minutes in [15, 30, 45])
                      ChoiceChip(
                          label: Text('$minutes min'),
                          selected: _minutes == minutes,
                          onSelected: _saving
                              ? null
                              : (_) => setState(() => _minutes = minutes))
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mostly reviewing'),
                      subtitle: const Text(
                          'I have studied the material before. This is separate from retaking the exam.'),
                      value: _review,
                      onChanged:
                          _saving ? null : (v) => setState(() => _review = v)),
                ])),
            const SizedBox(height: AppSpacing.xl),
            if (_error != null) Text(_error!, style: context.textStyles.body),
            PrimaryButton(
                label: 'Save availability',
                isLoading: _saving,
                onPressed: _days.isEmpty || _minutes == null ? null : _save),
          ])));
}
