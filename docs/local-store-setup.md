# Local WooCommerce store lab (XAMPP)

Use this checklist to seed a **real catalog** on `http://localhost/` so the Flutter app can run end-to-end flows. No automation is required-configure everything in **WP Admin**.

## Prerequisites

- WordPress + **WooCommerce** + **StoreFuse Bridge ≥ 1.0.2** active on XAMPP
- Smoke: `curl http://localhost/wp-json/storefuse/v1/status` → `data.status === "ok"`

## Catalog

- [ ] Add **5–10 products** (at least one **simple**, one **variable** if possible)
- [ ] Assign **categories** and **featured images**
- [ ] Publish products (status **Published**)

Verify from your PC:

```bash
curl "http://localhost/wp-json/storefuse/v1/products?per_page=5"
```

Expect `data.items` with products. **If `items` is empty** (common on a fresh install), the app home/shop will look empty until you add products in **WooCommerce → Products**.

## Payments

- [ ] **WooCommerce → Settings → Payments** - enable **Cash on delivery (COD)** (or another gateway you can complete locally)
- [ ] Confirm `GET /settings` shows `store.cod_enabled: true` after save

## Shipping

- [ ] **WooCommerce → Settings → Shipping** - add **Flat rate** or **Free shipping** so checkout can complete
- [ ] Set a **default customer location** if needed for rate calculation

## Test customer

- [ ] **Users → Add New** or register via storefront - create a **Customer** role user
- [ ] Note email + password for app **Login** and order history tests

## StoreFuse Bridge

- [ ] **StoreFuse Bridge** admin - confirm modules enabled: **products**, **cart**, **checkout**, **auth**, **orders**
- [ ] Optional: assign **Appearance → Menus** to locations `storefuse-header` / `storefuse-footer` for app navigation
- [ ] Optional: **Appearance → Customize → Site Identity** - set **logo** (used in app bar/splash after bootstrap)

## Run the app

| Target | `BRIDGE_BASE_URL` |
|--------|-------------------|
| Android emulator | `http://10.0.2.2` |
| Windows / iOS simulator | `http://localhost` |
| Physical device | `http://<your-pc-lan-ip>` |

```bash
flutter run --dart-define=BRIDGE_BASE_URL=http://10.0.2.2 --dart-define=APP_FLAVOR=dev
```

## Exit criteria

- Home or **Shop** shows products
- Guest **Add to cart** → **Checkout** (redirect WebView when `headless_checkout: false`) → **Order confirmation** via order key
- Sign in with test customer → **Orders** list/detail

Then run [VERIFIED_CHECKLIST.md](VERIFIED_CHECKLIST.md) and record Bridge/WC versions.
