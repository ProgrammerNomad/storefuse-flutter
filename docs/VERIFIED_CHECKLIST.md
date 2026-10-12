# Bridge manual session checklist (Phase 7)

Run on a **real device or emulator** against your WordPress site with StoreFuse Bridge **≥ 1.0.2**. Record Bridge and WooCommerce versions here when complete.

Source: [storefuse-bridge verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md)

| Step | Flow | Pass | Notes |
|------|------|------|-------|
| 1 | Guest `GET /cart` establishes WC cookies | ☐ | |
| 2 | Guest add to cart + login merges cart | ☐ | |
| 3 | Cart survives app restart | ☐ | |
| 4 | Nonce recovery after invalid cart write | ☐ | |
| 5 | Redirect checkout → order key confirmation | ☐ | |
| 6 | Logged-in orders list/detail | ☐ | |
| 7 | Reorder adds lines with WC nonce | ☐ | |

**Environment**

- Bridge version: __________
- WooCommerce version: __________
- Device: __________
- `BRIDGE_BASE_URL`: __________
