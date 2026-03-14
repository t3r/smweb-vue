import type { Request, Response } from 'express'
import * as countryService from '../services/countryService.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'

export async function getCountries(req: Request, res: Response): Promise<void> {
  try {
    const data = await countryService.getCountries()
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/countries')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getCountryAt(req: Request, res: Response): Promise<void> {
  try {
    const lon = Number(req.query.lon)
    const lat = Number(req.query.lat)
    if (!Number.isFinite(lon) || !Number.isFinite(lat)) {
      res.status(400).json({ error: 'Query parameters lon and lat (numbers) are required' })
      return
    }
    if (lon < -180 || lon > 180 || lat < -90 || lat > 90) {
      res.status(400).json({ error: 'lon must be in [-180, 180] and lat in [-90, 90]' })
      return
    }
    const data = await countryService.getCountryAt(lon, lat)
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/countries/at')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
