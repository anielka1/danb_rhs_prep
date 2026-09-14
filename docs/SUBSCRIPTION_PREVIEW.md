# Subscription preview and access

The subscription screen is presentation-only. Its Weekly / Monthly USD prices
are temporary copy in `subscription_screen.dart`, never product IDs or access
inputs. Cards, Continue with Monthly, and Restore purchases have null callbacks.
Monthly's visual selection does not grant Premium. No billing SDK, transaction,
network verification, restore, or entitlement write is implemented here. Legal
URLs are not configured in the app; Terms and Privacy are disabled rather than
linked to invented destinations.

## First run and persistence

ExamDateScreen preserves its existing date/profile/completion writes and Retry.
After successful first-run completion, MainShell presents the offer for Free.
Choosing an unscheduled timeframe follows the same flow. X and system Back close
the offer; the completed setup survives restart. A restart goes to Home, even if
the process ended while the offer was visible. Editing the timeframe in Settings
does not present it again. An active existing Premium entitlement skips the offer.

## Access boundary

`PremiumAccessController` reads the existing SubscriptionRepository contract and
observes entitlement events. The production adapter reads the existing locally
cached Entitlement snapshot; it never writes one. Missing snapshots mean Free.
The controller is installed above MaterialApp's root Navigator and both nested
tab Navigators. Pending reads and failed reads fail closed; errors expose Retry.
Expiry uses Entitlement.isActiveAt, an expiry timer and refresh on app resume.
Answering time pauses while the access gate is displayed; action handlers also
check access before submitting or beginning study.
Stream updates supersede an older outstanding read. There is no duplicate stored
Premium boolean and no migration.

Home's five learning tiles and Continue show locks/Premium for inactive access.
Protected practice, topic, explanation, summary/review, mock/instructions/results,
and saved-library screens independently check the app scope. This also covers
existing named-route fallbacks and unnamed routes pushed from Progress/other
screens. The practice auto-start callback checks access before creating a
session; the saved library delays its read until access is allowed. Isolated
widget tests can omit the application scope to test individual presentation or
legacy learning policies. The production composition root always installs it;
application-level access tests exercise that root, not an isolated page only.

Home, Settings/date edits and Progress remain available. Stored sessions,
answer orders, history, bookmarks, content statuses, quotas and learning logic
are retained. Existing free quota algorithms remain in the domain layer for
compatibility; the application access gate now precedes them. The debug demo
starts Free too. Tests can inject an explicit Premium entitlement into the
isolated demo to keep testing the complete learning flows; this does not affect
production or simulate a successful purchase.

## Manual verification still needed

No native iPhone run was possible in the implementation environment: simctl
reported an invalid CoreSimulatorService connection / connection refused.
Local Linux Flutter renders cover the offer and plans in both themes at 375×667
and the repository's AX5 (4×) proxy. The new paywall render tests load the bundled
MaterialIcons font so the illustration, close button and selection glyphs are
visible. Existing golden harnesses/comparators are unchanged.
