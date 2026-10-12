# Bridge manual session checklist (Phase 7)

Run on a **real device or emulator** against your WordPress site with StoreFuse Bridge **≥ 1.0.2**. Record Bridge and WooCommerce versions here when complete.

Source: [storefuse-bridge verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md)

Prepare the store first: [local-store-setup.md](local-store-setup.md).

## How to run

1. **Emulator** - `flutter run --dart-define=BRIDGE_BASE_URL=http://10.0.2.2`
2. **Physical device (same Wi‑Fi)** - `flutter run --dart-define=BRIDGE_BASE_URL=http://<PC-LAN-IP>`
3. Work through each row below; on failure, trace `lib/core/api/storefuse_client.dart` and the relevant provider (cart, auth, checkout).
4. Mark **Pass** and add **Notes** (e.g. order key, error code).

| Step | Flow | Pass | Notes |
|------|------|------|-------|
| 1 | Guest `GET /cart` establishes WC cookies | ☐ | |
| 2 | Guest add to cart + login merges cart | ☐ | |
| 3 | Cart survives app restart | ☐ | |
| 4 | Nonce recovery after invalid cart write | ☐ | Cart provider re-bootstraps WC nonce on `missing_wc_nonce` |
| 5 | Redirect checkout → order key confirmation | ☐ | Or headless if `headless_checkout: true` |
| 6 | Logged-in orders list/detail | ☐ | |
| 7 | Reorder adds lines with WC nonce | ☐ | |

**Environment**

- Bridge version: __________
- WooCommerce version: __________
- Device: __________
- `BRIDGE_BASE_URL`: __________
- `APP_FLAVOR`: __________

## Code-level checks (automated)

These are covered by unit/widget tests and static analysis in CI:

- Envelope parsing and API errors - `test/envelope_test.dart`
- Store theme color parsing - `test/store_branding_test.dart`
- Cart badge count from bootstrap cart - `test/cart_badge_test.dart`

```bash
flutter analyze --no-fatal-infos
flutter test
```

Manual rows above still require a live Bridge + WooCommerce site.
