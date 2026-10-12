# StoreFuse Flutter

Native Flutter client for [StoreFuse Bridge](https://github.com/ProgrammerNomad/storefuse-bridge) (`/wp-json/storefuse/v1`).

## Prerequisites

- Flutter stable (3.x)
- WordPress + WooCommerce + StoreFuse Bridge **≥ 1.0.2** on your site
- Local smoke: `GET {site}/wp-json/storefuse/v1/status` → `data.status === "ok"`

## Configure `BRIDGE_BASE_URL`

WordPress **site root** (no trailing slash). Cookie jars are per flavor - do not mix dev/prod URLs.

| Target | Example |
|--------|---------|
| Android emulator | `http://10.0.2.2` (host machine localhost) |
| iOS simulator | `http://localhost` |
| Physical device | `http://192.168.x.x` (your PC LAN IP) |
| Production | `https://shop.example.com` with `APP_FLAVOR=prod` |

Optional `--dart-define` values: see [docs/env.example.md](docs/env.example.md).

## Run (dev)

```bash
flutter pub get
flutter run --dart-define=BRIDGE_BASE_URL=http://10.0.2.2
```

iOS simulator:

```bash
flutter run --dart-define=BRIDGE_BASE_URL=http://localhost
```

Production build (HTTPS only):

```bash
flutter build apk --dart-define=APP_FLAVOR=prod --dart-define=BRIDGE_BASE_URL=https://shop.example.com
```

## Quality checks

```bash
flutter analyze
flutter test
```

CI: [.github/workflows/flutter.yml](.github/workflows/flutter.yml)

## Implemented phases

| Phase | Scope |
|-------|--------|
| 0 | Dio client, cookie jar, envelope errors, splash + `/status` gate |
| 1 | Catalog: settings, categories, products, PDP, deep links `/products/:slug` |
| 2 | Debounced search, PDP reviews when module enabled |
| 3 | Cart CRUD, coupons, mini-cart badge, guest nonce bootstrap |
| 4 | Login/register/logout, forgot/reset password, account, addresses, wishlist, downloads |
| 5 | Checkout: redirect WebView vs headless form from `features.headless_checkout` |
| 6 | Orders list/detail, cancel, reorder, return, tracking, invoice |
| 7 | Offline banner, no-store on session routes, tests + CI, prod flavor validation, [manual checklist](docs/VERIFIED_CHECKLIST.md) |

## Documentation

- [docs/ROADMAP.md](docs/ROADMAP.md)
- [docs/integration.md](docs/integration.md)
- Bridge [mobile-flutter.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/clients/mobile-flutter.md)

## Go-live

- [docs/local-store-setup.md](docs/local-store-setup.md) - seed WooCommerce for E2E testing
- [docs/release.md](docs/release.md) - prod builds and signing
- [docs/VERIFIED_CHECKLIST.md](docs/VERIFIED_CHECKLIST.md) - manual session sign-off

## License

[MIT](LICENSE)
