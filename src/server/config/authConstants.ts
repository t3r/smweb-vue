/** OAuth authority codes (fgs_extuserids.eu_authority; aligns with legacy comments: 2 = Google, 3–4 reserved) */
export const AUTH_PROVIDER_GITHUB = 1
export const AUTH_PROVIDER_GOOGLE = 2
export const AUTH_PROVIDER_GITLAB = 5

/** Role names for authorization */
export const ROLE_USER = 'user'
export const ROLE_REVIEWER = 'reviewer'
export const ROLE_TESTER = 'tester'
export const ROLE_ADMIN = 'admin'

export const ROLES = [ROLE_USER, ROLE_REVIEWER, ROLE_TESTER, ROLE_ADMIN]

/** Minimum role level (admin ≥ tester ≥ reviewer ≥ user) */
export const ROLE_LEVEL: Record<string, number> = {
  [ROLE_USER]: 0,
  [ROLE_REVIEWER]: 1,
  [ROLE_TESTER]: 2,
  [ROLE_ADMIN]: 3,
}

export function hasMinimumRole(userRole: string | undefined, requiredRole: string): boolean {
  const a = ROLE_LEVEL[userRole ?? ''] ?? -1
  const b = ROLE_LEVEL[requiredRole] ?? -1
  return a >= b
}
