# Phase 0 - Foundation

**Status:** Planning  
**Goal:** HTTP client, envelope parsing, health check.

## User stories

- As a developer, I can point the app at a Bridge base URL and confirm connectivity.
- As a developer, I parse `schema` and `api_version` consistently.

## Screens (future)

- Splash / environment selector (dev/staging/prod)

## Verified API calls

| Method | Route | Auth |
|--------|-------|------|
| GET | `/status` | Public |

## Headers / cache

- Public; short in-memory cache OK for `/status` during dev - prefer refresh on cold start.

## Acceptance criteria

- [ ] `GET /status` returns `data.status === 'ok'` and `api_version === '0.1.0'`
- [ ] Error envelope renders user-safe message from `error.message`
- [ ] Cookie jar initialized (empty) before session work in phase 3
