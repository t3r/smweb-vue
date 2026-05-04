# FlightGear scenery database

[![run-tests](https://github.com/t3r/smweb-vue/actions/workflows/run-tests.yaml/badge.svg)](https://github.com/t3r/smweb-vue/actions/workflows/run-tests.yaml)
[![E2E](https://github.com/t3r/smweb-vue/actions/workflows/e2e.yml/badge.svg)](https://github.com/t3r/smweb-vue/actions/workflows/e2e.yml)
[![Deploy email queue worker](https://github.com/t3r/smweb-vue/actions/workflows/deploy-email-queue-worker.yml/badge.svg)](https://github.com/t3r/smweb-vue/actions/workflows/deploy-email-queue-worker.yml)

This repository is the **web application and API** for the FlightGear **scenery database**: shared 3D models, object placements, authors, and the review workflow for community submissions. It replaces the **legacy PHP application** (still referenced in the ecosystem as the previous scenery site) with a **Vue 3 + Node.js (Express) + PostgreSQL** stack, open source and backed by automated tests and CI.

This is the code driving https://scenery.flightgear.org/

## Architecture (overview)

```
  Users (browser)
        |
        v
  +-------------------+
  | Reverse proxy /   |   optional; path-based mount (e.g. /v2) supported
  | TLS termination   |
  +---------+---------+
            |
     +------+------+
     |             |
     v             v
+-----------+  +---------------------------+
| Static    |  | Express API               |
| SPA       |  | sessions, OAuth, REST     |
| Vue +     |  | /api/* + production SPA   |
| Vite      |  +-------------+-------------+
+-----------+                |
     ^                       |
     |   same-origin /api    |
     +-----------------------+
                             |
        +--------------------+--------------------+
        |                    |                    |
        v                    v                    v
 +-------------+     +---------------+    +------------------+
 | PostgreSQL  |     | OAuth         |    | Email queue      |
 | fgs_*       |     | GitHub /      |    | worker (AWS)     |
 | schema      |     | GitLab        |    | notifications    |
 +-------------+     +---------------+    +------------------+
```

- **SPA** — catalog UI, maps, submission forms; built to `dist/public`.
- **API** — reads/writes the existing relational schema (`sql/`), queues position requests, reviewer flows, optional email enqueue.
- **Email worker** — separate deploy (see `terraform/` / GitHub workflow) for processing the outbound queue.

### Contribution and review workflow (implemented)

Writes do not hit live scenery tables immediately: each change is a **position request** stored in PostgreSQL (`fgs_position_requests`), identified by a **`sig`**, until someone with at least the **reviewer** role (reviewer, tester, or admin) accepts or rejects it via the validator API. Submit auth is **`POSITION_REQUEST_SUBMIT_ROLE`** (default: signed-in `user`; can be tightened or relaxed to anonymous + `email` — see `docs/auth.md`).

```
  Contributor (Vue)
        |
        |  OAuth session (GitHub/GitLab), or anonymous + email if env allows
        v
  POST /api/submissions/*          e.g. objects, models, uploads,
  (queue-only endpoints)            object/model update & delete …
        |
        v
  +---------------------------+       +---------------------------+
  | Insert row                |       | Optional: enqueue email   |
  | fgs_position_requests     | ----> | ("request created")     |
  | type, JSON payload, email |       +---------------------------+
  | comment, sig              |
  +---------------------------+
        ^
        |  signed in; role ≥ reviewer (fgs_user_roles)
        |
  GET  /api/submissions/pending           list queue (+ failed parse list)
  GET  /api/submissions/pending/:sig      full payload for one sig
        |
        +---- POST …/pending/:sig/accept ----+
        |                                     |
        |                                     v
        |                          +---------------------------+
        |                          | requestExecutor applies   |
        |                          | change to fgs_* tables    |
        |                          | + fgs_news summary line   |
        |                          | + enqueue accept email    |
        |                          | + DELETE request row      |
        |                          +---------------------------+
        |
        +---- POST …/pending/:sig/reject ----+
                                              |
                                              v
                                   +---------------------------+
                                   | enqueue reject email      |
                                   | (optional reason in body) |
                                   | + DELETE request row      |
                                   | (no scenery table writes) |
                                   +---------------------------+
```

## Quick start

```bash
npm install
cp .env.example .env
npm run dev
```

- **App (dev):** http://localhost:5173 — Vite dev server; API is proxied at `/api` (or `/{base}/api` when `APP_BASE_PATH` and `VITE_APP_BASE_PATH` match, e.g. `/v2`).
- **API direct:** http://localhost:3000

## Repository layout

| Path | Purpose |
|------|---------|
| `src/client/` | Vue SPA (Vite) |
| `src/server/` | Express API |
| `src/shared/` | Shared TypeScript |
| `sql/` | Schema and migrations |
| `tests/` | Vitest (`npm test`, `npm run test:run`) |
| `terraform/` | Infrastructure (e.g. email queue worker) |

## Production build

```bash
npm run build   # dist/server (tsc) + dist/public (Vite)
npm start       # node dist/server/app.js
```

Set `NODE_ENV=production`, `FRONTEND_URL` (public SPA origin; may include a path if mounted under a prefix), and `SESSION_SECRET` (≥32 characters). The process listens on `PORT` and binds to `IP` if set, otherwise `::` (IPv6). Behind a reverse proxy, set `TRUST_PROXY=1` so `req.ip` and cookies use `X-Forwarded-*`.

For **same host** API + SPA, omit `VITE_API_URL` so the client uses relative `/api/...` (or `/{base}/api/...` when both server and Vite use the same `APP_BASE_PATH` / `VITE_APP_BASE_PATH`). Optional: `CLIENT_DIST_PATH` if the static build is not next to `dist/server`.

**Footer build id:** At build time, Vite can expose a version string from `VITE_APP_GIT_SLUG` or `GIT_SLUG`, else a one-line `VERSION` file in the repo root, else `git rev-parse --short HEAD`, else `dev`. On hosts without `.git`, write the commit SHA to `VERSION` before `npm run build`.

## Documentation

- Auth / OAuth: `docs/auth.md`
- API contract (phase 1): `docs/api-contract-phase1.md`
