import { describe, it, expect } from 'vitest'
import {
  resolveIcaoFromCells,
  parseOurAirportsCsvToRows,
} from '../../src/server/services/ourAirportsSync.js'

describe('resolveIcaoFromCells', () => {
  const idx = {
    ident: 0,
    icao_code: 1,
    gps_code: 2,
  }

  it('prefers icao_code', () => {
    expect(resolveIcaoFromCells(['x', 'EDDF', 'KEDF'], idx)).toBe('EDDF')
  })

  it('falls back to gps_code', () => {
    expect(resolveIcaoFromCells(['x', '', 'KJFK'], idx)).toBe('KJFK')
  })

  it('falls back to ident', () => {
    expect(resolveIcaoFromCells(['EGLL', '', ''], idx)).toBe('EGLL')
  })

  it('returns null when no valid code', () => {
    expect(resolveIcaoFromCells(['', '', ''], idx)).toBe(null)
  })
})

describe('parseOurAirportsCsvToRows', () => {
  const sample = `"id","ident","type","name","latitude_deg","longitude_deg","elevation_ft","continent","iso_country","iso_region","municipality","scheduled_service","icao_code","iata_code","gps_code","local_code","home_link","wikipedia_link","keywords"
2212,"EDDF","large_airport","Frankfurt Main Airport",50.026706,8.55835,364,"EU","DE","DE-HE","Frankfurt am Main","yes","EDDF","FRA","EDDF",,"https://example.com",,
9999,"00A","heliport","RF Heliport",40.1,-74.9,0,"NA","US","US-PA","X","no",,,"K00A","00A",,,
`

  it('parses rows and resolves ICAO keys', () => {
    const rows = parseOurAirportsCsvToRows(sample)
    const byIcao = Object.fromEntries(rows.map((r) => [r.icao, r]))
    expect(byIcao.EDDF).toMatchObject({
      icao: 'EDDF',
      name: 'Frankfurt Main Airport',
      latitude_deg: 50.026706,
      longitude_deg: 8.55835,
      airport_type: 'large_airport',
      ourairports_id: 2212,
    })
    expect(byIcao.K00A).toMatchObject({
      icao: 'K00A',
      ourairports_id: 9999,
    })
  })
})
