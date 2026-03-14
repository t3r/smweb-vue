import * as statisticsRepo from '../repositories/statisticsRepository.js'

export interface StatisticsResult {
  date: unknown
  models: number
  objects: number
  authors: number
}

export async function getLatest(): Promise<StatisticsResult> {
  const row = await statisticsRepo.findLatest()
  if (!row) {
    return { date: null, models: 0, objects: 0, authors: 0 }
  }
  return {
    date: row.date,
    models: Number(row.models) || 0,
    objects: Number(row.objects) || 0,
    authors: Number(row.authors) || 0,
  }
}
