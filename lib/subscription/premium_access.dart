import 'free_practice_store.dart';
import '../domain/models/answer_attempt.dart';
import '../practice_session/practice_session_controller.dart';
import '../practice_session/practice_session_scope.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/models/entitlement.dart';
import '../domain/repositories/subscription_repository.dart';
import '../domain/repositories/bootstrap_local_store.dart';
import '../screens/subscription_screen.dart';
import '../widgets/app_scaffold.dart';

/// Offline access only. Never writes an entitlement or simulates a purchase.
class CachedSubscriptionRepository implements SubscriptionRepository {
  CachedSubscriptionRepository(this.store);
  final BootstrapLocalStore store;
  @override
  Future<Entitlement> currentEntitlement() async =>
      await store.readEntitlementSnapshot() ??
      Entitlement.free(lastVerifiedAt: DateTime.now().toUtc());
  @override
  Stream<Entitlement> entitlementChanges() => const Stream.empty();
}

/// One app-owned subscription state, above both the root and tab navigators.
/// Unexpired verified access survives refresh failures; expiry and explicit
/// revocation are enforced even without a successful refresh.
class PremiumAccessController extends ChangeNotifier
    with WidgetsBindingObserver {
  PremiumAccessController(this.repository,
      {this.trialStore, this.now = DateTime.now}) {
    WidgetsBinding.instance.addObserver(this);
    _subscription = repository.entitlementChanges().listen((value) {
      _revision++;
      _accept(value);
    }, onError: (Object _) {
      _revision++;
      _fail();
    });
    refresh();
  }
  final SubscriptionRepository repository;
  final FreePracticeStore? trialStore;
  FreePracticeState? trial;
  bool _trialReady = false;
  bool get ready => active || !loading && !failed;
  int get freeQuestionsRemaining =>
      ready && _trialReady ? trial?.remaining ?? 0 : 0;
  bool get canStartFreePractice =>
      ready && !active && freeQuestionsRemaining > 0;
  bool allowsTrialSession(String id, {bool feedback = false}) =>
      ready &&
      _trialReady &&
      trial?.sessionIds.contains(id) == true &&
      (feedback || freeQuestionsRemaining > 0);
  Future<void> registerTrial(String id) async {
    if (!canStartFreePractice) throw StateError('Free practice unavailable');
    await trialStore!.registerSession(id);
    await reloadTrial();
  }

  Future<void> reloadTrial() async {
    _trialReady = false;
    try {
      if (trialStore != null) {
        trial = await trialStore!.read();
        _trialReady = true;
      }
      if (!_disposed) notifyListeners();
    } catch (_) {
      if (!_disposed) _fail();
      rethrow;
    }
  }

  Future<void> recordAnswer(
      AnswerAttempt attempt, Future<void> Function() write) async {
    if (!ready) throw StateError('Access unavailable');
    if (active) {
      await write();
      return;
    }
    if (trialStore == null || !_trialReady) {
      throw StateError('Free practice unavailable');
    }
    await trialStore!.record(attempt, write);
    await reloadTrial();
  }

  bool _presentingCompletion = false;
  Future<bool> completeTrial(
      BuildContext context, PracticeSessionController controller) async {
    if (active ||
        !ready ||
        trial?.completed != true ||
        trial?.sessionIds.contains(controller.session.id) != true ||
        controller.hasUnsavedChanges) {
      return false;
    }
    if (_presentingCompletion) return true;
    _presentingCompletion = true;
    try {
      if (controller.answeredCount == controller.totalQuestions) {
        await controller.complete();
        if (controller.hasUnsavedChanges) return true;
      }
      await trialStore!.markCompletionPaywallShown();
      await reloadTrial();
      if (!context.mounted) return true;
      await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()));
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      }
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save your progress. Please try again.')));
      }
      return true;
    } finally {
      _presentingCompletion = false;
    }
  }

  final DateTime Function() now;
  Entitlement? entitlement;
  bool loading = true;
  bool failed = false;
  bool _disposed = false;
  int _revision = 0;
  Timer? _expiry;
  StreamSubscription<Entitlement>? _subscription;
  bool get active => entitlement?.isActiveAt(now()) ?? false;
  Future<void> refresh() async {
    final revision = ++_revision;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final value = await repository.currentEntitlement();
      _trialReady = false;
      if (trialStore != null) {
        trial = await trialStore!.read();
        _trialReady = true;
      }
      if (!_disposed && revision == _revision) _accept(value);
    } catch (_) {
      if (!_disposed && revision == _revision) _fail();
    }
  }

  void _accept(Entitlement value) {
    entitlement = value;
    loading = false;
    failed = false;
    _expiry?.cancel();
    final expiry = value.expiresAt;
    if (expiry != null && expiry.isAfter(now())) {
      _expiry = Timer(expiry.difference(now()), () {
        if (!_disposed) notifyListeners();
      });
    }
    notifyListeners();
  }

  void _fail() {
    loading = false;
    failed = true;
    // Keep the expiry timer for previously verified access while offline.
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _expiry?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

class PremiumAccessScope extends InheritedNotifier<PremiumAccessController> {
  const PremiumAccessScope(
      {super.key,
      required PremiumAccessController controller,
      required super.child})
      : super(notifier: controller);
  static PremiumAccessController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PremiumAccessScope>()
      ?.notifier;
}

/// Installed by the production composition root. Standalone presentation tests
/// may omit the app scope; all application navigators are beneath it.
bool practiceAllowed(BuildContext context, {bool feedback = false}) {
  final access = PremiumAccessScope.maybeOf(context);
  if (access == null || access.active) return true;
  final controller = PracticeSessionScope.maybeOf(context);
  return controller != null &&
      access.allowsTrialSession(controller.session.id, feedback: feedback);
}

Widget? premiumBlock(BuildContext context,
    {bool freePractice = false,
    bool trialFeedback = false,
    bool trialSession = false}) {
  final access = PremiumAccessScope.maybeOf(context);
  if (access == null || access.active) return null;
  if (freePractice && access.canStartFreePractice) return null;
  if ((trialSession || trialFeedback) &&
      practiceAllowed(context, feedback: trialFeedback)) {
    return null;
  }
  if (access.loading || access.failed) {
    return AppScaffold(
        body: Column(children: [
      Align(
          alignment: Alignment.centerRight,
          child: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close))),
      Expanded(
          child: SingleChildScrollView(
              child: Column(children: [
        if (access.loading)
          const CircularProgressIndicator(semanticsLabel: 'Checking access')
        else ...[
          const Text('Could not check your access. Your data is preserved.'),
          TextButton(onPressed: access.refresh, child: const Text('Retry'))
        ],
      ]))),
    ]));
  }
  return const SubscriptionScreen();
}
