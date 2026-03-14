# Repository layout

```
scenemodels/
├── src/
│   ├── client/          # Vue SPA (Vite root: src/client)
│   ├── server/          # Express (entry: app.ts)
│   └── shared/
├── dist/
│   ├── server/          # tsc output (`npm run build:server`)
│   └── public/          # Vite build (`vite build`)
├── sql/                 # Schema + migrations
├── tests/               # Vitest
├── lambda/              # AWS Lambda workers (e.g. email queue)
└── package.json         # Single workspace; `npm run dev` runs API + Vite
```
