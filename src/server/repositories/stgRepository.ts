import { sequelize } from '../config/database.js'
import { QueryTypes } from 'sequelize'

/**
 * Render .stg lines for a scenery tile via PostgreSQL `fn_dumpstgrows`.
 * Returns `null` when the tile has no exportable objects or signs.
 */
export async function dumpStgForTile(tile: number): Promise<string | null> {
  const rows = (await sequelize.query(
    'SELECT fn_dumpstgrows(:tile) AS stg',
    { replacements: { tile }, type: QueryTypes.SELECT }
  )) as { stg: string | null }[]
  const stg = rows[0]?.stg
  if (stg == null || stg === '') return null
  return stg
}
