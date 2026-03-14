import type { Request, Response } from 'express'
import * as objectService from '../services/objectService.js'
import * as requestRepo from '../repositories/requestRepository.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'
import {
  validateId,
  validateCountry,
  validateDescriptionSearch,
  validateOptionalInt,
  validateOffset,
  validateLimit,
} from '../utils/validateInput.js'

const OBJECT_SORT_FIELDS = new Set(['id', 'description', 'type', 'country', 'lastUpdated', 'lat', 'lon'])

export async function getObjects(req: Request, res: Response): Promise<void> {
  try {
    const { offset, limit, country, group, model, sortField, sortOrder, description } = req.query
    const offsetVal = validateOffset(offset)
    const limitVal = validateLimit(limit)
    const countryParam = validateCountry(country)
    const groupParam = validateOptionalInt(group)
    const modelParam = validateOptionalInt(model)
    const sortFieldVal = sortField && OBJECT_SORT_FIELDS.has(String(sortField)) ? String(sortField) : null
    const sortOrderVal = sortOrder != null ? (Number(sortOrder) === 1 ? 1 : -1) : null
    const descriptionParam = validateDescriptionSearch(description)
    const data = await objectService.getObjects(
      offsetVal,
      limitVal,
      countryParam,
      groupParam,
      sortFieldVal,
      sortOrderVal,
      descriptionParam,
      modelParam
    )
    const { objectIds: pendingObjectIds } = await requestRepo.getPendingEntityIds()
    const pendingSet = new Set(pendingObjectIds)
    const objects = (data.objects || []).map((o) => {
      const row = o as unknown as { id: number; [key: string]: unknown }
      return {
        ...row,
        hasPendingRequest: pendingSet.has(row.id),
      }
    })
    res.json({ ...data, objects })
  } catch (err) {
    logDbError(err, 'GET /api/objects')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function searchObjects(req: Request, res: Response): Promise<void> {
  try {
    const { model, lat, lon, country, description } = req.query
    const modelVal = validateOptionalInt(model)
    const countryVal = validateCountry(country)
    const descriptionVal = validateDescriptionSearch(description)
    const data = await objectService.searchObjects({
      model: modelVal ?? undefined,
      lat: lat != null ? Number(lat) : undefined,
      lon: lon != null ? Number(lon) : undefined,
      country: countryVal ?? undefined,
      description: descriptionVal ?? undefined,
    })
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/objects/search')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getObjectsForMap(req: Request, res: Response): Promise<void> {
  try {
    const raw = req.query.bbox
    const limit = req.query.limit != null ? Math.min(5000, Math.max(1, Number(req.query.limit) || 2000)) : 2000
    let bbox: { minLng: number; minLat: number; maxLng: number; maxLat: number } | null = null
    if (typeof raw === 'string') {
      const parts = raw.split(',').map((s) => Number(s.trim()))
      if (parts.length === 4 && parts.every(Number.isFinite)) {
        bbox = { minLng: parts[0], minLat: parts[1], maxLng: parts[2], maxLat: parts[3] }
      }
    }
    if (!bbox) {
      res.status(400).json({ error: 'Missing or invalid bbox (minLng,minLat,maxLng,maxLat)' })
      return
    }
    const spanLon = bbox.maxLng - bbox.minLng
    const spanLat = bbox.maxLat - bbox.minLat
    const maxSpan = 120
    if (spanLon > maxSpan || spanLat > maxSpan) {
      res.status(400).json({
        error: 'Zoom in to load objects',
        code: 'BBOX_TOO_LARGE',
        message: `Bbox too large (max ${maxSpan}° span). Zoom in to reduce the visible area.`,
      })
      return
    }
    const data = await objectService.getObjectsForMap(bbox, limit)
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/objects/map')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getObject(req: Request, res: Response): Promise<void> {
  try {
    const paramId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id
    const id = validateId(typeof paramId === 'string' ? paramId : String(paramId ?? ''))
    if (id == null) {
      res.status(400).json({ error: 'Invalid object id' })
      return
    }
    const obj = await objectService.getObjectById(id)
    if (!obj) {
      res.status(404).json({ error: 'Object not found' })
      return
    }
    const { objectIds: pendingObjectIds } = await requestRepo.getPendingEntityIds()
    const hasPendingRequest = pendingObjectIds.includes(obj.id)
    res.json({ ...obj, hasPendingRequest })
  } catch (err) {
    logDbError(err, 'GET /api/objects/:id')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function createObject(req: Request, res: Response): Promise<void> {
  res.status(201).json({ id: 999, ...req.body })
}

export async function updateObject(req: Request, res: Response): Promise<void> {
  const idParam = req.params.id
  const id = parseInt(Array.isArray(idParam) ? idParam[0] : idParam ?? '', 10)
  res.json({ id, ...req.body })
}

export async function deleteObject(req: Request, res: Response): Promise<void> {
  res.status(204).send()
}
