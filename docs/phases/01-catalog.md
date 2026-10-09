# Phase 1 - Catalog

**Status:** Planning  
**Goal:** Browse products and categories.

## User stories

- As a shopper, I see product lists and product detail.
- As a shopper, I browse categories.

## Screens (future)

- Home (uses settings separately)
- Category list / category detail
- Product list / product detail

## Verified API calls

| Method | Route | Auth |
|--------|-------|------|
| GET | `/settings` | Public |
| GET | `/products` | Public |
| GET | `/products/{slug}` | Public |
| GET | `/categories` | Public |
| GET | `/categories/{slug}` | Public |
| GET | `/attributes` | Public |
| GET | `/tags` | Public |

## Headers / cache

- Public tier only; optional short in-memory cache - **never** mix with cart cookies on CDN (N/A on mobile).

## Acceptance criteria

- [ ] Product detail shows price object `{ raw, formatted, currency }`
- [ ] Out-of-stock state from product payload
- [ ] Deep link to product by slug
