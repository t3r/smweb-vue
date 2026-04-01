import * as statisticsRepo from '../repositories/statisticsRepository.js'
import * as requestRepo from '../repositories/requestRepository.js'

export interface StatisticsResult {
  date: unknown
  models: number
  objects: number
  authors: number
  pendingRequests: number
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
