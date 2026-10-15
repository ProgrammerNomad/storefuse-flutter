# Environment configuration

The app reads settings at **compile time** via Flutter `--dart-define` (not a runtime `.env` file).

| Variable | Required | Example | Notes |
|----------|----------|---------|-------|
| `APP_FLAVOR` | For prod builds | `prod` | Enables HTTPS checks and prod timeouts |
| `BRIDGE_BASE_URL` | Yes | `https://your-shop.com` | WordPress **site root** only - not `/wp-json/...` |
| `API_NAMESPACE` | No | `storefuse/v1` | Default; rarely changed |
| `STOREFRONT_DEEP_LINK_SCHEME` | No | `storefuse` | Password reset deep links if overriding WP email filter |
| `ENABLE_HTTP_LOGS` | No | `false` | Dev only; forbidden when `APP_FLAVOR=prod` |

Full API URL:

```
${BRIDGE_BASE_URL}/wp-json/${API_NAMESPACE}
```

If you paste the full REST URL by mistake, the client strips a trailing `/wp-json/<API_NAMESPACE>` from `BRIDGE_BASE_URL`.

**Not in client env:** WooCommerce consumer key/secret - Bridge uses server-side WordPress auth.

---

## Local production URL (keep out of git)

1. Copy the committed template:

   ```powershell
   Copy-Item dart_defines.example.json dart_defines.local.json
   ```

2. Edit `dart_defines.local.json` - set `BRIDGE_BASE_URL` to your live WordPress origin (HTTPS, no path).

3. Run or build:

   ```powershell
   flutter run --dart-define-from-file=dart_defines.local.json
   .\scripts\run_android_prod.ps1
   flutter build apk --release --dart-define-from-file=dart_defines.local.json
   .\scripts\build_apk_prod.ps1
   ```

`dart_defines.local.json` is gitignored. Never commit real shop URLs.

In Cursor / VS Code, [`.vscode/settings.json`](../.vscode/settings.json) adds `--dart-define-from-file=dart_defines.local.json` to **Run** and **build** so you do not need the PowerShell scripts every time. Plain `flutter run` from a **system terminal** (outside the IDE) still needs the flag or `.\scripts\run_android_prod.ps1`.

---

## Inline defines (CI or one-off)

```bash
flutter run --dart-define=APP_FLAVOR=dev --dart-define=BRIDGE_BASE_URL=http://10.0.2.2
flutter build appbundle --release --dart-define=APP_FLAVOR=prod --dart-define=BRIDGE_BASE_URL=https://your-shop.com
```

---

## Staging vs production

Use separate `BRIDGE_BASE_URL` values per flavor. Cookie jars must not cross environments.
