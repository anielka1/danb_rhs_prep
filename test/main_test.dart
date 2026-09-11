import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/repositories/bootstrap_local_store.dart';
import 'package:danb_rhs_prep/domain/repositories/content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/data/exam_content_codec.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/main.dart';
import 'package:danb_rhs_prep/screens/main_shell.dart';
import 'package:danb_rhs_prep/screens/welcome_screen.dart';
import 'package:danb_rhs_prep/screens/splash_screen.dart';
import 'package:danb_rhs_prep/services/analytics_service.dart';
import 'package:danb_rhs_prep/services/fakes/fake_analytics_service.dart';

/// A content "loader" this file fully controls the timing of — nothing
/// resolves until the test explicitly calls [complete]/[fail], so
/// startup's async behavior (splash staying visible, a retry actually
/// re-invoking this, disposal mid-flight) can be tested deterministically
/// instead of guessed at with arbitrary `pump(Duration(...))` calls.
///
/// [complete] takes no argument — it always resolves with the real
/// bundled DANB RHS package, read once (see [_realPackage] below), not
/// read live at the point each test calls [complete]. Reading the file
/// "live" there (interleaved with other pending async work inside a
/// `testWidgets` body) was found, by direct reproduction, to delay that
/// synchronous-looking call's effects until test teardown — a
/// `flutter_test`/`fake_async` interaction, not anything about bootstrap
/// itself.
class _ControlledContentRepository implements ContentRepository {
  Completer<ContentPackage> _completer = Completer<ContentPackage>();
  int loadCallCount = 0;

  @override
  Future<ContentPackage> loadContentPackage(String examId) {
    loadCallCount++;
    return _completer.future;
  }

  void complete() => _completer.complete(_realPackage);
  void fail(Object error) => _completer.completeError(error);

  /// Prepares for a second run (e.g. a retry) with a fresh, unresolved
  /// future — otherwise completing/failing again would be a no-op on an
  /// already-completed [Completer].
  void reset() => _completer = Completer<ContentPackage>();
}

/// Read once, lazily, the first time any test touches it — not via
/// `setUpAll`/`setUp`, and not freshly per test: a plain (non-widget)
/// `test()` earlier in this same file, combined with `setUp()`-created
/// dependencies used by a later `testWidgets`, was independently found
/// (by direct reproduction) to also delay that later test's async
/// resolution until teardown. Avoiding `setUp()` here entirely — each
/// test calls [_freshBootstrap] explicitly instead — sidesteps both
/// quirks without depending on which one was really at fault.
final ContentPackage _realPackage = () {
  final String source =
      File('assets/content/danb_rhs/content.json').readAsStringSync();
  return const ExamContentCodec().decode(source);
}();

typedef _Bootstrap = ({
  _ControlledContentRepository contentLoader,
  BootstrapLocalStore localStore,
  AppBootstrapService bootstrapService,
});

_Bootstrap _freshBootstrap() {
  final contentLoader = _ControlledContentRepository();
  final localStore = InMemoryBootstrapLocalStore();
  return (
    contentLoader: contentLoader,
    localStore: localStore,
    bootstrapService: AppBootstrapService(
      contentRepository: contentLoader,
      localStore: localStore,
    ),
  );
}

Widget _appWith(_Bootstrap boot, {AnalyticsService? analytics}) {
  return DanbRhsPrepApp(
    analytics: analytics ?? const NoOpAnalyticsService(),
    bootstrapService: boot.bootstrapService,
    localStore: boot.localStore,
  );
}

