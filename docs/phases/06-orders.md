# Phase 6 - Orders and post-purchase

**Status:** Planning  
**Goal:** Order history, cancel, reorder, tracking.

## User stories

- As a shopper, I view past orders and order detail.
- As a shopper, I cancel eligible orders and request returns.

## Screens (future)

- Order list
- Order detail
- Tracking / invoice

## Verified API calls

| Method | Route | Auth |
|--------|-------|------|
| GET | `/orders` | Authenticated |
| GET | `/orders/{id}` | Authenticated |
| POST | `/orders/{id}/cancel` | Authenticated + WP nonce |
| POST | `/orders/{id}/reorder` | Authenticated + `X-WC-Nonce` |
| POST | `/orders/{id}/return-request` | Authenticated + WP nonce |
| GET | `/orders/{id}/tracking` | Authenticated |
| GET | `/orders/{id}/invoice` | Authenticated |

Note: numeric `{id}` only; public thank-you uses `GET /orders/{key}` in phase 5.

## Acceptance criteria

- [ ] Order list paginated (`page`, `per_page`)
- [ ] Reorder adds lines to cart with WC nonce
