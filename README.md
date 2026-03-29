# FlightGear Scenemodels

A web frontend for the FlightGear scenery database
Vue 3 + Express + PostgreSQL. 

## Setup

```bash
npm install
cp .env.example .env
npm run dev
```

- App (dev): http://localhost:5173 — Vite proxies `/api` to the API on port 3000.
- API direct: http://localhost:3000

## Repo layout

- `src/client/` — Vue (Vite)
- `src/server/` — Express API
- `src/shared/` — shared TypeScript
- `sql/` — schema and migrations
- `tests/` — Vitest (`npm test`, `npm run test:run`)

## Production

```bash
npm run build   # `dist/server` (tsc) + `dist/public` (Vite)
npm start       # `node dist/server/app.js`
```

Require `NODE_ENV=production`, `FRONTEND_URL` (exact public origin), `SESSION_SECRET` (≥32 characters). Behind a reverse proxy, set `TRUST_PROXY=1` so `req.ip` and cookies use `X-Forwarded-*`. Same host for API and SPA: do not set `VITE_API_URL` (client uses relative `/api/...`). Optional: `CLIENT_DIST_PATH` if the static build is not next to `dist/server`.
