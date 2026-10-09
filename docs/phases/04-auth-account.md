# Phase 4 - Auth and account

**Status:** Planning  
**Goal:** Login, profile, addresses, wishlist.

## User stories

- As a shopper, I register, log in, and manage my profile.
- As a shopper, I save billing/shipping addresses and wishlist items.

## Screens (future)

- Login / register / forgot password
- Account profile
- Addresses
- Wishlist

## Verified API calls

| Method | Route | Auth |
|--------|-------|------|
| GET | `/auth/nonce` | Public |
| POST | `/auth/register` | Auth write |
| POST | `/auth/login` | Auth write |
| POST | `/auth/logout` | Auth write |
| GET | `/auth/me` | Authenticated |
| POST | `/auth/forgot-password` | Auth write |
| POST | `/auth/reset-password` | Auth write |
| GET | `/account` | Authenticated |
| PUT | `/account` | Authenticated + WP nonce |
| POST | `/account/change-password` | Authenticated + WP nonce |
| GET | `/addresses` | Authenticated |
| PUT | `/addresses/billing` | Authenticated + WP nonce |
| PUT | `/addresses/shipping` | Authenticated + WP nonce |
| GET | `/wishlist` | Authenticated |
| POST | `/wishlist/add` | Authenticated + WP nonce |
| DELETE | `/wishlist/remove` | Authenticated + WP nonce |
| GET | `/downloads` | Authenticated |

## Acceptance criteria

- [ ] Login merges guest cart (checklist steps 2, 6–7)
- [ ] `GET /auth/me` after cold start with stored cookies
- [ ] POST `/reviews` uses login + WP nonce (if implementing review submit)
