import { QueryTypes } from 'sequelize'
import { sequelize } from '../config/database.js'

export type AirportPositionRow = {
  icao: string
  name: string
  latitude_deg: number
  longitude_deg: number
  airport_type: string | null
  ourairports_id: number
}

export async function findByIcao(icao: string): Promise<AirportPositionRow | null> {
  const rows = (await sequelize.query(
    `SELECT icao, name, latitude_deg, longitude_deg, airport_type, ourairports_id
     FROM fgs_airports WHERE icao = :icao LIMIT 1`,
    { replacements: { icao }, type: QueryTypes.SELECT }
  )) as AirportPositionRow[]
  return rows[0] ?? null
}
