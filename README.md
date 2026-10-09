# StoreFuse Flutter (planning)

**Status: planning only** - this repository does not yet contain a shippable Flutter application (`pubspec.yaml`, app code, and CI are future work).

StoreFuse Flutter will be a **native client** for the same headless API as StoreFuse + Next.js:

```
{wordpress}/wp-json/storefuse/v1
```

---

## Prerequisites

- [StoreFuse Bridge](https://github.com/ProgrammerNomad/storefuse-bridge) **≥ 0.1.0** on your WooCommerce site
- Canonical route list: [Bridge verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md)

---

## Documentation (this repo)

| Doc | Purpose |
|-----|---------|
| [docs/ROADMAP.md](docs/ROADMAP.md) | Phases 0–7 overview |
| [docs/phases/](docs/phases/) | Per-phase stories, screens, verified API calls |
| [docs/integration.md](docs/integration.md) | HTTP, base URL, envelope parsing |
| [docs/auth-and-session.md](docs/auth-and-session.md) | Cookies, nonces, cart token |
| [docs/env.example.md](docs/env.example.md) | Configuration template |
| [docs/payments-and-checkout.md](docs/payments-and-checkout.md) | Checkout modes and routes |
| [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) | WP companion plugins / extra JSON fields |

Bridge client guide for mobile: [mobile-flutter.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/clients/mobile-flutter.md)

---

## License

TBD when application code is added.
