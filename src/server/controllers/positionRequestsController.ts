import type { Request, Response } from 'express'
import * as requestRepo from '../repositories/requestRepository.js'
import { getPreviewDataFromPackageBuffer } from '../services/modelService.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'
import { listTarEntries, getTarFileContent } from '../utils/tarList.js'
import { validateFileName } from '../utils/validateInput.js'

type PendingPkgOk = { ok: true; buffer: Buffer }
type PendingPkgErr = { ok: false; status: number; error: string }
type PendingPkgLoad = PendingPkgOk | PendingPkgErr

function isPendingPkgErr(r: PendingPkgLoad): r is PendingPkgErr {
  return r.ok === false
}

async function loadPendingModelAddPackage(sig: string): Promise<PendingPkgLoad> {
  if (!sig || typeof sig !== 'string') {
    const err: PendingPkgErr = { ok: false, status: 400, error: 'Missing sig' }
    return err
  }
  const request = await requestRepo.getRequestBySig(sig)
  if (!request) {
    const err: PendingPkgErr = { ok: false, status: 404, error: 'Request not found or already processed' }
    return err
  }
  if (request.type !== 'MODEL_ADD' || !request.content || typeof request.content !== 'object') {
    const err: PendingPkgErr = { ok: false, status: 400, error: 'Not a MODEL_ADD request or no content' }
    return err
  }
  const content = request.content as Record<string, unknown>
  const model = content.model as Record<string, unknown> | undefined
  const modelfilesBase64 = (model?.modelfiles ?? model?.modelfile) as string | undefined
  if (!modelfilesBase64 || typeof modelfilesBase64 !== 'string') {
    const err: PendingPkgErr = { ok: false, status: 404, error: 'No model package in request' }
    return err
  }
  try {
    const buffer = Buffer.from(modelfilesBase64, 'base64')
    const ok: PendingPkgOk = { ok: true, buffer }
    return ok
  } catch {
    const err: PendingPkgErr = { ok: false, status: 400, error: 'Invalid model package encoding' }
    return err
  }
}

function mimeForModelFileBasename(name: string): string {
  const ext = name.includes('.') ? name.slice(name.lastIndexOf('.')) : ''
  const mime: Record<string, string> = {
    '.ac': 'application/octet-stream',
    '.xml': 'application/xml',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.tga': 'image/x-tga',
  }
  return mime[ext.toLowerCase()] || 'application/octet-stream'
}

