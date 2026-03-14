import type { Request, Response } from 'express'
import * as newsRepo from '../repositories/newsRepository.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'

export async function getNews(req: Request, res: Response): Promise<void> {
  try {
    const limit = Math.min(Math.max(1, Number(req.query.limit) || 20), 100)
    const offset = Math.max(0, Number(req.query.offset) || 0)
    const [items, total] = await Promise.all([
      newsRepo.findRecent(limit, offset),
      newsRepo.getTotalCount(),
    ])
    res.json({ news: items, total })
  } catch (err) {
    logDbError(err, 'GET /api/news')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
