# Customization (Flutter + WordPress)

Store-specific fields and behavior should live in **WordPress companion plugins** using StoreFuse Bridge filters - not forked app code.

---

## Pattern

1. Install a small WP plugin with `Requires Plugins: woocommerce, storefuse-bridge`.
2. Add filters documented in [Bridge extensions.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/extensions.md).
3. Flutter parses extra keys under `data` (e.g. `data.acf`, custom top-level objects from filters).

Example - product extras:

```php
add_filter( 'storefuse_bridge_product_response', function ( array $data, WC_Product $product, WP_REST_Request $request ): array {
    $data['loyalty_points'] = (int) get_post_meta( $product->get_id(), '_loyalty_points', true );
    return $data;
}, 10, 3 );
```

Flutter: read `loyalty_points` when `schema` is `storefuse.product.v1`.

---

## Versioning

Check `api_version` and `schema` on each response. When Bridge bumps versions, companion plugins and Flutter models update together on staging.

---

## v0.2 modules

Formal companion **module registration** is specified in [extension-api-v0.2.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/extension-api-v0.2.md) - not available in Bridge 0.1.0. Until then, use filters only.
