import * as modelgroupRepo from '../repositories/modelgroupRepository.js'
import { cache, cacheTtlSeconds } from '../config/cache.js'

const CACHE_KEY_MODEL_GROUPS = 'modelgroups:all'

export async function getModelGroups(): Promise<{
  groups: import('../repositories/modelgroupRepository.js').ModelGroupRow[]
}> {
  if (cacheTtlSeconds > 0) {
    const cached = cache.get<{ groups: import('../repositories/modelgroupRepository.js').ModelGroupRow[] }>(CACHE_KEY_MODEL_GROUPS)
    if (cached) return cached
  }
  const groups = await modelgroupRepo.findAll()
  const result = { groups }
  if (cacheTtlSeconds > 0) cache.set(CACHE_KEY_MODEL_GROUPS, result, cacheTtlSeconds)
  return result
}
