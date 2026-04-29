# Authentication and authorization

- **OAuth:** GitHub, Google, and GitLab (authorization code). Callbacks: `{API_BASE}/api/auth/github/callback`, `.../google/callback`, and `.../gitlab/callback` (`API_BASE` defaults to `http://localhost:PORT`).
- **Sessions:** PostgreSQL table `user_sessions` (`connect-pg-simple`, same DB as app). `SESSION_STORE=memory` forces in-memory store. In `NODE_ENV=test` without `TEST_USE_REAL_DB=1`, memory is used automatically.
- **Roles:** `user` | `reviewer` | `tester` | `admin` in `fgs_user_roles`; new users get `user`. POST `/api/submissions/objects`, `/object/delete`, `/object/update`, `/model/delete`, `/models`, `/models/upload`, `/models/update-upload` (anything that queues a position request) use **`POSITION_REQUEST_SUBMIT_ROLE`**: default `user` (signed-in user or higher), or `reviewer` / `tester` / `admin` for stricter gates, or **`none`** / **`anonymous`** / **`off`** to allow unauthenticated submit (callers must still send `email` in the JSON body where required). `au_id` = `fgs_authors.au_id` (linked via `fgs_extuserids` after login).

## Migration

```bash
psql -d scenemodels -f sql/migrations/001_fgfs_migration.sql
```

Grant roles:

```sql
INSERT INTO fgs_user_roles (au_id, role) VALUES (5, 'reviewer')
ON CONFLICT (au_id) DO UPDATE SET role = EXCLUDED.role;
```

## OAuth app settings

- **GitHub:** OAuth App — homepage = frontend URL; callback = API + `/api/auth/github/callback`. Env: `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`.
- **Google:** Google Cloud Console OAuth 2.0 Client (Web application) — authorized redirect URI = API + `/api/auth/google/callback`; scopes `openid profile email`. Env: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`.
- **GitLab:** Application — redirect = API + `/api/auth/gitlab/callback`; scopes `read_user` (and `read_api` if needed). Env: `GITLAB_CLIENT_ID`, `GITLAB_CLIENT_SECRET`, optional `GITLAB_BASE_URL`.

## Env (see `.env.example`)

`SESSION_SECRET`, `FRONTEND_URL`, OAuth secrets; optional `API_BASE_URL`. Dev with Vite on another port: `VITE_API_URL=http://localhost:3000`. Same-origin production: leave `VITE_API_URL` unset.

## Account merge (two `fgs_authors` rows)

If OAuth created a new author while a legacy row exists (email mismatch), a signed-in user can merge into the other account: **Account → Merge with another account** (or `/account/merge`). The server emails a one-time link to the **target** author’s `au_email`. Opening it while signed in as the **source** (initiator) runs the merge: lower `au_id` is kept, FKs on models, news, objects, and OAuth links are repointed, roles combined, the duplicate author row removed. DB migration: `sql/migrations/004_fgs_account_merge_requests.sql`.

## Route guards

```js
import { requireAuth, requireRole, requirePositionRequestSubmitAuth } from '../middleware/auth.js'

router.get('/protected', requireAuth, handler)
router.get('/review', requireAuth, requireRole('reviewer'), handler)
router.delete('/admin/x', requireAuth, requireRole('admin'), handler)
router.post('/submissions/example', requirePositionRequestSubmitAuth, handler) // respects POSITION_REQUEST_SUBMIT_ROLE
```

`req.user`: `{ id, name, email, role }` (`id` = author id).
