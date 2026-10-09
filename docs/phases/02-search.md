# Phase 2 - Search

**Status:** Planning  
**Goal:** Query products and optional content discovery.

## User stories

- As a shopper, I search products by keyword.
- As a shopper, I read blog posts (if store enables posts module).

## Screens (future)

- Search results
- Post list / post detail (optional)

## Verified API calls

| Method | Route | Auth |
|--------|-------|------|
| GET | `/search?q=` | Public |
| GET | `/posts` | Public |
| GET | `/posts/{slug}` | Public |
| GET | `/reviews?product_id=` | Public |

## Acceptance criteria

- [ ] Search debounced; minimum query length per Bridge validation
- [ ] Reviews list on product detail when `reviews` module enabled (`GET /status` → `modules.reviews`)
