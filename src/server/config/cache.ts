import NodeCache from 'node-cache'
import dotenv from 'dotenv'

dotenv.config()

/**
 * Cache TTL in seconds. From env CACHE_TTL_SECONDS (default 0 = caching disabled).
 * CACHE_TTL_MINUTES is supported and converted to seconds if CACHE_TTL_SECONDS is not set.
 */
function getTtlSeconds(): number {
  const fromSeconds = Number(process.env.CACHE_TTL_SECONDS)
  if (Number.isInteger(fromSeconds) && fromSeconds >= 0) return fromSeconds
  const fromMinutes = Number(process.env.CACHE_TTL_MINUTES)
  if (Number.isInteger(fromMinutes) && fromMinutes >= 0) return fromMinutes * 60
  return 0
}

const cacheTtlSeconds = getTtlSeconds()

const cache = new NodeCache({
  stdTTL: cacheTtlSeconds > 0 ? cacheTtlSeconds : 600,
  useClones: false,
})

export { cache, cacheTtlSeconds }
