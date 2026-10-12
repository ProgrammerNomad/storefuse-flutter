# Local development (WordPress + XAMPP)

Seed products and payments: [local-store-setup.md](local-store-setup.md).

## Smoke test

```bash
curl http://localhost/wp-json/storefuse/v1/status
```

Expect `data.status === "ok"` and Bridge version ≥ **1.0.2**.

## Base URL by target

| Target | `BRIDGE_BASE_URL` |
|--------|-------------------|
| Android emulator | `http://10.0.2.2` |
| iOS simulator / desktop | `http://localhost` |
| Physical device | `http://<your-pc-lan-ip>` |

Full API root: `{BRIDGE_BASE_URL}/wp-json/storefuse/v1`

## Windows: use the real project path (not a drive shortcut)

If you open the repo through a **shortcut on another drive** (for example `D:\Websites\storefuse-flutter` → `C:\xampp\htdocs\storefuse-flutter`), Gradle may resolve the project on **D:** while Flutter plugins load from **C:** (`PUB_CACHE`). Kotlin incremental compilation can then fail with `different roots` errors involving plugins such as `webview_flutter_android`.

**Fix:** run all Flutter/Gradle commands from the **canonical folder** on one drive:

```powershell
cd C:\xampp\htdocs\storefuse-flutter
flutter run --dart-define=BRIDGE_BASE_URL=http://10.0.2.2 --dart-define=APP_FLAVOR=dev
```

The repo also sets `kotlin.incremental=false` in `android/gradle.properties` as a safety net if you must use a shortcut. After path or Gradle changes, run `flutter clean` once.

## Run the app

```bash
flutter pub get
flutter run --dart-define=BRIDGE_BASE_URL=http://10.0.2.2 --dart-define=APP_FLAVOR=dev
```

Windows desktop against local WP:

```bash
flutter run -d windows --dart-define=BRIDGE_BASE_URL=http://localhost
```

## Checkout mode

`GET /status` → `features.headless_checkout`:

- `false` (default on many sites): redirect checkout via WebView (`POST /checkout/redirect-url`)
- `true`: in-app headless form (`POST /checkout`)

Local WP verified **2026-10-12**: Bridge **1.0.2**, `headless_checkout: false`.

## Android cleartext

HTTP dev hosts are allowed in `android/app/src/main/res/xml/network_security_config.xml`.
