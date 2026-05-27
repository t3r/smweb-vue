import type { Request, Response } from 'express'
import * as modelRatingService from '../services/modelRatingService.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'
import { validateId } from '../utils/validateInput.js'

export async function putModelRating(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    if (id == null) {
      res.status(400).json({ error: 'Invalid model id' })
      return
    }
    const user = req.user
    if (!user?.id) {
      res.status(401).json({ error: 'Authentication required' })
      return
    }
    const score = modelRatingService.parseRatingScore((req.body as { score?: unknown })?.score)
    if (score == null) {
      res.status(400).json({ error: 'Rating must be an integer from 1 to 5' })
      return
    }
    const rating = await modelRatingService.setModelRating(id, user.id, score)
    res.json(rating)
  } catch (err) {
    const status = (err as { statusCode?: number }).statusCode
    if (status === 404) {
      res.status(404).json({ error: 'Model not found' })
      return
    }
    logDbError(err, 'PUT /api/models/:id/rating')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getModelRating(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    if (id == null) {
      res.status(400).json({ error: 'Invalid model id' })
      return
    }
    const viewerId = req.user?.id ?? null
    const rating = await modelRatingService.getRatingFieldsForModel(id, viewerId)
    res.json(rating)
  } catch (err) {
    logDbError(err, 'GET /api/models/:id/rating')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
