import { describe, it, expect } from 'vitest'
import { hashMergeToken } from '../../src/server/services/accountMergeService.ts'

describe('hashMergeToken', () => {
  it('returns deterministic sha256 buffer', () => {
    const a = hashMergeToken('same')
    const b = hashMergeToken('same')
    expect(Buffer.compare(a, b)).toBe(0)
    expect(a.length).toBe(32)
  })

  it('differs for different tokens', () => {
    const a = hashMergeToken('a')
    const b = hashMergeToken('b')
    expect(Buffer.compare(a, b)).not.toBe(0)
  })
})
