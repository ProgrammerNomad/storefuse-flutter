# Local development (WordPress + XAMPP)

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
