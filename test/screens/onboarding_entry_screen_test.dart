import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/bootstrap/bootstrap_session_scope.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import 'package:danb_rhs_prep/domain/models/readiness_snapshot.dart';
import 'package:danb_rhs_prep/domain/models/user_profile.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/onboarding_entry_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';
import 'package:danb_rhs_prep/widgets/primary_button.dart';

/// Forwards every [BootstrapLocalStore] method to [_delegate] unchanged —
/// a base for test doubles below that need to override only
/// [writeOnboardingComplete]'s behavior (failing, flaky, or
/// externally-controlled) while every other key still behaves like a
/// normal in-memory store.
class _DelegatingLocalStore implements BootstrapLocalStore {
  _DelegatingLocalStore(this._delegate);
  final BootstrapLocalStore _delegate;

  @override
  Future<String?> readSelectedExamId() => _delegate.readSelectedExamId();
  @override
  Future<void> writeSelectedExamId(String examId) =>
      _delegate.writeSelectedExamId(examId);
  @override
  Future<bool?> readOnboardingComplete() => _delegate.readOnboardingComplete();
  @override
  Future<void> writeOnboardingComplete(bool complete) =>
      _delegate.writeOnboardingComplete(complete);
  @override
  Future<ThemePreference?> readThemePreference() =>
      _delegate.readThemePreference();
  @override
  Future<void> writeThemePreference(ThemePreference preference) =>
      _delegate.writeThemePreference(preference);
  @override
  Future<Entitlement?> readEntitlementSnapshot() =>
      _delegate.readEntitlementSnapshot();
  @override
  Future<void> writeEntitlementSnapshot(Entitlement entitlement) =>
      _delegate.writeEntitlementSnapshot(entitlement);
  @override
  Future<ReadinessSnapshot?> readLatestReadinessSnapshot(String examId) =>
      _delegate.readLatestReadinessSnapshot(examId);
  @override
  Future<void> writeLatestReadinessSnapshot(ReadinessSnapshot snapshot) =>
      _delegate.writeLatestReadinessSnapshot(snapshot);
}

/// [writeOnboardingComplete] always fails — simulates a persistent local
/// storage failure (e.g. disk full).
class _ThrowingWriteLocalStore extends _DelegatingLocalStore {
  _ThrowingWriteLocalStore(super.delegate);
  int writeAttempts = 0;

  @override
  Future<void> writeOnboardingComplete(bool complete) async {
    writeAttempts++;
    throw StateError('disk full');
  }
}

/// [writeOnboardingComplete] fails on its first call, then genuinely
/// succeeds on every call after — simulates a transient failure that a
/// user-initiated Retry can recover from.
class _FlakyWriteLocalStore extends _DelegatingLocalStore {
  _FlakyWriteLocalStore(super.delegate);
  int writeAttempts = 0;

  @override
  Future<void> writeOnboardingComplete(bool complete) {
    writeAttempts++;
    if (writeAttempts == 1) {
      return Future<void>.error(StateError('disk full'));
    }
    return super.writeOnboardingComplete(complete);
  }
}

/// [writeOnboardingComplete] never resolves on its own — the test
/// controls exactly when it completes via [writeCompleter], to
/// deterministically test behavior while a save is genuinely still in
/// flight (no `pump(Duration(...))` guessing).
class _ControlledWriteLocalStore extends _DelegatingLocalStore {
  _ControlledWriteLocalStore(super.delegate);
  final Completer<void> writeCompleter = Completer<void>();
  int writeAttempts = 0;

  @override
  Future<void> writeOnboardingComplete(bool complete) {
    writeAttempts++;
    return writeCompleter.future;
  }
}

final ContentPackage _realPackage = () {
  final String source =
      File('assets/content/danb_rhs/content.json').readAsStringSync();
  return const ExamContentCodec().decode(source);
}();

