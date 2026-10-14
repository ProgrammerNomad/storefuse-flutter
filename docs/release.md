# Release and customization

The 1.1 client requires StoreFuse Bridge 1.1.0. Run `flutter pub get`, `flutter analyze`, and `flutter test`. Local Android: `flutter run -d emulator-5554 --dart-define=BRIDGE_BASE_URL=http://10.0.2.2 --dart-define=APP_FLAVOR=dev`.

## Per-client identity

Configure WordPress StoreFuse → General app color, logo, support URL and policy pages. Homepage settings drive announcement links, hero text, trust items, featured/manual products and promotions. Replace launcher artwork and display names for each store. Do not reuse another client's signing identity.

Android `android/gradle.properties`:

```properties
storefuseApplicationId=com.example.mystore
storefuseScheme=mystore
```

Use the same scheme in `--dart-define=STOREFRONT_DEEP_LINK_SCHEME=mystore`. On iOS configure `STOREFUSE_SCHEME` in the Runner build configuration and the appropriate bundle identifier in Xcode. The custom scheme is wired on both platforms; verified web links require your domain's association files and platform entitlements and are not automatically deployed. Product shares use the WooCommerce product permalink for browser fallback.

## Signing and transport

Create your own production Android keystore and local `android/key.properties` with storeFile, storePassword, keyAlias and keyPassword. Never commit this file or keystore. Missing signing configuration deliberately fails release builds; it never falls back to the debug identity.

```sh
flutter build appbundle --release --dart-define=APP_FLAVOR=prod --dart-define=BRIDGE_BASE_URL=https://shop.example.com --dart-define=STOREFRONT_DEEP_LINK_SCHEME=mystore
```

Production requires HTTPS. Android release cleartext and backup are disabled. The debug configuration permits local development HTTP. Development responses from localhost are mapped to 10.0.2.2 only when that is the configured emulator host and ports agree; production URLs are never remapped. Use an HTTPS staging URL for physical devices and iOS unless you explicitly configure a local development exception.

## Supported checkout

Core native gateways: COD, bank transfer, cheque. Custom fields, mandatory guest account creation and unsupported gateways use the WooCommerce WebView checkout. Bridge must allow the precise HTTPS payment origins used by your provider. External payment-app schemes require a tested adapter. Completion is verified on the expected return origin against the server order; pending, failed and cancelled are distinct states.

Cookies and an unresolved checkout attempt are persisted in OS-protected storage per site/flavor. Response loss recovers using the original idempotency key after restart. The cart offers recovery even when the cart has become empty. Never clear a pending checkout just to retry payment. Logout clears local session/recovery state. Legacy plaintext cookie files are no longer read; users sign in again on upgrade.

## Optional providers and localization

Stock alerts, returns, invoice downloads, push and postcode serviceability require enabled, working Bridge providers. Core hides unavailable actions. English localization infrastructure is included; most detailed commerce copy still needs extraction before adding translated ARBs. Do not claim full multilingual or RTL acceptance yet.

## Release acceptance

Run real guest/customer purchases, two-account isolation, restart/retry, offline/slow-network, shipping/taxes/coupons, custom fields, gateway failure/cancel/late return, large text, dark mode and screen-reader checks on your store. Run iOS tests on macOS and a signed Android distribution build with your own identity. Test actual email delivery and privacy request processing. Merchant content (policies, support, images), payment accounts, signing keys and store submission are deployment configuration, not supplied credentials.

Local API-36 emulator and automated tests provide development evidence, not evidence of all these external release gates. Consult Bridge `docs/release-1.1.md` and `docs/IMPLEMENTATION-TRACKER.md` for exact verification.
