import type { Request, Response } from 'express'
import * as requestRepo from '../repositories/requestRepository.js'
import { getPreviewDataFromPackageBuffer } from '../services/modelService.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'

export async function getList(req: Request, res: Response): Promise<void> {
  try {
    const { ok, failed } = await requestRepo.getPendingRequests()
    res.json({
      pending: ok.map(({ id, sig, type, email, comment, details, authorId }) => ({
        id,
        sig,
        type,
        email,
        comment,
        details,
        authorId: authorId ?? null,
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
    const modelfilesBase64 = (model?.modelfiles ?? model?.modelfile) as string | undefined
    if (!modelfilesBase64 || typeof modelfilesBase64 !== 'string') {
      res.status(404).json({ error: 'No model package in request' })
      return
    }
    let buffer: Buffer
    try {
      buffer = Buffer.from(modelfilesBase64, 'base64')
    } catch {
      res.status(400).json({ error: 'Invalid model package encoding' })
      return
    }
    const data = getPreviewDataFromPackageBuffer(buffer)
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
