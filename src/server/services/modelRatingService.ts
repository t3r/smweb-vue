import * as modelRatingRepo from '../repositories/modelRatingRepository.js'
import * as modelRepo from '../repositories/modelRepository.js'

export interface ModelRatingFields {
  ratingAverage: number | null
  ratingCount: number
  userRating: number | null
}

const emptyRating: ModelRatingFields = {
  ratingAverage: null,
  ratingCount: 0,
  userRating: null,
}

export async function getRatingFieldsForModel(
  modelId: number,
  viewerAuthorId?: number | null
): Promise<ModelRatingFields> {
  const agg = await modelRatingRepo.getAggregateForModel(modelId)
  let userRating: number | null = null
  if (viewerAuthorId != null && Number.isFinite(viewerAuthorId)) {
    userRating = await modelRatingRepo.getUserRating(modelId, viewerAuthorId)
  }
  return {
    ratingAverage: agg.average,
    ratingCount: agg.count,
    userRating,
  }
}

export async function attachRatingsToModels(
  models: { id: number; [key: string]: unknown }[],
  viewerAuthorId?: number | null
): Promise<(typeof models[number] & ModelRatingFields)[]> {
  if (!models.length) return []
  const ids = models.map((m) => Number(m.id)).filter((id) => Number.isInteger(id) && id > 0)
  const aggregates = await modelRatingRepo.getAggregatesForModelIds(ids)
  const userRatings =
    viewerAuthorId != null && Number.isFinite(viewerAuthorId)
      ? await modelRatingRepo.getUserRatingsForModelIds(ids, viewerAuthorId)
      : new Map<number, number>()

  return models.map((m) => {
    const id = Number(m.id)
    const agg = aggregates.get(id) ?? { average: null, count: 0 }
    return {
      ...m,
      ratingAverage: agg.average,
      ratingCount: agg.count,
      userRating: userRatings.get(id) ?? null,
    }
  })
}

export function parseRatingScore(raw: unknown): number | null {
  const n = Number(raw)
  if (!Number.isInteger(n) || n < 1 || n > 5) return null
  return n
}

export async function setModelRating(
  modelId: number,
  authorId: number,
  score: number
): Promise<ModelRatingFields> {
  const model = await modelRepo.findById(modelId)
  if (!model) {
    const err = new Error('Model not found') as Error & { statusCode?: number }
    err.statusCode = 404
    throw err
  }
  await modelRatingRepo.upsertRating(modelId, authorId, score)
  return getRatingFieldsForModel(modelId, authorId)
}
