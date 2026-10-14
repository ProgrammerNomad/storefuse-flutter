# Push notifications (honest capability)

StoreFuse Bridge exposes `POST /account/device-token` to persist device tokens on the customer record. **The Flutter app does not ship FCM/APNs delivery** - merchants must wire Firebase or APNs separately.

## Debug / staging

In **debug** builds (`kDebugMode`), after login/register the app calls `registerDeviceToken` with a placeholder token so you can verify the Bridge route without Firebase.

Optional dart-defines for explicit testing:

| Define | Purpose |
|--------|---------|
| `REGISTER_DEVICE_TOKEN=true` | Register even in profile builds when `features.push_notifications` is true |
| `DEVICE_PUSH_TOKEN=...` | Token string (default `dev-stub-token`) |

Production (`APP_FLAVOR=prod`) never registers placeholder tokens.

## Returns, tracking, invoice

| Action | Bridge route | App support |
|--------|--------------|-------------|
| Cancel order | `POST /orders/{id}/cancel` | Yes |
| Reorder | `POST /orders/{id}/reorder` | Yes |
| Return request | `POST /orders/{id}/return-request` | Yes (status stored; fulfillment plugins vary) |
| Tracking | `GET /orders/{id}/tracking` | Shown when Bridge returns data |
| Invoice | `GET /orders/{id}/invoice` | Opens URL/PDF when provided |

Back-in-stock: `POST /products/{slug}/notify` stores signups; email delivery requires a WooCommerce extension or custom handler on `storefuse_bridge_notify_signup`.
