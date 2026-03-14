/**
 * Unit tests for request boundary validation (SQL injection / type safety at controller inputs).
 * Repositories use parameterized queries; these validators ensure hostile strings never reach as typed IDs/filters where applicable.
 */
import { describe, it, expect } from 'vitest'
import {
  validateId,
  validateCountry,
  validateDescriptionSearch,
  validateFileName,
  validateOptionalInt,
  validateOffset,
  validateLimit,
} from '../../src/server/utils/validateInput.ts'

const SQLISH = [
  "1' OR '1'='1",
  "1; DROP TABLE fgs_objects;--",
  "1 UNION SELECT * FROM fgs_authors--",
  "'; DELETE FROM fgs_models WHERE '1'='1",
  '1 OR 1=1',
  '0x01; EXEC xp_cmdshell',
  'admin"--',
  "1'/**/OR/**/1=1",
]

describe('validateId', () => {
  it('accepts positive integers', () => {
    expect(validateId(1)).toBe(1)
    expect(validateId('42')).toBe(42)
    expect(validateId('999')).toBe(999)
  })

  it('rejects null, zero, negative, non-integers', () => {
    expect(validateId(null)).toBeNull()
    expect(validateId(undefined)).toBeNull()
    expect(validateId('')).toBeNull()
    expect(validateId(0)).toBeNull()
    expect(validateId(-1)).toBeNull()
    expect(validateId(1.5)).toBeNull()
    expect(validateId('1.5')).toBeNull()
    expect(validateId(NaN)).toBeNull()
  })

  it('rejects common SQL injection patterns in id params', () => {
    for (const p of SQLISH) {
      expect(validateId(p), `expected null for ${JSON.stringify(p)}`).toBeNull()
    }
  })
})

describe('validateOptionalInt', () => {
  it('accepts positive integers or null for empty', () => {
    expect(validateOptionalInt(1)).toBe(1)
    expect(validateOptionalInt('2')).toBe(2)
    expect(validateOptionalInt(null)).toBeNull()
    expect(validateOptionalInt(undefined)).toBeNull()
    expect(validateOptionalInt('')).toBeNull()
  })

  it('rejects injection-like strings', () => {
    for (const p of SQLISH) {
      expect(validateOptionalInt(p)).toBeNull()
    }
  })
})

describe('validateCountry', () => {
  it('accepts exactly two letters', () => {
    expect(validateCountry('DE')).toBe('de')
    expect(validateCountry(' us ')).toBe('us')
  })

  it('rejects wrong length (including OR 1=1 payloads)', () => {
    expect(validateCountry('D')).toBeNull()
    expect(validateCountry('DEU')).toBeNull()
    expect(validateCountry("DE'")).toBeNull()
    for (const p of SQLISH) {
      expect(validateCountry(p)).toBeNull()
    }
  })
})

describe('validateDescriptionSearch', () => {
  it('accepts normal search text (special chars allowed; bound as ILIKE param in SQL)', () => {
    expect(validateDescriptionSearch('hangar')).toBe('hangar')
    expect(validateDescriptionSearch("O'Brien")).toBe("O'Brien")
    expect(validateDescriptionSearch('%_')).toBe('%_')
  })

  it('rejects empty and overlong', () => {
    expect(validateDescriptionSearch('')).toBeNull()
    expect(validateDescriptionSearch('   ')).toBeNull()
    expect(validateDescriptionSearch('x'.repeat(501))).toBeNull()
  })

  it('still returns a bounded string for long-but-valid SQL-looking text under max length', () => {
    const s = "'; DROP TABLE x;--".padEnd(100, 'a')
    expect(s.length).toBeLessThanOrEqual(500)
    expect(validateDescriptionSearch(s)).toBe(s)
  })
})

describe('validateFileName', () => {
  it('accepts safe filenames', () => {
    expect(validateFileName('model.ac')).toBe('model.ac')
    expect(validateFileName('tex.png')).toBe('tex.png')
  })

  it('rejects path traversal and null byte', () => {
    expect(validateFileName('../etc/passwd')).toBeNull()
    expect(validateFileName('..\\windows\\system32')).toBeNull()
    expect(validateFileName('foo\0bar.ac')).toBeNull()
    expect(validateFileName('')).toBeNull()
  })

  it('rejects injection-like names that include ..', () => {
    expect(validateFileName("model.ac'; DROP TABLE--")).not.toBeNull()
    expect(validateFileName('../../../model.ac')).toBeNull()
  })
})

describe('validateOffset', () => {
  it('returns non-negative integers; coerces invalid to 0', () => {
    expect(validateOffset(0)).toBe(0)
    expect(validateOffset(10)).toBe(10)
    expect(validateOffset('5')).toBe(5)
    expect(validateOffset(-1)).toBe(0)
    expect(validateOffset('1; DROP')).toBe(0)
    expect(validateOffset(NaN)).toBe(0)
  })
})

describe('validateLimit', () => {
  it('clamps to default 20 and max', () => {
    expect(validateLimit(undefined)).toBe(20)
    expect(validateLimit('0')).toBe(20)
    expect(validateLimit(50)).toBe(50)
    expect(validateLimit(100)).toBe(100)
    expect(validateLimit(500)).toBe(100)
    expect(validateLimit(5, 10)).toBe(5)
    expect(validateLimit(99, 10)).toBe(10)
  })

  it('rejects injection strings as invalid number → default', () => {
    for (const p of SQLISH) {
      expect(validateLimit(p)).toBe(20)
    }
  })
})
