# Integration - Flutter ↔ StoreFuse Bridge

## Base URL

```
{BRIDGE_BASE_URL}/wp-json/storefuse/v1
```

Example: `https://shop.example.com/wp-json/storefuse/v1`

Configure via [env.example.md](env.example.md).

---

## Response envelope

All success responses:

```json
{
  "schema": "storefuse.products.v1",
  "api_version": "0.1.0",
  "data": { }
}
```

Errors:

```json
{
  "schema": "storefuse.error.v1",
  "api_version": "0.1.0",
  "error": { "code": "...", "message": "...", "status": 404 }
}
```

Parse `schema` for contract versioning; never assume WooCommerce internal field names.

---

## Bootstrap sequence (recommended)

1. `GET /status` - module flags, `features.headless_checkout`
2. `GET /settings` - currency, branding (cache in memory; refresh on app resume)
3. `GET /cart` - establish WC session cookies

---

## Verified endpoints only

Do not call routes absent from [verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md). When Bridge adds routes, update phase docs in the same PR as the Bridge release.

---

## Related

- [auth-and-session.md](auth-and-session.md)
- [payments-and-checkout.md](payments-and-checkout.md)
- Bridge [api-reference.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/api-reference.md)
