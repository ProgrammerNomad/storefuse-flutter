# Environment configuration (template)

Copy values into your Flutter build config / `--dart-define` / `.env` (tooling choice is up to the future app implementation).

| Variable | Required | Example | Notes |
|----------|----------|---------|-------|
| `BRIDGE_BASE_URL` | Yes | `https://shop.example.com` | WordPress site root (no trailing path) |
| `API_NAMESPACE` | No | `storefuse/v1` | Default; rarely changed |
| `STOREFRONT_DEEP_LINK_SCHEME` | No | `storefuse` | Password reset deep links if overriding WP email filter |
| `ENABLE_HTTP_LOGS` | No | `false` | Dev only |

Full API URL:

```
${BRIDGE_BASE_URL}/wp-json/${API_NAMESPACE}
```

**Not in client env:** WooCommerce consumer key/secret - Bridge uses server-side WordPress auth.

---

## Staging vs production

Use separate `BRIDGE_BASE_URL` values per flavor. Cookie jars must not cross environments.
