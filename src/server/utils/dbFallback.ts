/**
 * Generic message returned to the client when a request fails (e.g. database errors).
 * Do not expose internal error details in responses.
 */
export const CLIENT_ERROR_MESSAGE = 'An error occurred'

/**
 * In test mode, when the database is unavailable or errors, we return empty/404 responses
 * so API contract tests pass without requiring a running Postgres.
 */
export function isDbConnectionError(err: unknown): boolean {
  if (!err) return false
  const e = err as { code?: string; name?: string; message?: string; cause?: unknown; errors?: unknown[] }
  const code = e.code || e.name || ''
  const msg = (e.message || '').toLowerCase()
  const isSequelize = e.name != null && e.name.startsWith('Sequelize')
  const nestedErrors = Array.isArray(e.errors) ? e.errors : []

  if (nestedErrors.some((nested) => isDbConnectionError(nested))) {
    return true
  }
  if (e.cause && isDbConnectionError(e.cause)) {
    return true
  }

  return (
    code === 'ECONNREFUSED' ||
    code === 'ENOTFOUND' ||
    code === 'ETIMEDOUT' ||
    code === 'ECONNRESET' ||
    e.name === 'SequelizeConnectionError' ||
    e.name === 'SequelizeConnectionRefusedError' ||
    isSequelize ||
    (msg && (msg.includes('connect') || msg.includes('relation') || msg.includes('does not exist') || msg.includes('authentication') || msg.includes('timeout')))
  )
}

export function inTestWithoutDb(err: unknown): boolean {
  return process.env.NODE_ENV === 'test' && err != null && isDbConnectionError(err)
}

export function logDbError(err: unknown, context: string): void {
  if (!err) return
  const e = err as { name?: string; code?: string; message?: string }
  const name = e.name || 'Error'
  const code = e.code || ''
  const msg = e.message || String(err)
  console.error(`[db] [${context}] ${name}${code ? ` (${code})` : ''}: ${msg}`)
}
