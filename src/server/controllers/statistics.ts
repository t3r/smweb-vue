import type { Request, Response } from 'express'
import * as statisticsService from '../services/statisticsService.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'

export async function getStatistics(req: Request, res: Response): Promise<void> {
  try {
    const data = await statisticsService.getLatest()
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/statistics')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
