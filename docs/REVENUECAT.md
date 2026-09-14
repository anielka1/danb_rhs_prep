# RevenueCat integration

## Architecture and identity

Production `main()` awaits SDK configuration before `runApp`. PurchasesClient
configures anonymously once per process; no custom app user ID, login or logout.
RevenueCatSubscriptionRepository implements SubscriptionStoreRepository, which
extends the existing SubscriptionRepository. UI sees only SubscriptionPlan and
Entitlement. InMemorySubscriptionRepository retains existing entitlement support
and adds controllable plan/purchase/restore callbacks for offline tests.

CustomerInfo.entitlements.all['premium'].isActive is the entitlement signal;
expiry is also enforced by Entitlement.isActiveAt. Product ID and expiry are
mapped, and lastVerifiedAt uses CustomerInfo.requestDate in UTC (not the time a
cached response is read). Older responses cannot overwrite newer events.
CustomerInfo refresh runs at startup and on foreground via PremiumAccessController,
and purchase/restore returned CustomerInfo is published immediately. A listener
propagates renewals/revocations. Read errors fail closed with Retry. The SDK owns
its cache; no independent Premium flag is written and no learning history is deleted.

## Configuration

```sh
flutter run --dart-define=REVENUECAT_IOS_API_KEY=<public_test_store_key>
flutter run --release --dart-define=REVENUECAT_IOS_API_KEY=<public_ios_sdk_key>
```

Use a `test_` key only for local debug Test Store. Release/profile accept only
`appl_` on iOS. Missing, unsupported or invalid configuration displays an unavailable
store with Retry and X; it never silently activates Premium or invokes Purchases
with an empty key. A corrected dart-define requires rebuilding/restarting.
Configuration errors are redacted; SDK logs are not forwarded. Debug adapter
logs contain only known error-code names or static catalog diagnostics.

Bundle ID: `com.anielkad.danbrhsprep`. Offering: `default`. Entitlement: `premium`.
Packages: `weekly` and `monthly`; RevenueCat's standard `$rc_weekly` and
`$rc_monthly` identifiers are also supported. Exactly one package per period must
exist, with these product IDs:

- `com.anielkad.danbrhs.premium.weekly`
- `com.anielkad.danbrhs.premium.monthly`

Configure the same product IDs in Test Store when testing it. The adapter rejects
missing/ambiguous packages and mismatched product IDs instead of selling an
unintended product. It requires subscription period and localized price metadata.
Introductory offer copy explicitly says “if eligible”; the store determines actual
eligibility. No guaranteed free trial, discount percentage, or price is fabricated.

`purchases_flutter` and `purchases_ui_flutter` are installed together. The custom
paywall is retained. Customer Center is not enabled: account feature support and
dashboard configuration have not been verified. Basic purchases/restores do not
depend on Customer Center.

## Release gates / owner actions

- In RevenueCat, connect the iOS app to the intended App Store app. Configure the
  two products, default offering and premium entitlement; attach both products
  to premium. Verify the public iOS SDK key belongs to this app.
- In App Store Connect, create both auto-renewing products in the appropriate
  subscription group, complete metadata/localizations/prices, agreements, tax
  and banking requirements, and Sandbox tester setup. Confirm product availability.
- In Xcode/developer portal, verify the matching bundle ID, signing and In-App
  Purchase capability. The project declares this capability and iOS 13 minimum;
  distribution signing remains a manual owner step.
- **TODO legal URLs:** no valid Privacy Policy or Terms of Use URL exists in this
  repo. Their controls remain disabled. Supply and verify the actual published
  URLs and wire them via a domain/platform URL-opening service before release.
  Do not publish the purchasable build until these legal links are configured.
- Review App Store privacy disclosures for RevenueCat anonymous identifiers,
  purchase data and network processing. No private App Store Connect credential
  belongs in the app, source tree, build arguments or logs. Configure those only
  in the appropriate secured dashboard.
- Test Store purchases do not prove App Store purchases work. Complete the
  following on a physical device before shipping. No real purchase is made by
  automated repository tests.

## Manual checklist

Test Store, debug build with `test_`:

- Fresh install → date or unscheduled → paywall; check localized store prices.
- X → locked Home; restart → Home; each protected tile/named route → paywall.
- Select Weekly then Monthly; check the purchased package and entitlement in
  RevenueCat. Rapid double tap must open only one store request.
- Cancel purchase, simulate failed/pending purchase, retry; neither cancellation
  nor success without premium unlocks the app.
- Restore with no active purchase, failed restore and active Premium; only the
  last unlocks. X during a pending operation must remain safe.
- Existing Premium skips first-run paywall; foreground renewal/expiry updates
  access without deleting answers, bookmarks or saved question ordering.
- Network unavailable → safe access check error/Retry; reconnect and refresh.
- Small device, large text, light/dark, VoiceOver, safe area and scroll to legal links.

Apple Sandbox / TestFlight, `appl_` build:

- Verify both actual App Store products, localized prices and any eligible trial.
- Test system purchase sheet, cancellation, Ask to Buy/pending state, renewal,
  cancellation followed by expiry, billing retry and restore after reinstall.
- Confirm the same premium entitlement and correct sandbox customer in RevenueCat.
- Confirm production bundle/signing, App Store legal metadata and privacy labels.
- Do not use a local StoreKit configuration as production catalog input.

## References checked

- [RevenueCat Flutter installation](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [SDK configuration](https://www.revenuecat.com/docs/getting-started/configuring-sdk)
- Installed `purchases_flutter` / `purchases_ui_flutter` 10.12.0 source and podspecs.

Documentation accessed 2026-09-14. The installed SDK's PurchaseParams.package /
Purchases.purchase API is used. Verification results are recorded in the PR;
Test Store, Apple Sandbox and signed device behavior require the owner setup above.
