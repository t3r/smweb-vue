import type { Request, Response } from 'express'
import * as stgService from '../services/stgService.js'
import { CLIENT_ERROR_MESSAGE, inTestWithoutDb, logDbError } from '../utils/dbFallback.js'

function sendPlain(res: Response, status: number, body: string): void {
  res.status(status).type('text/plain; charset=utf-8').send(body)
}

/**
 * GET /api/tiles/:tile/stg — anonymous .stg dump for a scenery tile (text/plain).
 */
export async function getTileStg(req: Request, res: Response): Promise<void> {
  const parsed = stgService.parseTileParam(req.params.tile)
  if (!parsed.ok) {
    sendPlain(res, 400, parsed.message)
    return
  }

  try {
    const stg = await stgService.getStgForTile(parsed.tile)
    if (stg == null) {
      sendPlain(res, 404, 'No scenery content for this tile')
      return
    }
    sendPlain(res, 200, stg.endsWith('\n') ? stg : `${stg}\n`)
  } catch (err) {
    logDbError(err, `GET /api/tiles/${req.params.tile}/stg`)
    if (inTestWithoutDb(err)) {
      sendPlain(res, 404, 'No scenery content for this tile')
      return
    }
    sendPlain(res, 500, CLIENT_ERROR_MESSAGE)
  }
}
