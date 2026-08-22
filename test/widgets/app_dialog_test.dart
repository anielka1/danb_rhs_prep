import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/widgets/app_dialog.dart';

enum _SignOutChoice { confirm, cancel }

void main() {
  Widget wrap(TargetPlatform platform, Widget child) {
    return MaterialApp(
      theme: ThemeData(platform: platform),
      home: Scaffold(body: child),
    );
  }

  Widget triggerButton(void Function(_SignOutChoice? result) onResult) {
    return Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          final result = await AppDialog.show<_SignOutChoice>(
            context: context,
            title: 'Sign Out',
            message: 'Are you sure you want to sign out?',
            actions: const [
              AppDialogAction(
                  label: 'Cancel',
                  value: _SignOutChoice.cancel,
                  style: AppDialogActionStyle.cancel),
              AppDialogAction(
                label: 'Sign Out',
                value: _SignOutChoice.confirm,
                style: AppDialogActionStyle.destructive,
              ),
            ],
          );
          onResult(result);
        },
        child: const Text('Open'),
      ),
    );
  }

  group('Material presentation (non-Apple platforms)', () {
    testWidgets('shows an AlertDialog with title, message and actions',
        (tester) async {
      _SignOutChoice? result;
      await tester.pumpWidget(
          wrap(TargetPlatform.android, triggerButton((r) => result = r)));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(find.text('Sign Out'), findsWidgets);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, _SignOutChoice.cancel);
    });

    testWidgets('destructive action uses the error color', (tester) async {
      await tester
          .pumpWidget(wrap(TargetPlatform.android, triggerButton((_) {})));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final TextButton destructiveButton = tester.widget(
        find.ancestor(
            of: find.text('Sign Out').last, matching: find.byType(TextButton)),
      );
      final ColorScheme colors =
          Theme.of(tester.element(find.byType(AlertDialog))).colorScheme;
      expect(destructiveButton.style?.foregroundColor?.resolve(<WidgetState>{}),
          colors.error);
    });

    testWidgets('returns the typed value of the tapped action', (tester) async {
      _SignOutChoice? result;
      await tester.pumpWidget(
          wrap(TargetPlatform.android, triggerButton((r) => result = r)));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      expect(result, _SignOutChoice.confirm);
    });

    testWidgets('barrier dismissal resolves to null when allowed',
        (tester) async {
      _SignOutChoice? result = _SignOutChoice.cancel;
      await tester.pumpWidget(
          wrap(TargetPlatform.android, triggerButton((r) => result = r)));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap outside the dialog to dismiss via the barrier.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(result, isNull);
    });
  });

  group('Cupertino presentation (iOS/macOS)', () {
    testWidgets('shows a CupertinoAlertDialog with title, message and actions',
        (tester) async {
      await tester.pumpWidget(wrap(TargetPlatform.iOS, triggerButton((_) {})));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
    });

    testWidgets('destructive action is marked isDestructiveAction',
        (tester) async {
      await tester.pumpWidget(wrap(TargetPlatform.iOS, triggerButton((_) {})));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final CupertinoDialogAction action = tester.widget(
        find.ancestor(
            of: find.text('Sign Out').last,
            matching: find.byType(CupertinoDialogAction)),
      );
      expect(action.isDestructiveAction, isTrue);
    });

    testWidgets(
        'cancel action is marked isDefaultAction and returns its typed value',
        (tester) async {
      _SignOutChoice? result;
      await tester.pumpWidget(
          wrap(TargetPlatform.iOS, triggerButton((r) => result = r)));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final CupertinoDialogAction action = tester.widget(
        find.ancestor(
            of: find.text('Cancel'),
            matching: find.byType(CupertinoDialogAction)),
      );
      expect(action.isDefaultAction, isTrue);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, _SignOutChoice.cancel);
    });
  });

  testWidgets('a non-dismissible dialog is not closed by tapping the barrier',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        TargetPlatform.android,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AppDialog.show<void>(
              context: context,
              title: 'Processing',
              actions: const [AppDialogAction(label: 'OK', value: null)],
              barrierDismissible: false,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
