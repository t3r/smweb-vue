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
