import type { Request, Response } from 'express'
import * as modelService from '../services/modelService.js'
import * as modelRepo from '../repositories/modelRepository.js'
import * as requestRepo from '../repositories/requestRepository.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'
import {
  validateId,
  validateOptionalInt,
  validateOffset,
  validateLimit,
  validateFileName,
  validateDescriptionSearch,
} from '../utils/validateInput.js'

const MODEL_SORT_FIELDS = new Set(['id', 'name', 'lastUpdated', 'group', 'author'])

export async function getModels(req: Request, res: Response): Promise<void> {
  try {
    const { offset, limit, group, author, sortField, sortOrder, search, authorSearch } = req.query
    const sortFieldVal = sortField && MODEL_SORT_FIELDS.has(String(sortField)) ? String(sortField) : null
    const sortOrderVal = sortOrder != null ? (Number(sortOrder) === 1 ? 1 : -1) : null
    const searchVal = validateDescriptionSearch(search)
    const authorSearchVal = validateDescriptionSearch(authorSearch)
    const data = await modelService.getModels(
      validateOffset(offset),
      validateLimit(limit),
      validateOptionalInt(group),
      validateOptionalInt(author),
      sortFieldVal,
      sortOrderVal,
      searchVal,
      authorSearchVal
    )
    const { modelIds: pendingModelIds } = await requestRepo.getPendingEntityIds()
    const pendingSet = new Set(pendingModelIds)
    const models = (data.models || []).map((m) => {
      const row = m as { id: number; [key: string]: unknown }
      return {
        ...row,
        hasPendingRequest: pendingSet.has(row.id),
      }
    })
    res.json({ ...data, models })
  } catch (err) {
    logDbError(err, 'GET /api/models')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getRecentModels(req: Request, res: Response): Promise<void> {
  try {
    const data = await modelService.getRecentModels(10)
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/models/recent')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getModel(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    if (id == null) {
      res.status(400).json({ error: 'Invalid model id' })
      return
    }
    const model = await modelService.getModelById(id)
    if (!model) {
      res.status(404).json({ error: 'Model not found' })
      return
    }
    const { modelIds: pendingModelIds } = await requestRepo.getPendingEntityIds()
    const hasPendingRequest = pendingModelIds.includes((model as { id: number }).id)
    res.json({ ...model, hasPendingRequest })
  } catch (err) {
    logDbError(err, 'GET /api/models/:id')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getModelThumbnail(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    if (id == null) {
      res.status(400).send()
      return
    }
    const thumb = await modelRepo.findThumbnailById(id)
    if (!thumb?.buffer) {
      res.status(404).json({ error: 'Thumbnail not found' })
      return
    }
    res.type('image/jpeg').send(thumb.buffer)
  } catch (err) {
    logDbError(err, 'GET /api/models/:id/thumbnail')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getModelFiles(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    if (id == null) {
      res.status(400).json({ error: 'Invalid model id' })
      return
    }
    const model = await modelService.getModelById(id)
    if (!model) {
      res.status(404).json({ error: 'Model not found' })
      return
    }
    const data = await modelService.getModelFiles(id)
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/models/:id/files')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getModelFile(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    const name = validateFileName(req.query.name)
    if (id == null) {
      res.status(400).json({ error: 'Invalid model id' })
      return
    }
    if (name == null) {
      res.status(400).json({ error: 'Missing or invalid name query parameter' })
      return
    }
    const model = await modelService.getModelById(id)
    if (!model) {
      res.status(404).json({ error: 'Model not found' })
      return
    }
    const result = await modelService.getModelFileContent(id, name)
    if (!result) {
      res.status(404).json({ error: 'File not found in model' })
      return
    }
    const ext = name.includes('.') ? name.slice(name.lastIndexOf('.')) : ''
    const mime: Record<string, string> = {
      '.ac': 'application/octet-stream',
      '.xml': 'application/xml',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.tga': 'image/x-tga',
    }
    const contentType = mime[ext.toLowerCase()] || 'application/octet-stream'
    const safeName = result.filename.replace(/["\r\n]/g, '_')
    res.setHeader('Content-Disposition', `attachment; filename="${safeName}"`)
    res.type(contentType).send(result.buffer)
  } catch (err) {
    logDbError(err, 'GET /api/models/:id/file')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getModelPackage(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    if (id == null) {
      res.status(400).send()
      return
    }
    const model = await modelService.getModelById(id)
    if (!model) {
      res.status(404).json({ error: 'Model not found' })
      return
    }
    const buffer = await modelService.getModelPackageBuffer(id)
    if (!buffer || buffer.length === 0) {
      res.status(404).json({ error: 'Model package not available' })
      return
    }
    const filename = `model-${id}.tar.gz`
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`)
    res.type('application/gzip').send(buffer)
  } catch (err) {
    logDbError(err, 'GET /api/models/:id/package')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getModelPreview(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    if (id == null) {
      res.status(400).json({ error: 'Invalid model id' })
      return
    }
    const model = await modelService.getModelById(id)
    if (!model) {
      res.status(404).json({ error: 'Model not found' })
      return
    }
    const data = await modelService.getModelPreviewData(id)
    if (!data) {
      res.status(404).json({ error: 'No AC3D file in model package or parse failed' })
      return
    }
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/models/:id/preview')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function createModel(req: Request, res: Response): Promise<void> {
  res.status(501).json({ error: 'Add model not implemented; use submission workflow when available' })
}

export async function updateModel(req: Request, res: Response): Promise<void> {
  res.status(501).json({ error: 'Update model not implemented; use submission workflow when available' })
}
