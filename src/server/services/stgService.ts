import * as stgRepository from '../repositories/stgRepository.js'

/** Packed FG scenery tile index (see FlightGear tile index scheme). */
const MAX_TILE = (1 << 22) - 1

export type ParseTileResult =
  | { ok: true; tile: number }
  | { ok: false; message: string }

export function parseTileParam(raw: string): ParseTileResult {
  if (raw == null || String(raw).trim() === '') {
    return { ok: false, message: 'Tile number is required' }
  }
  const tile = Number(raw)
  if (!Number.isInteger(tile) || tile < 0 || tile > MAX_TILE) {
    return { ok: false, message: 'Invalid tile number' }
  }
  return { ok: true, tile }
}

export async function getStgForTile(tile: number): Promise<string | null> {
  return stgRepository.dumpStgForTile(tile)
}
