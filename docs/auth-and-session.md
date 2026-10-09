# Auth and session (Flutter)

Flutter does **not** share cookies with the user’s browser. Implement a **persistent cookie jar** for the WordPress/WooCommerce host and treat session endpoints as **never cacheable**.

**Minimum Bridge plugin version for guest cart:** compare `GET /status` → `data.version` to **`1.0.2`** (guest `cart_nonce` on `/auth/nonce` and `/cart`).

**Cart session:** Use a **cookie jar** as the primary path. **`X-StoreFuse-Cart-Token`** signed restore is **experimental** until [Bridge cart-token-restore.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/cart-token-restore.md) passes on your site. The header is not a login token.

**Canonical auth roadmap (cookies, Application Passwords, future JWT):** [StoreFuse Bridge auth-strategy.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/auth-strategy.md) — do not duplicate that document here.

Contrast with Next.js: [Bridge mobile-flutter client guide](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/clients/mobile-flutter.md).

---

## Nonces (two types)

| Header | Nonce action | Used for |
|--------|--------------|----------|
| `X-WP-Nonce` | `wp_rest` | `POST /auth/login`, register, logout, account updates, order cancel, wishlist |
| `X-WC-Nonce` | `wc_store_api` | Cart writes, `POST /checkout`, reorder |

**Guest bootstrap (1.0.2+):** `GET /auth/nonce` returns `{ nonce, cart_nonce }`. Alternatively read `cart_nonce` from `GET /cart` JSON or `X-WC-Nonce` response header.

**Logged in:** refresh from login response or `GET /auth/me` (`nonce`, `cart_nonce`). Guest `GET /auth/me` also returns both nonces when `logged_in: false`.

---

## Login flow (verified routes)

1. `GET /auth/nonce` (store both nonces)
2. `POST /auth/login` - body `{ "email", "password", "remember" }` + `X-WP-Nonce`
3. Persist cookies; store `cart_nonce` for cart API
4. `GET /auth/me` - profile refresh (`logged_in: false` when logged out; HTTP 200)

Logout: `POST /auth/logout` + `X-WP-Nonce` + auth cookies.

Password: `POST /auth/forgot-password`, `POST /auth/reset-password` (see Bridge api-reference).

---

## Guest cart merge

Before login, call `GET /cart` and perform cart operations with the **same cookie jar**. On `POST /auth/login`, Bridge merges guest cart server-side (`storefuse_bridge_guest_cart_merged`).

Validate using the manual checklist in [verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md).

---

## Cart token header

Responses may include **`X-StoreFuse-Cart-Token`** (signed HMAC, not raw customer id). Optional to persist for diagnostics; **cookies remain authoritative**. Do not rely on header-only restore until staging checklist passes.

---

## Security notes

- No WooCommerce API keys in the app binary.
- Use certificate pinning only if your security model requires it (optional).
- Do not log nonces or cookies in production builds.
- Production builds: encrypt/store cookie **values** at rest (not merely the jar file path).
