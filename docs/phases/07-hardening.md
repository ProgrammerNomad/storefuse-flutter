# Phase 7 - Hardening and release

**Status:** Planning  
**Goal:** Production readiness for first store rollout.

## User stories

- As a store owner, the app handles offline and API errors gracefully.
- As a developer, I verify session flows on real devices against staging Bridge.

## Verified API calls

Re-run full matrix from [verified-routes.md](https://github.com/ProgrammerNomad/storefuse-bridge/blob/main/docs/verified-routes.md) - no new routes in this phase.

## Utilities (optional store features)

| Method | Route | Auth |
|--------|-------|------|
| GET | `/utils/countries` | Public |
| GET | `/utils/pincode/{pincode}` | Public |
| POST | `/products/{slug}/notify` | Public |

## Acceptance criteria

- [ ] Manual session checklist completed (Bridge + WC versions recorded)
- [ ] No cached authenticated responses
- [ ] `api_version` mismatch shows upgrade prompt
- [ ] App store build uses production `BRIDGE_BASE_URL` only
- [ ] Companion plugin custom fields documented in [CUSTOMIZATION.md](../CUSTOMIZATION.md) tested

## Out of scope

- CI/CD pipeline definition (add when `pubspec.yaml` exists)
- App Store / Play Store listing assets
