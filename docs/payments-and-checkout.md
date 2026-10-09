# Payments and checkout (planning)

Checkout behavior follows **Bridge checkout module** settings and verified routes only.

---

## Discover mode

| Call | Purpose |
|------|---------|
| `GET /status` | `features.headless_checkout` |
| `GET /checkout/config` | `checkout_mode`, fields, countries |

`checkout_mode` is `redirect` or `headless` (WP admin → StoreFuse → Checkout).

---

## Redirect mode

1. Ensure cart has items (`GET /cart`).
2. `POST /checkout/redirect-url` - no nonce required.
3. Open returned URL in WebView or external browser for gateway UI.

---

## Headless mode

When `features.headless_checkout` is true:

1. `GET /checkout/payment-methods`
2. `GET /checkout/shipping-methods` (optional address query params)
3. `POST /checkout` with billing/shipping/payment - requires `X-WC-Nonce` + session cookies

Response shape: see Bridge `storefuse_bridge_checkout_result` filter output in [api-reference.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/api-reference.md).

---

## Thank-you / order confirmation

`GET /orders/{key}` - public route; key pattern `wc_order_*` (not numeric id).

---

## Out of scope (Flutter v1 planning)

- Native Stripe/PayPal SDK integration spec (depends on store gateways)
- JWT auth
- Routes not listed in [verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md)
