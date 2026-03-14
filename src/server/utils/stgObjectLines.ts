import * as modelRepo from '../repositories/modelRepository.js'
import * as countryRepo from '../repositories/countryRepository.js'

/** Max non-blank lines per submission (legacy PHP mass form). */
export const STG_MASS_IMPORT_MAX_LINES = 100

/** Same character class as legacy FormChecker `model_filepath`. */
const MODEL_PATH_RE = /^[a-z0-9_/.-]+$/i

export function headingSTG2True(stgHeading: number): number {
  if (stgHeading > 180) return 540 - stgHeading
  return 180 - stgHeading
}

function basenameFromModelPath(path: string): string {
  const parts = path.split('/').filter(Boolean)
  return parts.length > 0 ? parts[parts.length - 1]! : path
}

export interface StgLineError {
  line: number
  text: string
  messages: string[]
}

export interface StgResolvedObject {
  modelId: number
  lat: number
  lon: number
  country: string
  elevationOffset: number
  heading: number
  description: string
}

export type ParseStgResult =
  | { ok: true; objects: StgResolvedObject[] }
  | { ok: false; lineErrors: StgLineError[] }

export function isStgParseFailure(r: ParseStgResult): r is { ok: false; lineErrors: StgLineError[] } {
  return r.ok === false
}

function normalizeLines(stg: string): string[] {
  return stg
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l.length > 0)
    .slice(0, STG_MASS_IMPORT_MAX_LINES)
}

/**
 * Parse OBJECT_SHARED STG lines like the legacy PHP mass form.
 * Format: OBJECT_SHARED &lt;model path&gt; &lt;lon&gt; &lt;lat&gt; &lt;ground elev&gt; &lt;STG heading&gt; [elevation offset if exactly 7 tokens]
 */
export async function parseStgObjectLines(stg: string): Promise<ParseStgResult> {
  const lines = normalizeLines(stg)
  if (lines.length < 1) {
    return {
      ok: false as const,
      lineErrors: [{ line: 0, text: '', messages: ['At least one non-blank line is required'] }],
    }
  }

  const lineErrors: StgLineError[] = []
  const objects: StgResolvedObject[] = []

  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i]!
    const lineNo = i + 1
    const messages: string[] = []
    const tokens = raw.split(/\s+/).filter(Boolean)

    if (tokens[0] !== 'OBJECT_SHARED') {
      messages.push('Only OBJECT_SHARED lines are supported')
    }

    const path = tokens[1]
    if (!path || !MODEL_PATH_RE.test(path)) {
      messages.push('Invalid or missing model path')
    }

    if (tokens.length < 6) {
      messages.push('Not enough fields (expected at least: OBJECT_SHARED path lon lat ground_elev heading)')
    }

    let modelId: number | null = null
    if (path && MODEL_PATH_RE.test(path)) {
      const basename = basenameFromModelPath(path)
      modelId = await modelRepo.findIdByPathBasename(basename)
      if (modelId == null) {
        messages.push(`Model not found for path basename "${basename}"`)
      }
    }

    const lon = tokens.length > 2 ? Number(tokens[2]) : NaN
    const lat = tokens.length > 3 ? Number(tokens[3]) : NaN
    if (!Number.isFinite(lon) || !Number.isFinite(lat)) {
      messages.push('Longitude and latitude must be valid numbers')
    }

    const stgHeading = tokens.length > 5 ? Number(tokens[5]) : NaN
    if (!Number.isFinite(stgHeading)) {
      messages.push('STG heading (6th field) must be a valid number')
    }

    let elevationOffset = 0
    if (tokens.length === 7) {
      const off = Number(tokens[6])
      if (!Number.isFinite(off)) {
        messages.push('Elevation offset (7th field) must be a valid number')
      } else {
        elevationOffset = off
      }
    }

    let countryCode = ''
    if (Number.isFinite(lon) && Number.isFinite(lat)) {
      const country = await countryRepo.findCountryAt(lon, lat)
      if (!country?.code) {
        messages.push('Could not resolve country at this position')
      } else {
        countryCode = country.code
      }
    }

    if (messages.length > 0) {
      lineErrors.push({ line: lineNo, text: raw, messages })
      continue
    }

    const trueHeading = headingSTG2True(stgHeading)

    objects.push({
      modelId: modelId!,
      lat,
      lon,
      country: countryCode,
      elevationOffset,
      heading: trueHeading,
      description: '',
    })
  }

  if (lineErrors.length > 0) {
    return { ok: false as const, lineErrors }
  }

  return { ok: true as const, objects }
}
