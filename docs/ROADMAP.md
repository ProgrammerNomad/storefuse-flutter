# StoreFuse Flutter roadmap

**Implementation status:** Flutter app is present. Core session, checkout, catalog and privacy work is implemented; see [release.md](release.md) for supported features and remaining release gates.

**API gate:** Every endpoint listed below appears in [StoreFuse Bridge verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md).

| Phase | Focus | Doc |
|-------|--------|-----|
| 0 | Foundation, HTTP, envelope | [phases/00-foundation.md](phases/00-foundation.md) |
| 1 | Catalog browse | [phases/01-catalog.md](phases/01-catalog.md) |
| 2 | Search and filters | [phases/02-search.md](phases/02-search.md) |
| 3 | Cart session | [phases/03-cart.md](phases/03-cart.md) |
| 4 | Auth and account | [phases/04-auth-account.md](phases/04-auth-account.md) |
| 5 | Checkout | [phases/05-checkout.md](phases/05-checkout.md) |
| 6 | Orders and post-purchase | [phases/06-orders.md](phases/06-orders.md) |
| 7 | Hardening and release | [phases/07-hardening.md](phases/07-hardening.md) |

---

## Cross-cutting policies

- **Cache:** No HTTP cache on cart, auth, account, orders; public catalog may use short in-memory cache only.
- **Headers:** `X-WC-Nonce` for cart/checkout writes; `X-WP-Nonce` for authenticated reads and writes.
- **Customization:** Extra product fields via Bridge filters - [CUSTOMIZATION.md](CUSTOMIZATION.md).

---

## Minimum Bridge version

`1.1.0` (`api_version` in JSON matches `STOREFUSE_BRIDGE_VERSION`).
