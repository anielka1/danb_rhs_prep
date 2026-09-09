import 'package:flutter/material.dart';
import '../practice_session/practice_session_controller.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'app_dialog.dart';
import 'primary_button.dart';

Future<bool> confirmLeavingUnsavedPractice(
    BuildContext context, PracticeSessionController controller) async {
  if (!controller.hasUnsavedChanges) return true;
  return await AppDialog.show<bool>(
        context: context,
        title: 'Leave without saving?',
        message:
            'Some progress is not saved on this device. Stay here to retry. Leaving may lose those changes.',
        actions: const [
          AppDialogAction(
              label: 'Stay here',
              value: false,
              style: AppDialogActionStyle.cancel),
          AppDialogAction(
              label: 'Leave without saving',
              value: true,
              style: AppDialogActionStyle.destructive),
        ],
      ) ??
      false;
}

/// Only shown after a storage failure; retries the retained writes rather
/// than submitting the answer again or recalculating the session result.
class PracticeSaveStatus extends StatefulWidget {
  const PracticeSaveStatus({super.key, required this.controller});
  final PracticeSessionController controller;

  @override
  State<PracticeSaveStatus> createState() => _PracticeSaveStatusState();
}

class _PracticeSaveStatusState extends State<PracticeSaveStatus> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    await widget.controller.retrySaving();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.hasUnsavedChanges && !_retrying) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: AppCard(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Some progress is not saved yet',
                style: context.textStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
                'Your changes are kept in this session. Retry before leaving or closing the app.',
                style: context.textStyles.bodySmall),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
                label: 'Retry saving', onPressed: _retrying ? null : _retry),
            if (_retrying) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Saving…', style: context.textStyles.bodySmall),
            ],
          ],
        )),
      ),
    );
  }
}
