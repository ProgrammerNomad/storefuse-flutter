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

The repo also sets `kotlin.incremental=false` in `android/gradle.properties` and disables Kotlin incremental compile on all Android subprojects in `android/build.gradle.kts`. **If you see `different roots` in a Gradle error, you are almost certainly building from the wrong path** - switch to `C:\xampp\htdocs\storefuse-flutter` and clean caches (below).

### Cache purge (after shortcut builds or Kotlin cache errors)

```powershell
cd C:\xampp\htdocs\storefuse-flutter
flutter clean
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
# If you previously built from D:\Websites\storefuse-flutter:
Remove-Item -Recurse -Force D:\Websites\storefuse-flutter\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force D:\Websites\storefuse-flutter\android\.gradle -ErrorAction SilentlyContinue
flutter pub get
```

### Emulator: other Flutter apps

If logcat shows `relay_uploader` or another package instead of `com.storefuse.storefuse_app`, uninstall the other app: `adb uninstall com.lasthash.relay_uploader`, then run StoreFuse again.

### Quick run script (Windows)

From repo root:

```powershell
.\scripts\run_android_dev.ps1
```

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
