import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/subscription/premium_access.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_free_practice_store.dart';
import 'package:danb_rhs_prep/domain/models/entitlement.dart';
import '../screens/subscription_access_test.dart'
    show ControlledSubscriptions, premium;
import '../study_plan/fixtures.dart';

void main() {
  testWidgets(
      'pending, premium purchase, expiry and duplicate retry preserve trial',
      (tester) async {
    var now = DateTime.utc(2026, 1, 1);
    final subscriptions = ControlledSubscriptions();
    final store = InMemoryFreePracticeStore();
    final access = PremiumAccessController(subscriptions,
        trialStore: store, now: () => now);

    addTearDown(subscriptions.events.close);
    expect(access.canStartFreePractice, false);
    subscriptions.read.complete(Entitlement.free(lastVerifiedAt: now));
    await tester.pump();
    expect(access.canStartFreePractice, true);
    final a = answer(fixture(count: 1).questions.first, now);
    await access.registerTrial(a.sessionId);
    var writes = 0;
    Future<void> write() async {
      writes++;
    }

    await access.recordAnswer(a, write);
    await access.recordAnswer(a, write);
    expect(access.freeQuestionsRemaining, 4);
    subscriptions.events
        .add(premium(expires: now.add(const Duration(days: 1))));
    await tester.pump();
    expect(access.active, true);
    await access.recordAnswer(a, write);
    expect((await store.read()).answeredCount, 1);
    now = now.add(const Duration(days: 2));
    expect(access.active, false);
    expect(access.freeQuestionsRemaining, 4);
    expect(access.allowsTrialSession('unregistered'), false);
    expect(writes, 3);
    access.dispose();
  });
}
