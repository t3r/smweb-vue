# API contract — phase 1 (read-only)

Base path: `/api`. Contract for tests and clients. Schema: `sql/scenemodels-schema.sql` (`fgs_models`, `fgs_modelgroups`, `fgs_authors`, `fgs_objects`, `fgs_countries`, `fgs_news`, …).

---

## Health

- **GET /api/health** — `200` if DB reachable (`status`, `message`, `database`); `503` if not.

---

## Statistics

- **GET /api/statistics** — latest snapshot + pending queue count: `{ "date", "models", "objects", "authors", "pendingRequests" }` (`date` may be `null`).
- **GET /api/statistics/history** — all rows from `fgs_statistics`, oldest first: `{ "series": [ { "date": "YYYY-MM-DD", "models", "objects", "authors" } ] }`.

---

## Models

- **GET /api/models**  
  - Query: `offset` (integer, optional), `limit` (integer, optional), `group` (integer, optional – model group id)
  - Response: `200`
  - Body: `{ "models": Model[], "total": number, "offset": number, "limit": number }`
  - `Model`: `{ "id": number, "name": string, "filename": string, "group": string | number, "author"?: { "id", "name" }, "lastUpdated"?: string }`

- **GET /api/models/recent**
  - Response: `200`
  - Body: `{ "models": Model[] }` (recent models, e.g. by `mo_modified`)

- **GET /api/models/:id**
  - Response: `200` – single model with details; `404` if not found
  - Body: `{ "id", "name", "filename", "description", "author": { "id", "name" }, "group", "lastUpdated" }`

- **GET /api/models/:id/thumbnail**
  - Response: `200` – image body (e.g. JPEG/PNG); `404` if no thumbnail

- **GET /api/models/:id/files**
  - Response: `200`
  - Body: `{ "files": string[] }` (list of file names/paths)

- **GET /api/models/:id/package**
  - Response: `200` – binary package (e.g. .tgz); `404` or `501` if not implemented

---

## Objects

- **GET /api/objects**
  - Query: `offset`, `limit` (optional)
  - Response: `200`
  - Body: `{ "objects": Object[], "total": number, "offset": number, "limit": number }`
  - `Object`: `{ "id", "modelId", "description", "position": { "lat", "lon", "elevation"?, "heading"? }, "country"?, "lastUpdated"? }`

- **GET /api/objects/search**
  - Query: `model`, `lat`, `lon`, `country`, `description` (optional)
  - Response: `200`
  - Body: `{ "objects": Object[], "total": number }`

- **GET /api/objects/:id**
  - Response: `200` – single object; `404` if not found
  - Body: object with `id`, `modelId`, `description`, `position`, `country`, `lastUpdated`

---

## Authors

- **GET /api/authors**
  - Response: `200`
  - Body: `{ "authors": Author[] }`
  - `Author`: `{ "id", "name", "email"?, "modelsCount"?, "description"?, "linkedIdentityProvider"?: boolean }` — `linkedIdentityProvider` is true when the author has a row in `fgs_extuserids` (OAuth-linked account).

- **GET /api/authors/:id**
  - Response: `200` – single author; `404` if not found
  - Body: `{ "id", "name", "email", "description", "modelsCount", "linkedIdentityProvider"?, "joinDate"? }` — same `linkedIdentityProvider` semantics as list.

---

## News

- **GET /api/news**
  - Response: `200`
  - Body: `{ "news": NewsPost[] }`
  - `NewsPost`: `{ "id", "title", "content"?, "author"?: { "id", "name" }, "publishedAt" }`

- **GET /api/news/:id**
  - Response: `200` – single news post; `404` if not found
  - Body: `{ "id", "title", "content", "author", "publishedAt" }`

---

## Submissions (write – queue for review)

Requests are stored in `fgs_position_requests` and processed by moderators via validator endpoints.

Auth for POST endpoints below (except `/objects/stg-preview`) is controlled by **`POSITION_REQUEST_SUBMIT_ROLE`**: default signed-in **`user`** (or higher); set to **`none`** / **`anonymous`** / **`off`** to allow unauthenticated calls (still send **`email`** in the body where required).

- **POST /api/submissions/objects**
  - Body: `{ "objects": [ { "modelId", "lat", "lon", "country", "elevationOffset"?, "heading"?, "description"? } ], "comment", "email"?: string }`
  - Response: `201` – `{ "id", "sig", "message": "Queued for review" }`; `400` on validation error

- **POST /api/submissions/models**
  - Body: `{ "name", "filename", "longitude", "latitude", "country", "thumbnailBase64", "modelfileBase64", "gplAccepted": true, "authorId"?, "groupId"?, "authorNew"?: { "name", "email" }, "comment"?, "email"?, "offset"?, "heading"?, "description"? }`
  - Response: `201` – `{ "id", "sig", "message": "Queued for review" }`; `400` on validation error

---

## Validator (requires signed-in user with reviewer or admin role)

- **GET /api/submissions/pending**
  - Response: `200` – `{ "pending": [ { "id", "sig", "type", "summary", "email", "comment" } ], "failed": [ { "id", "sig", "error" } ] }`

- **GET /api/submissions/pending/:sig**
  - Response: `200` – full request `{ "id", "sig", "type", "email", "comment", "content" }`; `404` if not found

- **POST /api/submissions/pending/:sig/accept**
  - Applies the request (executor) and removes it from the queue. Response: `200` – `{ "success": true }`; `404` if not found

- **POST /api/submissions/pending/:sig/reject**
  - Removes the request without applying. Response: `200` – `{ "success": true }`; `404` if not found

---

## Status codes

- `200` – success
- `201` – created (for future write endpoints)
- `204` – no content (e.g. delete)
- `400` – bad request (validation)
- `404` – resource not found
- `501` – not implemented (e.g. package download placeholder)
