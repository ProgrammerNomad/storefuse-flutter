# Production release

## Requirements

- WordPress + WooCommerce + StoreFuse Bridge **≥ 1.0.2** on **HTTPS**
- `APP_FLAVOR=prod` and `BRIDGE_BASE_URL=https://your-shop.example` (non-HTTPS fails at startup)
- Complete [VERIFIED_CHECKLIST.md](VERIFIED_CHECKLIST.md) on staging before store release

## Environment matrix

| Variable | Dev | Prod |
|----------|-----|------|
| `APP_FLAVOR` | `dev` (default) | `prod` |
| `BRIDGE_BASE_URL` | `http://10.0.2.2` / LAN IP | `https://…` only |
| `ENABLE_HTTP_LOGS` | optional `true` | keep `false` |

See [env.example.md](env.example.md) for all `--dart-define` flags.

## Build commands

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test

flutter build apk \
  --dart-define=APP_FLAVOR=prod \
  --dart-define=BRIDGE_BASE_URL=https://shop.example.com

flutter build appbundle \
  --dart-define=APP_FLAVOR=prod \
  --dart-define=BRIDGE_BASE_URL=https://shop.example.com
```

iOS (after Xcode team + bundle ID):

```bash
flutter build ipa \
  --dart-define=APP_FLAVOR=prod \
  --dart-define=BRIDGE_BASE_URL=https://shop.example.com
```

## Android signing

1. Create a release keystore (once):

   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` → `android/key.properties` (do **not** commit `key.properties` or `.jks`).

3. Wire signing in `android/app/build.gradle.kts` (see comments in that file when `key.properties` exists).

Release builds must not ship with debug signing.

## Deep links

Password reset uses `STOREFRONT_DEEP_LINK_SCHEME` (default `storefuse://`) aligned with Bridge `storefront_reset_path` / WP filters.

## Pre-ship checklist

- [ ] Staging HTTPS smoke: `/status`, `/settings`, add to cart, checkout, order confirmation
- [ ] Prod flavor: no Bridge debug line on home
- [ ] Store logo/name from WP **Site Identity**
- [ ] Play/App Store assets and listing (out of repo scope)
