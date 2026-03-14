import type { Request, Response } from 'express'
import * as modelgroupService from '../services/modelgroupService.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'

export async function getModelGroups(req: Request, res: Response): Promise<void> {
  try {
    const data = await modelgroupService.getModelGroups()
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/modelgroups')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
