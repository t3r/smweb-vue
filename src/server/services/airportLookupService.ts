import * as airportsRepository from '../repositories/airportsRepository.js'

export type AirportPosition = {
  icao: string
  name: string
  latitude: number
  longitude: number
  airportType: string | null
  ourAirportsId: number
}

export function parseIcaoParam(raw: string): string | null {
  const t = raw.trim().toUpperCase()
  if (!/^[A-Z0-9]{3,4}$/.test(t)) return null
  return t
}

export async function getPositionByIcao(rawIcao: string): Promise<AirportPosition | null> {
  const icao = parseIcaoParam(rawIcao)
  if (!icao) return null
  const row = await airportsRepository.findByIcao(icao)
  if (!row) return null
  return {
    icao: row.icao.trim(),
    name: row.name,
    latitude: row.latitude_deg,
    longitude: row.longitude_deg,
    airportType: row.airport_type,
    ourAirportsId: row.ourairports_id,
  }
}