void main() {
  test('the old fixed two-second splash timer is gone', () {
    final String source =
        File('lib/screens/splash_screen.dart').readAsStringSync();
    expect(source.contains('Timer('), isFalse,
        reason: 'SplashScreen must not schedule any Timer — its lifetime '
            'is determined only by bootstrap completion');
    expect(source.contains('Duration(seconds: 2)'), isFalse);
  });

  group('while bootstrap is pending', () {
    testWidgets('the splash screen stays visible, and Login never appears',
        (tester) async {
      final boot = _freshBootstrap();
      await tester.pumpWidget(_appWith(boot));
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('DANB RHS Prep'), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);

      // Still true after further time passes without bootstrap resolving
      // — this is not a race that happens to look right at one instant.
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Finish cleanly so the test doesn't leave a dangling Completer.
      boot.contentLoader.complete();
      await tester.pumpAndSettle();
    });
  });

  group('successful bootstrap routing', () {
    testWidgets('onboarding incomplete routes to the welcome screen',
        (tester) async {
      final boot = _freshBootstrap();
      await tester.pumpWidget(_appWith(boot));
      boot.contentLoader.complete();
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
    });

    testWidgets('onboarding complete routes directly to MainShell, Home',
        (tester) async {
      final boot = _freshBootstrap();
      await boot.localStore.writeOnboardingComplete(true);
      await tester.pumpWidget(_appWith(boot));
      boot.contentLoader.complete();
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Your study space'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets(
        'the initial Home view is reported exactly once, and never through Login',
        (tester) async {
      final boot = _freshBootstrap();
      final analytics = FakeAnalyticsService();
      await boot.localStore.writeOnboardingComplete(true);
      await tester.pumpWidget(_appWith(boot, analytics: analytics));
      boot.contentLoader.complete();
      await tester.pumpAndSettle();

      expect(analytics.screenViews.where((id) => id == 'home').length, 1);
    });

    testWidgets(
        'onboarding incomplete: the welcome route is reported for '
        'route analytics, preserving AnalyticsNavigatorObserver behavior',
        (tester) async {
      final boot = _freshBootstrap();
      final analytics = FakeAnalyticsService();
      await tester.pumpWidget(_appWith(boot, analytics: analytics));
      boot.contentLoader.complete();
      await tester.pumpAndSettle();

      expect(analytics.screenViews.contains(WelcomeScreen.route), isTrue);
    });

    testWidgets('replacement navigation prevents returning to the splash',
        (tester) async {
      final boot = _freshBootstrap();
      await boot.localStore.writeOnboardingComplete(true);
      await tester.pumpWidget(_appWith(boot));
      boot.contentLoader.complete();
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      // pushReplacement means there is nothing left to pop back to.
      expect(Navigator.of(tester.element(find.byType(MainShell))).canPop(),
          isFalse);
    });
  });

  group('content failure', () {
    testWidgets('shows the recoverable error screen, not a blank/crashed one',
        (tester) async {
      final boot = _freshBootstrap();
      await tester.pumpWidget(_appWith(boot));
      boot.contentLoader.fail(const FormatException('bad json'));
      await tester.pumpAndSettle();

      expect(find.text('Study content could not be loaded'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
      expect(find.byType(WelcomeScreen), findsNothing);

      // The failure's raw detail must never reach the UI.
      expect(find.textContaining('FormatException'), findsNothing);
      expect(find.textContaining('bad json'), findsNothing);
    });

    testWidgets('Retry re-runs bootstrap and can transition to success',
        (tester) async {
      final boot = _freshBootstrap();
      await tester.pumpWidget(_appWith(boot));
      boot.contentLoader.fail(const FormatException('bad json'));
      await tester.pumpAndSettle();
      expect(find.text('Study content could not be loaded'), findsOneWidget);
      expect(boot.contentLoader.loadCallCount, 1);

      boot.contentLoader.reset();
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(boot.contentLoader.loadCallCount, 2,
          reason: 'Retry must perform the complete bootstrap operation '
              'again, not reuse the failed result');

      boot.contentLoader.complete();
      await tester.pumpAndSettle();

      expect(find.text('Study content could not be loaded'), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('repeated taps while retrying do not start concurrent runs',
        (tester) async {
      final boot = _freshBootstrap();
      await tester.pumpWidget(_appWith(boot));
      boot.contentLoader.fail(const FormatException('bad json'));
      await tester.pumpAndSettle();

      boot.contentLoader.reset();
      // loadCallCount is cumulative for this test's contentLoader: 1
      // already from the initial failed attempt above, so a single
      // retry tap brings it to 2 — a second, concurrent retry would
      // bring it to 3.
      expect(boot.contentLoader.loadCallCount, 1);
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(boot.contentLoader.loadCallCount, 2);

      // While the retry is loading, the error screen (and its Retry
      // button) is replaced by the splash visual — a real user has no
      // way to tap Retry a second time during this window, which is
      // what actually prevents a concurrent run: there is nothing left
      // to tap. Pumping further time without resolving confirms this
      // holds, not just at the instant right after the first tap.
      expect(find.text('Try Again'), findsNothing);
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Try Again'), findsNothing);
      expect(boot.contentLoader.loadCallCount, 2,
          reason: 'no concurrent retry must have started while the first '
              'is still pending');

      boot.contentLoader.complete();
      await tester.pumpAndSettle();
    });
  });

  group('disposal', () {
    testWidgets(
        'disposing while bootstrap is in flight causes no navigation and '
        'no error when it later completes', (tester) async {
      final boot = _freshBootstrap();
      await tester.pumpWidget(_appWith(boot));
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      // Replace the whole tree — SplashScreen (and its State) is disposed
      // with bootstrap still pending.
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);

      // Completing afterward must not throw (a `mounted` check must
      // prevent touching the disposed State) and must not navigate
      // anything, since there is nothing left to navigate.
      boot.contentLoader.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });

  group('theme rebuilds', () {
    testWidgets('rebuilding for a theme change does not restart bootstrap',
        (tester) async {
      final boot = _freshBootstrap();
      await tester.pumpWidget(_appWith(boot));
      await tester.pump();
      expect(boot.contentLoader.loadCallCount, 1);

      // Rebuild DanbRhsPrepApp several times without changing the
      // bootstrap-relevant widgets — SplashScreen's State (an Element
      // under the same route) is preserved across this, exactly as it
      // would be across a real theme change animating through
      // AnimatedTheme.
      for (var i = 0; i < 3; i++) {
        await tester.pumpWidget(_appWith(boot));
        await tester.pump();
      }

      expect(boot.contentLoader.loadCallCount, 1,
          reason: 'bootstrap must run exactly once regardless of how many '
              'times the app rebuilds while it is pending');

      boot.contentLoader.complete();
      await tester.pumpAndSettle();
    });
  });

  group('analytics', () {
    testWidgets('a throwing analytics service does not block startup',
        (tester) async {
      final boot = _freshBootstrap();
      await boot.localStore.writeOnboardingComplete(true);
      await tester
          .pumpWidget(_appWith(boot, analytics: _ThrowingAnalyticsService()));
      boot.contentLoader.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Your study space'), findsOneWidget);
    });
  });

  group('DebugDemoEnvironment isolation', () {
    // Isolation is a separate entrypoint (lib/main_demo.dart), not a
    // runtime flag inside lib/main.dart — see that entrypoint's own doc
    // comment. This is the source-level half of the proof: the file
    // plain `flutter run` and `flutter build ios --release --no-codesign`
    // always build from must have zero reference to DebugDemoEnvironment,
    // not merely a guarded one. test/main_demo_test.dart proves the other
    // half — that lib/main_demo.dart does inject it.
    test(
        'lib/main.dart has no import or reference to DebugDemoEnvironment '
        "in actual code (a doc comment explaining this file's own "
        "isolation boundary doesn't count)", () {
      final String code = _stripComments(
        File('lib/main.dart').readAsStringSync(),
      );

      expect(code.contains('DebugDemoEnvironment'), isFalse,
          reason: 'lib/main.dart must never import or reference '
              'DebugDemoEnvironment — demo data is wired only from the '
              'separate lib/main_demo.dart entrypoint '
              '(flutter run -t lib/main_demo.dart), never reachable from a '
              'plain flutter run or a release build.');
    });
  });
}

/// Removes `//` line comments and `///`/`/** */` doc/block comments so
/// textual checks above only ever see real code, not names mentioned in
/// prose explaining the very boundary being verified.
String _stripComments(String source) {
  final String noBlockComments =
      source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return noBlockComments.split('\n').map((line) {
    final int index = line.indexOf('//');
    return index == -1 ? line : line.substring(0, index);
  }).join('\n');
}

class _ThrowingAnalyticsService implements AnalyticsService {
  @override
  void trackScreenView(String screenId) {
    throw StateError('analytics backend unavailable');
  }

  @override
  void trackEvent(String name, {Map<String, Object?> properties = const {}}) {
    throw StateError('analytics backend unavailable');
  }
}