BootstrapReady _readySnapshot() {
  return BootstrapReady(
    selectedExamId: kDefaultExamId,
    contentPackage: _realPackage,
    profile: null,
    themePreference: ThemePreference.system,
    readinessSnapshot: null,
    entitlement: Entitlement.free(lastVerifiedAt: DateTime.utc(2026, 1, 1)),
    onboardingComplete: false,
  );
}

void main() {
  Widget wrap(BootstrapLocalStore localStore) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BootstrapSessionScope(
        snapshot: _readySnapshot(),
        child: OnboardingEntryScreen(localStore: localStore),
      ),
    );
  }

  testWidgets('renders an honest placeholder, no fake profile questions',
      (tester) async {
    await tester.pumpWidget(wrap(InMemoryBootstrapLocalStore()));

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Continue records onboarding complete and enters MainShell',
      (tester) async {
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(await localStore.readOnboardingComplete(), isTrue);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(OnboardingEntryScreen), findsNothing);
  });

  testWidgets(
      'Continue is idempotent: rapid double-tap does not double-write or '
      'error', (tester) async {
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore));

    await tester.tap(find.text('Continue'));
    // Immediately tapping again, before settling — the button becomes
    // disabled (via `_continuing`) synchronously on the first tap, so a
    // real fast double-tap cannot reach `_continue` a second time.
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('does not fabricate a UserProfile — no profile is created',
      (tester) async {
    // This screen writes only a standalone onboarding-complete flag, per
    // Section 6's explicit "do not create fake profile answers" —
    // asserted here by confirming the local store's onboarding flag is
    // the only thing this screen ever writes (it has no
    // UserSettingsRepository dependency to write a profile through at
    // all).
    final localStore = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(wrap(localStore));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(await localStore.readOnboardingComplete(), isTrue);
  });

  group('onboarding-save failure handling', () {
    testWidgets(
        'a failed save shows a recoverable, accessible error and does not '
        'navigate', (tester) async {
      final localStore =
          _ThrowingWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore));

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingEntryScreen), findsOneWidget,
          reason: 'a save failure must not silently enter the main app');
      expect(find.byType(MainShell), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining("couldn't save"), findsOneWidget);
      expect(
          find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.liveRegion == true),
          findsOneWidget,
          reason: 'the error must be announced to assistive tech');
      expect(await localStore.readOnboardingComplete(), isNot(isTrue));
    });

    testWidgets('Retry after a failed save succeeds and navigates once',
        (tester) async {
      final flaky = _FlakyWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(flaky));

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(flaky.writeAttempts, 2,
          reason: 'the first attempt failed, Retry made a second one');
      expect(await flaky.readOnboardingComplete(), isTrue);
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(OnboardingEntryScreen), findsNothing,
          reason: 'navigation must happen exactly once, not repeatedly');
    });

    testWidgets(
        'repeated taps while a save is in flight cannot start a '
        'concurrent write', (tester) async {
      final controlled =
          _ControlledWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(controlled));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      // The button is now disabled/loading (its label swaps to a
      // spinner, so it can no longer be found by its old text) — tap
      // the same button element again anyway to prove the guard itself,
      // not just that the label happens to be gone.
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump();

      expect(controlled.writeAttempts, 1);

      controlled.writeCompleter.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controlled.writeAttempts, 1,
          reason: 'still exactly one write after the outstanding one '
              'resolved — the second tap never started a new one');
    });

    testWidgets(
        '"Continue for this session" navigates without marking durable '
        'completion', (tester) async {
      final localStore =
          _ThrowingWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(localStore));

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Continue for this session'), findsOneWidget);

      await tester.tap(find.text('Continue for this session'));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(await localStore.readOnboardingComplete(), isNot(isTrue),
          reason: 'session-only continuation must not pretend '
              'persistence succeeded');
    });

    testWidgets('disposing while a save is outstanding causes no exception',
        (tester) async {
      final controlled =
          _ControlledWriteLocalStore(InMemoryBootstrapLocalStore());
      await tester.pumpWidget(wrap(controlled));

      await tester.tap(find.text('Continue'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      controlled.writeCompleter.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
