import { QueryTypes } from 'sequelize'
import { sequelize } from '../config/database.js'

export interface ModelRatingAggregate {
  average: number | null
  count: number
}

export interface ModelRatingRow {
  modelId: number
  score: number
}

/** Average and count for one model; empty when no ratings yet. */
export async function getAggregateForModel(modelId: number): Promise<ModelRatingAggregate> {
  const rows = (await sequelize.query(
    `SELECT AVG(mrt_score)::float AS average, COUNT(*)::int AS count
     FROM fgs_model_ratings
     WHERE mrt_model_id = :modelId`,
    { replacements: { modelId }, type: QueryTypes.SELECT }
  )) as { average: number | null; count: number }[]
  const row = rows[0]
  if (!row || row.count === 0) return { average: null, count: 0 }
  return {
    average: row.average != null ? Math.round(Number(row.average) * 100) / 100 : null,
    count: Number(row.count) || 0,
  }
}

/** Batch aggregates for list views. */
export async function getAggregatesForModelIds(
  modelIds: number[]
): Promise<Map<number, ModelRatingAggregate>> {
  const map = new Map<number, ModelRatingAggregate>()
  if (!modelIds.length) return map
  const rows = (await sequelize.query(
    `SELECT mrt_model_id AS "modelId",
            AVG(mrt_score)::float AS average,
            COUNT(*)::int AS count
     FROM fgs_model_ratings
     WHERE mrt_model_id IN (:modelIds)
     GROUP BY mrt_model_id`,
    { replacements: { modelIds }, type: QueryTypes.SELECT }
  )) as { modelId: number; average: number | null; count: number }[]
  for (const row of rows) {
    map.set(Number(row.modelId), {
      average: row.average != null ? Math.round(Number(row.average) * 100) / 100 : null,
      count: Number(row.count) || 0,
    })
  }
  return map
}

/** Current user's score per model (batch). */
export async function getUserRatingsForModelIds(
  modelIds: number[],
  authorId: number
): Promise<Map<number, number>> {
  const map = new Map<number, number>()
  if (!modelIds.length || !Number.isFinite(authorId)) return map
  const rows = (await sequelize.query(
    `SELECT mrt_model_id AS "modelId", mrt_score AS score
     FROM fgs_model_ratings
     WHERE mrt_author_id = :authorId AND mrt_model_id IN (:modelIds)`,
    { replacements: { authorId, modelIds }, type: QueryTypes.SELECT }
  )) as ModelRatingRow[]
  for (const row of rows) {
    map.set(Number(row.modelId), Number(row.score))
  }
  return map
}

export async function getUserRating(modelId: number, authorId: number): Promise<number | null> {
  const rows = (await sequelize.query(
    `SELECT mrt_score AS score
     FROM fgs_model_ratings
     WHERE mrt_model_id = :modelId AND mrt_author_id = :authorId`,
    { replacements: { modelId, authorId }, type: QueryTypes.SELECT }
  )) as { score: number }[]
  const score = rows[0]?.score
  return score != null ? Number(score) : null
}

export async function upsertRating(
  modelId: number,
  authorId: number,
  score: number
): Promise<{ score: number }> {
  const rows = (await sequelize.query(
    `INSERT INTO fgs_model_ratings (mrt_model_id, mrt_author_id, mrt_score)
     VALUES (:modelId, :authorId, :score)
     ON CONFLICT (mrt_model_id, mrt_author_id)
     DO UPDATE SET mrt_score = EXCLUDED.mrt_score, mrt_updated_at = now()
     RETURNING mrt_score AS score`,
    { replacements: { modelId, authorId, score }, type: QueryTypes.SELECT }
  )) as { score: number }[]
  return { score: Number(rows[0]?.score ?? score) }
}
