/**
 * Strict input validation for SQL injection prevention and data integrity.
 * Use at controller boundary; reject invalid input with 400 before passing to services/repositories.
 */

const MAX_DESCRIPTION_SEARCH_LEN = 500
const COUNTRY_CODE_LEN = 2
const MAX_FILENAME_LEN = 500

export function validateId(value: unknown): number | null {
  if (value === undefined || value === null || value === '') return null
  const n = Number(value)
  if (!Number.isInteger(n) || n < 1) return null
  return n
}

export function validateCountry(value: unknown): string | null {
  if (value === undefined || value === null) return null
  const s = String(value).trim()
  if (s.length !== COUNTRY_CODE_LEN) return null
  return s.toLowerCase()
}

export function validateDescriptionSearch(value: unknown): string | null {
  if (value === undefined || value === null) return null
  const s = String(value).trim()
  if (s.length === 0 || s.length > MAX_DESCRIPTION_SEARCH_LEN) return null
  return s
}

export function validateFileName(value: unknown): string | null {
  if (value === undefined || value === null) return null
  const s = String(value).trim()
  if (s.length === 0 || s.length > MAX_FILENAME_LEN) return null
  if (s.includes('\0') || s.includes('..')) return null
  return s
}

export function validateOptionalInt(value: unknown): number | null {
  if (value === undefined || value === null || value === '') return null
  const n = Number(value)
  if (!Number.isInteger(n) || n < 1) return null
  return n
}

export function validateOffset(value: unknown): number {
  const n = Number(value)
  if (!Number.isInteger(n) || n < 0) return 0
  return n
}

export function validateLimit(value: unknown, max = 100): number {
  const n = Number(value)
  if (!Number.isInteger(n) || n < 1) return 20
  return Math.min(n, max)
}
