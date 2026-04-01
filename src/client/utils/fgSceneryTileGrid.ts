/**
 * FlightGear scenery tile grid (SGBucket-style), per
 * https://wiki.flightgear.org/Tile_Index_Scheme
 * Authoritative: simgear/bucket/newbucket.{hxx,cxx}
 */

/** First matching `lat >= lo` wins (same order as wiki Python). */
const WIDTH_AT_LO: readonly { lo: number; tw: number }[] = [
  { lo: 89, tw: 12 },
  { lo: 86, tw: 4 },
  { lo: 83, tw: 2 },
  { lo: 76, tw: 1 },
  { lo: 62, tw: 0.5 },
  { lo: 22, tw: 0.25 },
  { lo: -22, tw: 0.125 },
  { lo: -62, tw: 0.25 },
  { lo: -76, tw: 0.5 },
  { lo: -83, tw: 1 },
  { lo: -86, tw: 2 },
  { lo: -89, tw: 4 },
  { lo: -90, tw: 12 },
] as const

/** Latitude boundaries between constant zonal tile widths (half-open strips [lo, hi)). */
const ZONAL_LAT_EDGES = [-90, -89, -86, -83, -76, -62, -22, 22, 62, 76, 83, 86, 89, 90] as const

export function getFgTileWidthDeg(lat: number): number {
  for (const { lo, tw } of WIDTH_AT_LO) {
    if (lat >= lo) return tw
  }
  return 12
}

/** Bit-packed index (wiki). */
export function fgTileIndex(lat: number, lon: number): number {
  const tw = getFgTileWidthDeg(lat)
  const baseY = Math.floor(lat)
  const y = Math.trunc((lat - baseY) * 8)
  const baseX = Math.floor(Math.floor(lon / tw) * tw)
  const x = Math.floor((lon - baseX) / tw)
  return ((baseX + 180) << 14) + ((baseY + 90) << 6) + (y << 3) + x
}

export type LngLatBounds = { west: number; south: number; east: number; north: number }

export type FgTileGridBuildOptions = {
  maxSegments?: number
  /** If true, skip horizontal 1/8° lines (meridians only) when over horizontal budget. */
  meridiansOnly?: boolean
}

const DEG_EPS = 1e-9

function emptyGrid(): GeoJSON.Feature<GeoJSON.MultiLineString> {
  return {
    type: 'Feature',
    properties: {},
    geometry: { type: 'MultiLineString', coordinates: [] },
  }
}

type Band = { lo: number; hi: number; tw: number; lat0: number; lat1: number }

function collectBands(south: number, north: number): Band[] {
  const out: Band[] = []
  for (let i = 0; i < ZONAL_LAT_EDGES.length - 1; i++) {
    const lo = ZONAL_LAT_EDGES[i]
    const hi = ZONAL_LAT_EDGES[i + 1]
    const tw = getFgTileWidthDeg((lo + hi) / 2)
    const lat0 = Math.max(south, lo)
    const lat1 = Math.min(north, hi - DEG_EPS)
    if (lat1 > lat0 + DEG_EPS) out.push({ lo, hi, tw, lat0, lat1 })
  }
  return out
}

/** Count meridian segments if drawn at full resolution for one band. */
function countMeridiansInBand(west: number, east: number, tw: number): number {
  let n = 0
  let lon = Math.floor(west / tw) * tw
  let iter = 0
  while (lon <= east + DEG_EPS && iter < 50000) {
    iter++
    if (lon >= west - DEG_EPS && lon <= east + DEG_EPS) n++
    lon += tw
  }
  return n
}

/**
 * Build GeoJSON MultiLineString segments for FG tile edges visible in `bounds`.
 * Vertical density is subsampled per zonal band so MapLibre is not fed thousands of lines.
 */
export function buildFgTileGridGeoJSON(
  bounds: LngLatBounds,
  options?: FgTileGridBuildOptions
): GeoJSON.Feature<GeoJSON.MultiLineString> {
  const maxSeg = options?.maxSegments ?? 900
  const meridiansOnly = options?.meridiansOnly ?? false
  let west = bounds.west
  let east = bounds.east
  const south = Math.max(-90, Math.min(90, bounds.south))
  const north = Math.max(-90, Math.min(90, bounds.north))

  if (north <= south + DEG_EPS) {
    return emptyGrid()
  }
  if (east < west) {
    return emptyGrid()
  }
  if (east - west > 350) {
    return emptyGrid()
  }
  west = Math.max(-180, Math.min(180, west))
  east = Math.max(-180, Math.min(180, east))
  if (east <= west + DEG_EPS) {
    return emptyGrid()
  }

  const coordinates: GeoJSON.Position[][] = []

  function pushSeg(a: GeoJSON.Position, b: GeoJSON.Position) {
    if (coordinates.length >= maxSeg) return
    coordinates.push([a, b])
  }

  const bands = collectBands(south, north)

  // --- Horizontal edges (1/8°): usually far fewer than meridians; cap share of budget ---
  const horizBudget = meridiansOnly ? 0 : Math.min(320, Math.floor(maxSeg * 0.35))
  if (!meridiansOnly && horizBudget > 0) {
    const baseYMin = Math.floor(south - DEG_EPS)
    const baseYMax = Math.floor(north + DEG_EPS)
    outer: for (let baseY = baseYMin; baseY <= baseYMax; baseY++) {
      for (let k = 0; k <= 8; k++) {
        if (coordinates.length >= horizBudget) break outer
        const lat = baseY + k / 8
        if (lat < south - DEG_EPS || lat > north + DEG_EPS) continue
        pushSeg([west, lat], [east, lat])
      }
    }
  }

  const remaining = maxSeg - coordinates.length
  if (remaining < 4 || bands.length === 0) {
    return { type: 'Feature', properties: {}, geometry: { type: 'MultiLineString', coordinates } }
  }

  // --- Vertical edges: split remaining budget across zonal bands; subsample meridians ---
  const bandCounts = bands.map((b) => ({
    ...b,
    nFull: countMeridiansInBand(west, east, b.tw),
  }))
  const totalFullMeridians = bandCounts.reduce((s, b) => s + b.nFull, 0)
  let perBand = Math.max(6, Math.floor(remaining / bands.length))
  if (totalFullMeridians > remaining * 1.2) {
    perBand = Math.max(4, Math.floor(remaining / bands.length))
  }

  for (const { tw, lat0, lat1, nFull } of bandCounts) {
    if (coordinates.length >= maxSeg) break
    const room = maxSeg - coordinates.length
    const budget = Math.min(perBand, room)
    const step = nFull <= budget ? 1 : Math.max(1, Math.ceil(nFull / Math.max(1, budget)))

    let lon = Math.floor(west / tw) * tw
    let meridianIndex = 0
    let iter = 0
    while (lon <= east + DEG_EPS && iter < 50000 && coordinates.length < maxSeg) {
      iter++
      if (lon >= west - DEG_EPS && lon <= east + DEG_EPS) {
        if (meridianIndex % step === 0) {
          pushSeg([lon, lat0], [lon, lat1])
        }
        meridianIndex++
      }
      lon += tw
    }
  }

  return { type: 'Feature', properties: {}, geometry: { type: 'MultiLineString', coordinates } }
}

export function fgTileGridFeatureCollection(
  bounds: LngLatBounds,
  options?: FgTileGridBuildOptions
): GeoJSON.FeatureCollection {
  return {
    type: 'FeatureCollection',
    features: [buildFgTileGridGeoJSON(bounds, options)],
  }
}
