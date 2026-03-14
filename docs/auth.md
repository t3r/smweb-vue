# Authentication and authorization

- **OAuth:** GitHub and GitLab (authorization code). Callbacks: `{API_BASE}/api/auth/github/callback` and `.../gitlab/callback` (`API_BASE` defaults to `http://localhost:PORT`).
- **Sessions:** PostgreSQL table `user_sessions` (`connect-pg-simple`, same DB as app). `SESSION_STORE=memory` forces in-memory store. In `NODE_ENV=test` without `TEST_USE_REAL_DB=1`, memory is used automatically.
- **Roles:** `user` | `reviewer` | `admin` in `fgs_user_roles`; new users get `user`. `au_id` = `fgs_authors.au_id` (linked via `fgs_extuserids` after login).

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
- **GitLab:** Application — redirect = API + `/api/auth/gitlab/callback`; scopes `read_user` (and `read_api` if needed). Env: `GITLAB_CLIENT_ID`, `GITLAB_CLIENT_SECRET`, optional `GITLAB_BASE_URL`.

## Env (see `.env.example`)

`SESSION_SECRET`, `FRONTEND_URL`, OAuth secrets; optional `API_BASE_URL`. Dev with Vite on another port: `VITE_API_URL=http://localhost:3000`. Same-origin production: leave `VITE_API_URL` unset.

## Route guards

```js
import { requireAuth, requireRole } from '../middleware/auth.js'

router.get('/protected', requireAuth, handler)
router.get('/review', requireAuth, requireRole('reviewer'), handler)
router.delete('/admin/x', requireAuth, requireRole('admin'), handler)
```

`req.user`: `{ id, name, email, role }` (`id` = author id).
