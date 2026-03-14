import { sequelize } from '../config/database.js'
import { QueryTypes } from 'sequelize'

export interface CountryRow {
  code: string
  name: string | null
}

export async function findAll(): Promise<CountryRow[]> {
  const rows = await sequelize.query(
    `SELECT co_code AS code, co_name AS name
     FROM fgs_countries
     ORDER BY co_name ASC NULLS LAST, co_code ASC`,
    { type: QueryTypes.SELECT }
  ) as { code?: string; name?: string }[]
  return rows.map((r) => ({
    code: (r.code?.trim() ?? '').toLowerCase(),
    name: r.name?.trim() || null,
  }))
}

/**
 * Get country code at a WGS84 position using gadm2 geometries and fgs_countries.
 * Returns the 2-letter code (or null if not found / unknown).
 */
export async function findCountryAt(longitude: number, latitude: number): Promise<CountryRow | null> {
  const rows = await sequelize.query(
    `SELECT fgs_countries.co_code AS code, fgs_countries.co_name AS name
     FROM gadm2, fgs_countries
     WHERE ST_Within(
       ST_SetSRID(ST_MakePoint(:lon, :lat), 4326),
       gadm2.wkb_geometry
     )
     AND gadm2.iso ILIKE fgs_countries.co_three
     LIMIT 1`,
    {
      replacements: { lon: longitude, lat: latitude },
      type: QueryTypes.SELECT,
    }
  ) as { code?: string; name?: string }[]
  const row = rows[0]
  if (!row?.code) return null
  return {
    code: (row.code.trim()).toLowerCase(),
    name: row.name?.trim() || null,
  }
}
