import { sequelize } from '../config/database.js'
import { QueryTypes } from 'sequelize'

export interface StatisticsRow {
  date: unknown
  objects: number
  models: number
  authors: number
}

export async function findLatest(): Promise<StatisticsRow | null> {
  const rows = await sequelize.query(
    `SELECT st_date AS date, st_objects AS objects, st_models AS models, st_authors AS authors
     FROM fgs_statistics
     ORDER BY st_date DESC NULLS LAST
     LIMIT 1`,
    { type: QueryTypes.SELECT }
  ) as { date: unknown; objects?: number; models?: number; authors?: number }[]
  const row = rows[0]
  if (!row) return null
  return {
    date: row.date,
    objects: row.objects ?? 0,
    models: row.models ?? 0,
    authors: row.authors ?? 0,
  }
}
