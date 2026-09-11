# RevenueCat subscription setup

The owner selected these three auto-renewing plans. All unlock the same
`premium` entitlement. Prices below are the intended **US storefront** prices;
the app displays StoreProduct.priceString and validates StoreKit's actual
subscriptionPeriod, so other storefronts use their localized store prices.

| Plan | App Store product ID (existing ExamConfig) | Duration | US price | RevenueCat package |
| --- | --- | --- | --- | --- |
| Weekly | `danb_rhs_premium_weekly` | 1 week | USD 9.99 | `$rc_weekly` |
| Monthly | `danb_rhs_premium_monthly` | 1 month | USD 29.99 | `$rc_monthly` |
| Quarterly | `danb_rhs_premium_3_months` | 3 months | USD 49.99 | `$rc_three_month` |

## Dashboard configuration (not performed by this code change)

1. In App Store Connect, create all three auto-renewable subscriptions in one
   subscription group, **RHS Premium**, at the same service level. Set durations
   and US storefront prices exactly as above; review localized prices separately.
   Do not create a 90-day consumable or a lifetime purchase for the quarterly plan.
2. Add product localizations, review screenshots and review information. Complete
   the Paid Apps agreement, banking/tax setup and app signing prerequisites.
3. In RevenueCat, create/open the project and its Apple App Store app with the
   production bundle ID. Connect the Apple credentials requested by the current
   dashboard securely there, including In-App Purchase key and server notifications.
   Never embed Apple private keys or RevenueCat secret API keys in the Flutter app.
4. Import the three products; attach all three to entitlement **`premium`**.
   Create offering **`default`**, mark it current and attach the packages above.
   Missing/duplicate products or mismatched durations disable checkout rather than
   offering a silently different plan. Do not configure introductory offers yet:
   the V1 paywall describes the selected regular recurring price.
5. Keep RevenueCat anonymous users enabled. For this accountless app, configure
   restore behavior to transfer purchases to the restoring App User ID and test
   reinstall/second-device restoration using the same Apple Account. Never call
   logOut as part of resetting study progress.
6. Publish the app's actual Terms and Privacy Policy, covering Apple/RevenueCat
   subscription processing and the anonymous customer identifier. Supply the
   public Apple SDK key (`appl_...`) and HTTPS document URLs at build time:

   ```sh
   flutter run \
     --dart-define=REVENUECAT_IOS_API_KEY=appl_YOUR_PUBLIC_APP_KEY \
     --dart-define=SUBSCRIPTION_TERMS_URL=https://YOUR_DOMAIN/terms \
     --dart-define=SUBSCRIPTION_PRIVACY_URL=https://YOUR_DOMAIN/privacy
   ```

   Use the same defines for the signed TestFlight/release build. These are public
   app configuration values. No credentials have been created or inserted by
   this change. Without a valid public key and legal URLs, buying is unavailable;
   the app still starts. Restore does not depend on paywall/legal URL loading.
7. Enable In-App Purchase capability in the signed Xcode target. The Podfile now
   explicitly targets iOS 13.0. Resolve Flutter/CocoaPods dependencies and retain
   generated lockfiles after a successful build.

## Implementation and access

- `SubscriptionService` is the domain boundary; only the data adapter imports
  RevenueCat and URL launcher. No login screen or custom backend is required.
- `SubscriptionController` sits above all navigators, refreshes at launch/resume,
  and receives RevenueCat CustomerInfo updates and expiry notifications.
- The paywall uses the existing product-card design, supports cancellation,
  pending payments, restore, and links to Apple subscription management.
- Practice refreshes access before checking its existing daily allowance. When
  the allowance is exhausted, successful purchase retries that action.
- Mock Exam refreshes access before starting a new exam, offers the paywall when
  the included allowance is used, then reconstructs the controller with the new
  entitlement. An already-started exam remains resumable.
- SDK CustomerInfo is the persisted subscription cache. Bootstrap's legacy
  SharedPreferences entitlement is not trusted for production purchase access.
  Offline access lasts only to the last known expiry. A cancelled auto-renewal
  stays active until expiry; a received refund/revocation removes access. Offline
  devices cannot learn of a refund until the next successful refresh.
- Missing expiry, inactive entitlement or failed signature verification grants
  no premium access. No synthetic success or hardcoded USD price reaches checkout.
- iOS is the configured billing platform for this release. Android/web billing
  configuration is not included. Injected demo bootstrap retains its fake state
  unless a subscription service is explicitly supplied.

## Required verification before selling

Run `flutter pub get`, `dart format --output=none --set-exit-if-changed lib test tool`,
`flutter analyze`, `flutter test`, and the signed iOS/TestFlight workflow. The
additional RevenueCat validation workflow produces a reviewable formatter and
lockfile patch for environments without Flutter; it does not replace the normal
CI checks or change their pass criteria.

In Apple sandbox on a device, verify each duration and displayed price, successful
purchase, cancellation, pending approval, renewal, cancellation at period end,
expiration, refund, reinstall/restore, no-purchase restore, offline relaunch,
return from subscription settings, double taps and a failed network request.
Verify VoiceOver, large text, and privacy/terms links on the paywall.

Payment code does not remove existing content/release gates. Do not release live
paid access until the production-reviewed question bank can deliver the advertised
practice and mock exams. Configure and exercise sandbox purchases first.

## Sources

- [RevenueCat Flutter installation](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [CustomerInfo, caching and subscription status](https://www.revenuecat.com/docs/customers/customer-info)
- [RevenueCat restore behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
- [Apple auto-renewable subscriptions](https://developer.apple.com/app-store/subscriptions/)
