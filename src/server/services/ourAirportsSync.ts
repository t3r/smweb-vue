import { sequelize } from '../config/database.js'
import { iterateCsvRecords } from '../utils/csv.js'

const DEFAULT_CSV_URL = 'https://davidmegginson.github.io/ourairports-data/airports.csv'
const DEFAULT_INTERVAL_MS = 24 * 60 * 60 * 1000
const INSERT_BATCH = 400

export type OurAirportsImportRow = {
  ourairports_id: number
  icao: string
  name: string
  latitude_deg: number
  longitude_deg: number
  airport_type: string | null
}

function getCsvUrl(): string {
  const u = process.env.OURAIRPORTS_CSV_URL?.trim()
  return u && u.length > 0 ? u : DEFAULT_CSV_URL
}

function getIntervalMs(): number {
  const n = Number(process.env.OURAIRPORTS_SYNC_INTERVAL_MS)
  if (Number.isFinite(n) && n >= 60_000) return n
  return DEFAULT_INTERVAL_MS
}

function headerMap(headerCells: string[]): Record<string, number> {
  const m: Record<string, number> = {}
  headerCells.forEach((h, i) => {
    m[h.trim().replace(/^\ufeff/, '')] = i
  })
  return m
}

/** Pick a stable ICAO-like key for lookup (OurAirports: icao_code, gps_code, ident). */
export function resolveIcaoFromCells(row: string[], idx: Record<string, number>): string | null {
  const get = (k: string): string => {
    const i = idx[k]
    if (i === undefined) return ''
    return (row[i] ?? '').trim()
  }
  for (const key of ['icao_code', 'gps_code', 'ident'] as const) {
    const raw = get(key)
    if (!raw) continue
    const u = raw.toUpperCase()
    if (/^[A-Z0-9]{3,4}$/.test(u)) return u
  }
  return null
}

export function parseOurAirportsCsvToRows(csvText: string): OurAirportsImportRow[] {
  const gen = iterateCsvRecords(csvText)
  const first = gen.next()
  if (first.done) return []
  const header = headerMap(first.value)
  const need = ['id', 'ident', 'type', 'name', 'latitude_deg', 'longitude_deg']
  for (const k of need) {
    if (header[k] === undefined) {
      throw new Error(`OurAirports CSV missing column: ${k}`)
    }
  }

  const byIcao = new Map<string, OurAirportsImportRow>()

  for (const cells of gen) {
    if (cells.length < header['name']! + 1) continue
    const idStr = (cells[header['id']!] ?? '').trim()
    const id = Number(idStr)
    if (!Number.isFinite(id)) continue

    const icao = resolveIcaoFromCells(cells, header)
    if (!icao) continue

    const lat = Number((cells[header['latitude_deg']!] ?? '').trim())
    const lon = Number((cells[header['longitude_deg']!] ?? '').trim())
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) continue
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue

    const name = (cells[header['name']!] ?? '').trim() || icao
    const airportType = (cells[header['type']!] ?? '').trim() || null

    byIcao.set(icao, {
      ourairports_id: id,
      icao,
      name,
      latitude_deg: lat,
      longitude_deg: lon,
      airport_type: airportType,
    })
  }

  return [...byIcao.values()]
}

async function downloadCsvText(url: string): Promise<string> {
  const res = await fetch(url, {
    redirect: 'follow',
    headers: { Accept: 'text/csv,*/*' },
  })
  if (!res.ok) {
    throw new Error(`OurAirports download failed: HTTP ${res.status} ${res.statusText}`)
  }
  return res.text()
}

async function replaceAllAirports(rows: OurAirportsImportRow[]): Promise<void> {
  const t = await sequelize.transaction()
  try {
    await sequelize.query('TRUNCATE TABLE fgs_airports RESTART IDENTITY', { transaction: t })
    for (let i = 0; i < rows.length; i += INSERT_BATCH) {
      const chunk = rows.slice(i, i + INSERT_BATCH)
      const replacements: Record<string, unknown> = {}
      const placeholders = chunk
        .map((row, r) => {
          replacements[`id${r}`] = row.ourairports_id
          replacements[`ic${r}`] = row.icao
          replacements[`nm${r}`] = row.name
          replacements[`la${r}`] = row.latitude_deg
          replacements[`lo${r}`] = row.longitude_deg
          replacements[`ty${r}`] = row.airport_type
          return `(:id${r}, :ic${r}, :nm${r}, :la${r}, :lo${r}, :ty${r})`
        })
        .join(',')
      await sequelize.query(
        `INSERT INTO fgs_airports (ourairports_id, icao, name, latitude_deg, longitude_deg, airport_type)
         VALUES ${placeholders}`,
        { replacements, transaction: t }
      )
    }
    await t.commit()
  } catch (e) {
    await t.rollback()
    throw e
  }
}

let syncInFlight = false

export async function syncOurAirportsFromWeb(): Promise<{ ok: true; count: number } | { ok: false; error: string }> {
  if (syncInFlight) {
    return { ok: false, error: 'sync already in progress' }
  }
  syncInFlight = true
  try {
    const url = getCsvUrl()
    const text = await downloadCsvText(url)
    const rows = parseOurAirportsCsvToRows(text)
    await replaceAllAirports(rows)
    console.log(`[ourairports] imported ${rows.length} airports from ${url}`)
    return { ok: true, count: rows.length }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    console.error('[ourairports] sync failed:', msg)
    return { ok: false, error: msg }
  } finally {
    syncInFlight = false
  }
}

let intervalId: ReturnType<typeof setInterval> | undefined
let started = false

export function startOurAirportsSyncScheduler(): void {
  if (started) return
  started = true

  if (process.env.NODE_ENV === 'test') return
  if (process.env.OURAIRPORTS_SYNC_DISABLED === '1' || process.env.OURAIRPORTS_SYNC_DISABLED === 'true') {
    console.log('[ourairports] sync disabled (OURAIRPORTS_SYNC_DISABLED)')
    return
  }

  const intervalMs = getIntervalMs()
  const run = () => {
    void syncOurAirportsFromWeb()
  }

  setTimeout(run, 15_000)
  intervalId = setInterval(run, intervalMs)
  console.log(
    `[ourairports] scheduler: first run in ~15s, then every ${intervalMs} ms (OURAIRPORTS_SYNC_INTERVAL_MS)`
  )
}

/** Test helper: stop periodic sync. */
export function stopOurAirportsSyncSchedulerForTests(): void {
  if (intervalId !== undefined) {
    clearInterval(intervalId)
    intervalId = undefined
  }
  started = false
}