export async function getPendingCount(_req: Request, res: Response): Promise<void> {
  try {
    const count = await requestRepo.countPendingRequests()
    res.json({ count })
  } catch (err) {
    logDbError(err, 'GET /api/position-requests/pending-count')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getList(req: Request, res: Response): Promise<void> {
  try {
    const { ok, failed } = await requestRepo.getPendingRequests()
    res.json({
      pending: ok.map(({ id, sig, type, email, comment, details, authorId, authorName }) => ({
        id,
        sig,
        type,
        email,
        comment,
        details,
        authorId: authorId ?? null,
        authorName: authorName ?? null,
      })),
      failed: failed.map(({ id, sig, error }) => ({ id, sig, error })),
    })
  } catch (err) {
    logDbError(err, 'GET /api/position-requests')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getBySig(req: Request, res: Response): Promise<void> {
  try {
    const sig = Array.isArray(req.params.sig) ? req.params.sig[0] : req.params.sig
    if (!sig) {
      res.status(400).json({ error: 'Missing sig' })
      return
    }
    const request = await requestRepo.getRequestBySig(sig)
    if (!request) {
      res.status(404).json({ error: 'Request not found or already processed' })
      return
    }
    res.json(request)
  } catch (err) {
    logDbError(err, 'GET /api/position-requests/:sig')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getModelPreview(req: Request, res: Response): Promise<void> {
  try {
    const sig = Array.isArray(req.params.sig) ? req.params.sig[0] : req.params.sig
    const loaded = await loadPendingModelAddPackage(typeof sig === 'string' ? sig : '')
    if (isPendingPkgErr(loaded)) {
      res.status(loaded.status).json({ error: loaded.error })
      return
    }
    const data = getPreviewDataFromPackageBuffer(loaded.buffer)
    if (!data) {
      res.status(404).json({ error: 'No AC3D file in model package or parse failed' })
      return
    }
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/position-requests/:sig/model-preview')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

/** Tarball file listing for MODEL_ADD review (same archive as model-preview). */
export async function getRequestModelFiles(req: Request, res: Response): Promise<void> {
  try {
    const sig = Array.isArray(req.params.sig) ? req.params.sig[0] : req.params.sig
    const loaded = await loadPendingModelAddPackage(typeof sig === 'string' ? sig : '')
    if (isPendingPkgErr(loaded)) {
      res.status(loaded.status).json({ error: loaded.error })
      return
    }
    const files = listTarEntries(loaded.buffer)
    res.json({ files })
  } catch (err) {
    logDbError(err, 'GET /api/position-requests/:sig/model-files')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

/** Single file from pending MODEL_ADD package (reviewer download). */
export async function getRequestModelFile(req: Request, res: Response): Promise<void> {
  try {
    const sig = Array.isArray(req.params.sig) ? req.params.sig[0] : req.params.sig
    const name = validateFileName(req.query.name)
    const loaded = await loadPendingModelAddPackage(typeof sig === 'string' ? sig : '')
    if (isPendingPkgErr(loaded)) {
      res.status(loaded.status).json({ error: loaded.error })
      return
    }
    if (name == null) {
      res.status(400).json({ error: 'Missing or invalid name query parameter' })
      return
    }
    const buf = getTarFileContent(loaded.buffer, name)
    if (!buf) {
      res.status(404).json({ error: 'File not found in model package' })
      return
    }
    const contentType = mimeForModelFileBasename(name)
    const safeName = name.replace(/["\r\n]/g, '_')
    res.setHeader('Content-Disposition', `attachment; filename="${safeName}"`)
    res.type(contentType).send(buf)
  } catch (err) {
    logDbError(err, 'GET /api/position-requests/:sig/file')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

/** Full .tar.gz for pending MODEL_ADD (reviewer download). */
export async function getRequestModelPackage(req: Request, res: Response): Promise<void> {
  try {
    const sig = Array.isArray(req.params.sig) ? req.params.sig[0] : req.params.sig
    const loaded = await loadPendingModelAddPackage(typeof sig === 'string' ? sig : '')
    if (isPendingPkgErr(loaded)) {
      res.status(loaded.status).json({ error: loaded.error })
      return
    }
    const safe = (typeof sig === 'string' ? sig : 'request').replace(/[^a-f0-9]/gi, '').slice(0, 12) || 'submission'
    res.setHeader('Content-Disposition', `attachment; filename="model-${safe}.tar.gz"`)
    res.type('application/gzip').send(loaded.buffer)
  } catch (err) {
    logDbError(err, 'GET /api/position-requests/:sig/package')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

/** Stored submission JPEG (320×240 after processing), not a render from the 3D package. */
export async function getRequestModelThumbnail(req: Request, res: Response): Promise<void> {
  try {
    const sig = Array.isArray(req.params.sig) ? req.params.sig[0] : req.params.sig
    if (!sig) {
      res.status(400).json({ error: 'Missing sig' })
      return
    }
    const request = await requestRepo.getRequestBySig(sig)
    if (!request) {
      res.status(404).json({ error: 'Request not found or already processed' })
      return
    }
    if (request.type !== 'MODEL_ADD' || !request.content || typeof request.content !== 'object') {
      res.status(400).json({ error: 'Not a MODEL_ADD request or no content' })
      return
    }
    const content = request.content as Record<string, unknown>
    const model = content.model as Record<string, unknown> | undefined
    const thumbB64 = model?.thumbnail
    if (!thumbB64 || typeof thumbB64 !== 'string') {
      res.status(404).json({ error: 'No thumbnail in request' })
      return
    }
    let buffer: Buffer
    try {
      buffer = Buffer.from(thumbB64, 'base64')
    } catch {
      res.status(400).json({ error: 'Invalid thumbnail encoding' })
      return
    }
    if (!buffer.length) {
      res.status(404).json({ error: 'No thumbnail in request' })
      return
    }
    res.type('image/jpeg').send(buffer)
  } catch (err) {
    logDbError(err, 'GET /api/position-requests/:sig/thumbnail')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
