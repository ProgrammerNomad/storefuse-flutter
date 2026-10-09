# Phase 5 - Checkout

**Status:** Planning  
**Goal:** Redirect or headless checkout per store config.

## User stories

- As a shopper, I complete purchase using the store’s configured checkout mode.
- As a shopper, I view order confirmation by order key.

## Screens (future)

- Checkout (headless form or redirect CTA)
- WebView checkout (redirect mode)
- Order confirmation

## Verified API calls

| Method | Route | Auth |
|--------|-------|------|
| GET | `/checkout/config` | Public (no-store) |
| GET | `/checkout/payment-methods` | Public (no-store) |
| GET | `/checkout/shipping-methods` | Public (no-store) |
| POST | `/checkout` | Session write |
| POST | `/checkout/redirect-url` | Public |
| GET | `/orders/{key}` | Public (order key) |

See [payments-and-checkout.md](../payments-and-checkout.md).

## Acceptance criteria

- [ ] UI switches on `features.headless_checkout` from `/status`
- [ ] Redirect mode opens Woo checkout URL from `/checkout/redirect-url`
- [ ] Headless mode places order with valid `X-WC-Nonce`
