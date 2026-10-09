# Phase 3 - Cart

**Status:** Planning  
**Goal:** Guest and logged-in cart with WC session.

## User stories

- As a shopper, I add/update/remove items and apply coupons.
- As a shopper, my cart persists across app restarts via cookies.

## Screens (future)

- Cart
- Mini-cart affordance on catalog

## Verified API calls

| Method | Route | Auth |
|--------|-------|------|
| GET | `/cart` | Session read |
| POST | `/cart/add` | Session write + `X-WC-Nonce` |
| PUT | `/cart/update` | Session write |
| DELETE | `/cart/remove` | Session write |
| POST | `/cart/coupon` | Session write |
| DELETE | `/cart/coupon` | Session write |

## Headers / cache

- `Cache-Control: no-store` on all cart calls
- Persist `X-StoreFuse-Cart-Token` optionally

## Acceptance criteria

- [ ] Guest cart survives app restart (cookie jar)
- [ ] Invalid nonce shows recoverable error (refresh nonces via auth phase)
- [ ] Manual checklist steps 1, 3–4 in [verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md) pass on dev site
