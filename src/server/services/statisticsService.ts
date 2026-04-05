import * as statisticsRepo from '../repositories/statisticsRepository.js'
import * as requestRepo from '../repositories/requestRepository.js'

export interface StatisticsResult {
  date: unknown
  models: number
  objects: number
  authors: number
  pendingRequests: number
}

export interface StatisticsHistoryPoint {
  /** ISO calendar date `YYYY-MM-DD`. */
  date: string
  models: number
  objects: number
  authors: number
}

function normalizeStatsDate(value: unknown): string {
  if (value == null) return ''
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value.toISOString().slice(0, 10)
  }
  const s = String(value).trim()
  if (/^\d{4}-\d{2}-\d{2}/.test(s)) return s.slice(0, 10)
  const t = Date.parse(s)
  if (!Number.isNaN(t)) return new Date(t).toISOString().slice(0, 10)
  return ''
}

export async function getLatest(): Promise<StatisticsResult> {
  const [row, pendingRequests] = await Promise.all([
    statisticsRepo.findLatest(),
    requestRepo.countPendingRequests(),
  ])
  const pending = Number(pendingRequests) || 0
  if (!row) {
    return { date: null, models: 0, objects: 0, authors: 0, pendingRequests: pending }
  }
  return {
    date: row.date,
    models: Number(row.models) || 0,
    objects: Number(row.objects) || 0,
    authors: Number(row.authors) || 0,
    pendingRequests: pending,
  }
}

export async function getHistory(): Promise<{ series: StatisticsHistoryPoint[] }> {
  const rows = await statisticsRepo.findAllByDateAsc()
  const series: StatisticsHistoryPoint[] = []
  for (const row of rows) {
    const date = normalizeStatsDate(row.date)
    if (!date) continue
    series.push({
      date,
      models: Number(row.models) || 0,
      objects: Number(row.objects) || 0,
      authors: Number(row.authors) || 0,
    })
  }
  return { series }
}
