# Tests (Vitest)

- Watch: `npm test`
- Once: `npm run test:run`
- Real DB: `npm run test:run:db` or `TEST_USE_REAL_DB=1 npm run test:run` (uses `.env`; tests are data-agnostic)

HTTP contract: `docs/api-contract-phase1.md`.

| Path | Role |
|------|------|
| `tests/api/*.test.js` | API (supertest + mocks) |
| `tests/api/input-safety.test.js` | Malformed query/path → 4xx or safe defaults |
| `tests/unit/*` | Parsers, `validateInput`, etc. |

`tests/helpers/app.js` loads `src/server/app.ts`. With default mocks, only `GET /api/health` may hit Sequelize (`200` or `503`).
