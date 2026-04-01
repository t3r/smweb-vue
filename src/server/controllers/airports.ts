import type { Request, Response } from 'express'
import * as airportLookupService from '../services/airportLookupService.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'

export async function getAirportByIcao(req: Request, res: Response): Promise<void> {
  try {
    const raw = typeof req.params.icao === 'string' ? req.params.icao : req.params.icao?.[0] ?? ''
    const icao = airportLookupService.parseIcaoParam(raw)
    if (!icao) {
      res.status(400).json({ error: 'Invalid ICAO code (expected 3–4 letters or digits)' })
      return
    }
    const pos = await airportLookupService.getPositionByIcao(icao)
    if (!pos) {
      res.status(404).json({ error: 'Airport not found', icao })
      return
    }
    res.json({
      icao: pos.icao,
      name: pos.name,
      latitude: pos.latitude,
      longitude: pos.longitude,
      airportType: pos.airportType,
      ourAirportsId: pos.ourAirportsId,
    })
  } catch (err) {
    logDbError(err, 'GET /api/airports/by-icao/:icao')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
