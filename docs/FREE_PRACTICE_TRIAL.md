# Five-question practice trial

Onboarding saves the profile, timeframe and completion before opening Home.
There is no startup subscription offer. A known Free entitlement may start only
Practice Questions while the installation's lifetime allowance remains. Other
learning routes require active Premium. Pending/failed access reads fail closed.

`PremiumAccessController` owns access decisions and uses `FreePracticeStore`.
Production uses `DriftFreePracticeStore` on the same AppDatabase as progress.
Schema 6 adds `free_practice_trial`, a singleton JSON ledger containing stable
attempt IDs, authorized trial session IDs, answeredCount, trialCompleted and
completionPaywallShown. No existing table/row is deleted. Schema 1–5 migrations
remain additive. There was no previous lifetime-trial state: the old daily cap
was computed from history, not a stored trial. Historical answers are preserved
and do not retroactively consume this new trial.

The ledger update, AnswerAttempt and QuestionState share one SQLite transaction.
Retrying the same attempt ID is idempotent; another attempt at the same question
consumes another slot. Recording a sixth new attempt fails. Failure rolls back
both answer and allowance. The ledger is outside the progress-reset tables, so
resetting learning history, changing the date or closing the offer cannot reset
it. Local-only storage cannot preserve the trial after uninstall/data deletion.

Only explicitly registered Practice Questions sessions are usable as trials;
other modes and direct routes retain the Premium guard. Sessions cap selection
at the remaining allowance and retain saved question/answer order on resume.
Premium answers use normal recording without consuming free allowance. Expiry
restores the previous remaining allowance rather than starting another trial.

After the fifth saved answer, feedback remains visible. Continuing presents the
existing paywall once at a time; closing it returns to Home. The completion flag
is durable, but is never a startup trigger. Purchase and restore continue through
the existing RevenueCat repository and entitlement-change stream, without a
parallel subscription flag. Unconfigured builds cannot simulate a purchase.

The isolated demo uses an in-memory ledger, like its other repositories. Its
restart intentionally resets demo data; production restart uses SQLite.

## Verification and rollout

Tests cover transactional rollback, same-attempt retry, repeat-question charging,
restart after three answers, reset preservation, schema-5 migration, full
onboarding → five answers → feedback → paywall → locked Home, locked alternate
routes, pending entitlement, purchase-event unlock and expiry preservation.
On iOS, additionally exercise a real configured Test Store/Sandbox transaction.
Schema rollback must be a forward fix retaining version 6, not downgrading the
installed database to schema 5.
