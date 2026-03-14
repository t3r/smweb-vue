import * as objectRepo from '../repositories/objectRepository.js'
import type { MapObject, Bbox } from '../repositories/objectRepository.js'

const MAP_BBOX_LIMIT_DEFAULT = 2000
const MAP_BBOX_LIMIT_MAX = 5000
const MAP_OBJECTS_THRESHOLD = 2000

export async function getObjects(
  offset = 0,
  limit = 20,
  country: string | null = null,
  group: number | null = null,
  sortField: string | null = null,
  sortOrder: number | null = null,
  description: string | null = null,
  model: number | null = null
): Promise<{ objects: MapObject[]; total: number; offset: number; limit: number }> {
  const opts: Record<string, unknown> = { offset, limit }
  if (country != null) opts.country = country
  if (group != null) opts.group = Number(group)
  if (model != null && Number.isInteger(model) && model > 0) opts.model = model
  if (sortField != null) opts.sortField = sortField
  if (sortOrder != null) opts.sortOrder = sortOrder === 1 ? 1 : -1
  if (description != null && String(description).trim() !== '') opts.description = String(description).trim()
  const { objects, total } = await objectRepo.findAndCountAll(opts as objectRepo.FindAllObjectsOptions)
  return {
    objects,
    total,
    offset: Number(offset),
    limit: Number(limit),
  }
}

export async function searchObjects(query: {
  model?: number
  lat?: number
  lon?: number
  country?: string
  description?: string
}): Promise<{ objects: MapObject[]; total: number }> {
  const { model, country, description } = query
  const { objects, total } = await objectRepo.findAndCountAll({
    offset: 0,
    limit: 100,
    model: model != null ? Number(model) : undefined,
    country: country || undefined,
    description: description || undefined,
  })
  return { objects, total }
}

export async function getObjectById(id: number): Promise<MapObject | null> {
  return objectRepo.findById(id)
}

export async function getObjectsForMap(
  bbox: Bbox,
  limit = MAP_BBOX_LIMIT_DEFAULT
): Promise<
  | { objects: MapObject[] }
  | { grid: { minLng: number; minLat: number; maxLng: number; maxLat: number; cols: number; rows: number; cells: { x: number; y: number; count: number }[] } }
> {
  if (
    !bbox ||
    typeof (bbox as Bbox).minLng !== 'number' ||
    typeof (bbox as Bbox).minLat !== 'number' ||
    typeof (bbox as Bbox).maxLng !== 'number' ||
    typeof (bbox as Bbox).maxLat !== 'number'
  ) {
    return { objects: [] }
  }
  const count = await objectRepo.findCountInBbox(bbox)
  if (count <= MAP_OBJECTS_THRESHOLD) {
    const cappedLimit = Math.min(Math.max(1, Number(limit) || MAP_BBOX_LIMIT_DEFAULT), MAP_BBOX_LIMIT_MAX)
    const { objects } = await objectRepo.findForMap(bbox, cappedLimit)
    return { objects }
  }
  const { cols, rows, cells } = await objectRepo.findGridCountsInBbox(bbox)
  return {
    grid: {
      minLng: bbox.minLng,
      minLat: bbox.minLat,
      maxLng: bbox.maxLng,
      maxLat: bbox.maxLat,
      cols,
      rows,
      cells,
    },
  }
}
