/**
 * FlightGear scenery tile grid / index (client util; pure functions).
 */
import { describe, it, expect } from 'vitest'
import {
  getFgTileWidthDeg,
  fgTileIndex,
  buildFgTileGridGeoJSON,
  fgTileGridFeatureCollection,
} from '../../src/client/utils/fgSceneryTileGrid.ts'

describe('getFgTileWidthDeg', () => {
  it('returns 12° at extreme north/south strips', () => {
    expect(getFgTileWidthDeg(89.5)).toBe(12)
    expect(getFgTileWidthDeg(-89.5)).toBe(12)
    expect(getFgTileWidthDeg(90)).toBe(12)
    expect(getFgTileWidthDeg(-90)).toBe(12)
  })

  it('returns mid-latitude widths per zonal bands', () => {
    expect(getFgTileWidthDeg(53.5)).toBe(0.25)
    expect(getFgTileWidthDeg(0)).toBe(0.125)
    expect(getFgTileWidthDeg(-10)).toBe(0.125)
    expect(getFgTileWidthDeg(70)).toBe(0.5)
    expect(getFgTileWidthDeg(80)).toBe(1)
  })
})

describe('fgTileIndex', () => {
  it('is stable for the same coordinates', () => {
    const a = fgTileIndex(53.5, 10.25)
    const b = fgTileIndex(53.5, 10.25)
    expect(a).toBe(b)
    expect(typeof a).toBe('number')
    expect(Number.isInteger(a)).toBe(true)
  })

  it('changes when position changes', () => {
    expect(fgTileIndex(53.5, 10)).not.toBe(fgTileIndex(53.5, 10.5))
  })
})

describe('buildFgTileGridGeoJSON', () => {
  const small = { west: 9.8, east: 10.2, south: 53.4, north: 53.6 }

  it('returns empty MultiLineString when north <= south', () => {
    const f = buildFgTileGridGeoJSON({ west: 0, east: 1, south: 5, north: 5 })
    expect(f.geometry.coordinates).toEqual([])
  })

  it('returns empty when east < west (invalid span)', () => {
    const f = buildFgTileGridGeoJSON({ west: 10, east: 9, south: 50, north: 51 })
    expect(f.geometry.coordinates).toEqual([])
  })

  it('returns empty when longitude span > 350°', () => {
    const f = buildFgTileGridGeoJSON({ west: -180, east: 180, south: -10, north: 10 })
    expect(f.geometry.coordinates).toEqual([])
  })

  it('returns empty when east <= west after clamping to world', () => {
    const f = buildFgTileGridGeoJSON({ west: 180, east: 180, south: 0, north: 1 })
    expect(f.geometry.coordinates).toEqual([])
  })

  it('produces segments for a valid viewport', () => {
    const f = buildFgTileGridGeoJSON(small)
    expect(f.type).toBe('Feature')
    expect(f.geometry.type).toBe('MultiLineString')
    expect(Array.isArray(f.geometry.coordinates)).toBe(true)
    expect(f.geometry.coordinates.length).toBeGreaterThan(0)
    for (const seg of f.geometry.coordinates) {
      expect(seg).toHaveLength(2)
      expect(seg[0]).toHaveLength(2)
      expect(seg[1]).toHaveLength(2)
    }
  })

  it('respects maxSegments cap', () => {
    const f = buildFgTileGridGeoJSON(small, { maxSegments: 8 })
    expect(f.geometry.coordinates.length).toBeLessThanOrEqual(8)
  })

  it('meridiansOnly skips horizontal budget', () => {
    const full = buildFgTileGridGeoJSON(small, { maxSegments: 200 })
    const mer = buildFgTileGridGeoJSON(small, { maxSegments: 200, meridiansOnly: true })
    expect(mer.geometry.coordinates.length).toBeLessThanOrEqual(full.geometry.coordinates.length)
  })

  it('clamps latitude to [-90, 90]', () => {
    const f = buildFgTileGridGeoJSON({ west: 10, east: 11, south: -95, north: 95 })
    expect(f.geometry.type).toBe('MultiLineString')
  })
})

describe('fgTileGridFeatureCollection', () => {
  it('wraps grid in a FeatureCollection', () => {
    const fc = fgTileGridFeatureCollection({
      west: 9.9,
      east: 10.1,
      south: 53.45,
      north: 53.55,
    })
    expect(fc.type).toBe('FeatureCollection')
    expect(fc.features).toHaveLength(1)
    expect(fc.features[0].geometry.type).toBe('MultiLineString')
  })
})
