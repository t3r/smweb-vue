import { sequelize } from '../config/database.js'
import { QueryTypes } from 'sequelize'

export interface ModelGroupRow {
  id: number
  name: string | null
  path: string | null
}

export async function findAll(): Promise<ModelGroupRow[]> {
  const rows = await sequelize.query(
    `SELECT mg_id AS id, mg_name AS name, mg_path AS path
     FROM fgs_modelgroups
     ORDER BY mg_name ASC NULLS LAST, mg_id ASC`,
    { type: QueryTypes.SELECT }
  ) as ModelGroupRow[]
  return rows
}

export async function existsById(id: number): Promise<boolean> {
  if (!Number.isInteger(id) || id < 0) return false
  const rows = await sequelize.query(
    `SELECT 1 AS ok FROM fgs_modelgroups WHERE mg_id = :id LIMIT 1`,
    { replacements: { id }, type: QueryTypes.SELECT }
  ) as { ok?: number }[]
  return rows.length > 0
}
