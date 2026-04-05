import { ROLES, ROLE_USER } from './authConstants.js'

/** Env values that allow POST without a session. */
const ANONYMOUS_VALUES = new Set(['none', 'anonymous', 'off'])

/**
 * Minimum role required to POST submission endpoints that queue position requests (`/api/submissions/...`),
 * or `none` when unauthenticated clients may submit (they must still supply `email` in the body where required).
 *
 * Env: `POSITION_REQUEST_SUBMIT_ROLE` — unset or `user` (default), `reviewer` | `tester` | `admin`, or `none` / `anonymous` / `off`.
 */
export function getPositionRequestSubmitRequiredRole(): 'none' | string {
  const raw = (process.env.POSITION_REQUEST_SUBMIT_ROLE ?? '').trim().toLowerCase()
  if (raw === '' || raw === ROLE_USER) return ROLE_USER
  if (ANONYMOUS_VALUES.has(raw)) return 'none'
  if (ROLES.includes(raw)) return raw
  console.warn(
    `[app] Invalid POSITION_REQUEST_SUBMIT_ROLE="${process.env.POSITION_REQUEST_SUBMIT_ROLE}", using "${ROLE_USER}"`
  )
  return ROLE_USER
}
