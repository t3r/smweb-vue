import * as countryRepo from '../repositories/countryRepository.js'
import { cache, cacheTtlSeconds } from '../config/cache.js'

const CACHE_KEY_COUNTRIES = 'countries:all'

export async function getCountries(): Promise<{ countries: import('../repositories/countryRepository.js').CountryRow[] }> {
  if (cacheTtlSeconds > 0) {
    const cached = cache.get<{ countries: import('../repositories/countryRepository.js').CountryRow[] }>(CACHE_KEY_COUNTRIES)
    if (cached) return cached
  }
  const countries = await countryRepo.findAll()
  const result = { countries }
  if (cacheTtlSeconds > 0) cache.set(CACHE_KEY_COUNTRIES, result, cacheTtlSeconds)
  return result
}

export async function getCountryAt(
  longitude: number,
  latitude: number
): Promise<{ country: import('../repositories/countryRepository.js').CountryRow | null }> {
  const country = await countryRepo.findCountryAt(longitude, latitude)
  return { country }
}
