# Live acceptance checklist (audit scenarios 1–12)

Run on a **real device or emulator** against WordPress + WooCommerce + StoreFuse Bridge **≥ 1.1.0** synced from source (`scripts/deploy-local.ps1`). Record versions in [BASELINE.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/BASELINE.md).

Prepare the store: [local-store-setup.md](local-store-setup.md) and `scripts/local-fixtures.php`.

## How to run

1. **Emulator** - `flutter run --dart-define=BRIDGE_BASE_URL=http://10.0.2.2`
2. **Physical device (same Wi‑Fi)** - `flutter run --dart-define=BRIDGE_BASE_URL=http://<PC-LAN-IP>`
3. Mark each scenario **Pass** with notes (order key, error code, screenshots).
4. Automated HTTP checks (no device): `python scripts/integration-local.py fixture-credentials.json` (Bridge repo).

## Audit scenarios

| # | Scenario | Pass | Notes |
|---|----------|------|-------|
| 1 | Cold start guest session: cart bootstrap, nonces | ☐ | |
| 2 | Login/logout; session survives restart | ☐ | |
| 3 | Guest cart → login merges cart | ☐ | |
| 4 | Account switch / no credential bleed | ☐ | |
| 5 | Redirect checkout: handoff, WebView, order-received verify | ☐ | |
| 6 | Headless COD checkout with shipping quote | ☐ | |
| 7 | Idempotency: retry same checkout / empty cart replay | ☐ | |
| 8 | Shipping to different address recalculates rates | ☐ | |
| 9 | Config-driven checkout fields (phone, address_2) | ☐ | |
| 10 | Close payment WebView early → no false confirmation | ☐ | |
| 11 | Variation product price/image; module-gated tabs | ☐ | |
| 12 | Privacy/terms links; account deletion request; CORS denied origin | ☐ | |

## Legacy manual rows (Phase 7)

| Step | Flow | Pass | Notes |
|------|------|------|-------|
| A | Guest `GET /cart` establishes WC cookies | ☐ | |
| B | Nonce recovery after invalid cart write | ☐ | |
| C | Logged-in orders list/detail | ☐ | |
| D | Reorder adds lines with WC nonce | ☐ | |

**Environment**

- Bridge version: __________
- WooCommerce version: __________
- Device: __________
- `BRIDGE_BASE_URL`: __________
- `APP_FLAVOR`: __________

## Code-level checks (automated)

```bash
flutter analyze --no-fatal-infos
flutter test
cd ../storefuse-bridge && vendor/bin/phpunit
```

Manual scenarios above still require a live Bridge + WooCommerce site.
