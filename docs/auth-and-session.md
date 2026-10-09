# Auth and session (Flutter)

Flutter does **not** share cookies with the user’s browser. Implement a **persistent cookie jar** for the WordPress host and treat session endpoints as **never cacheable**.

Contrast with Next.js: [Bridge mobile-flutter client guide](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/clients/mobile-flutter.md).

---

## Nonces (two types)

| Header | Nonce action | Used for |
|--------|--------------|----------|
| `X-WP-Nonce` | `wp_rest` | `POST /auth/login`, register, logout, account updates, order cancel, wishlist |
| `X-WC-Nonce` | `wc_store_api` | Cart writes, `POST /checkout`, reorder |

Obtain WP nonce: `GET /auth/nonce` or from `GET /auth/me` / login response (`nonce`, `cart_nonce` fields).

---

## Login flow (verified routes)

1. `GET /auth/nonce`
2. `POST /auth/login` - body `{ "email", "password", "remember" }` + `X-WP-Nonce`
3. Persist cookies; store `cart_nonce` for cart API
4. `GET /auth/me` - profile refresh

Logout: `POST /auth/logout` + `X-WP-Nonce` + auth cookies.

Password: `POST /auth/forgot-password`, `POST /auth/reset-password` (see Bridge api-reference).

---

## Guest cart merge

Before login, call `GET /cart` and perform cart operations with the **same cookie jar**. On `POST /auth/login`, Bridge merges guest cart server-side (`storefuse_bridge_guest_cart_merged`).

Validate using the manual checklist in [verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md).

---

## Cart token header

Responses may include `X-StoreFuse-Cart-Token` (WC customer/session id). Optional to persist for diagnostics; **cookies remain authoritative** for Bridge 0.1.0.

---

## Security notes

- No WooCommerce API keys in the app binary.
- Use certificate pinning only if your security model requires it (optional).
- Do not log nonces or cookies in production builds.
