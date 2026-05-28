import { describe, it, expect } from 'vitest'
import { parseTileParam } from '../../src/server/services/stgService.ts'

describe('parseTileParam', () => {
  it('accepts valid tile integers', () => {
    expect(parseTileParam('0')).toEqual({ ok: true, tile: 0 })
    expect(parseTileParam('12345')).toEqual({ ok: true, tile: 12345 })
  })

  it('rejects invalid values', () => {
    expect(parseTileParam('')).toEqual({ ok: false, message: 'Tile number is required' })
    expect(parseTileParam('abc')).toEqual({ ok: false, message: 'Invalid tile number' })
    expect(parseTileParam('1.5')).toEqual({ ok: false, message: 'Invalid tile number' })
    expect(parseTileParam('-1')).toEqual({ ok: false, message: 'Invalid tile number' })
  })
})
