import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('../../src/server/repositories/modelRepository.ts', () => ({
  findIdByPathBasename: vi.fn(),
}))

vi.mock('../../src/server/repositories/countryRepository.ts', () => ({
  findCountryAt: vi.fn(),
}))

import { findIdByPathBasename } from '../../src/server/repositories/modelRepository.ts'
import { findCountryAt } from '../../src/server/repositories/countryRepository.ts'
import {
  parseStgObjectLines,
  headingSTG2True,
  isStgParseFailure,
} from '../../src/server/utils/stgObjectLines.ts'

describe('headingSTG2True', () => {
  it('maps STG heading to true degrees', () => {
    expect(headingSTG2True(0)).toBe(180)
    expect(headingSTG2True(90)).toBe(90)
    expect(headingSTG2True(180)).toBe(0)
  })
})

describe('parseStgObjectLines — path and injection resilience', () => {
  beforeEach(() => {
    vi.mocked(findIdByPathBasename).mockResolvedValue(1)
    vi.mocked(findCountryAt).mockResolvedValue({ code: 'de' })
  })

  it('rejects model path with SQL metacharacters (not in MODEL_PATH_RE)', async () => {
    const stg =
      "OBJECT_SHARED Models/Foo'; DROP TABLE bar-- 8.5 52.3 100 0\n"
    const r = await parseStgObjectLines(stg)
    expect(isStgParseFailure(r)).toBe(true)
    expect(r.lineErrors[0].messages.some((m) => /invalid|model path/i.test(m))).toBe(true)
  })

  it('rejects path with characters outside allowed model path class', async () => {
    const r = await parseStgObjectLines('OBJECT_SHARED Models/windsock<script> 8 52 100 0\n')
    expect(isStgParseFailure(r)).toBe(true)
  })

  it('returns ok when line is valid', async () => {
    const r = await parseStgObjectLines('OBJECT_SHARED Models/windsock 8.5 52.3 100 0\n')
    expect(r.ok).toBe(true)
    expect(r.objects).toHaveLength(1)
    expect(r.objects[0].modelId).toBe(1)
    expect(r.objects[0].country).toBe('de')
  })

  it('returns ok with null country when no polygon (e.g. ocean)', async () => {
    vi.mocked(findCountryAt).mockResolvedValue(null)
    const r = await parseStgObjectLines('OBJECT_SHARED Models/windsock 8.5 52.3 100 0\n')
    expect(r.ok).toBe(true)
    expect(r.objects[0].country).toBeNull()
  })
})
