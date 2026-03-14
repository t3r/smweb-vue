import type { Request, Response } from 'express'
import * as emailQueueRepo from '../repositories/emailQueueRepository.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

function parsePositiveInt(v: unknown, fallback: number, min: number, max: number): number {
  const n = v != null ? Number(v) : NaN
  if (!Number.isFinite(n)) return fallback
  return Math.min(max, Math.max(min, Math.floor(n)))
}

export async function receive(req: Request, res: Response): Promise<void> {
  try {
    const body = (req.body || {}) as { batchSize?: unknown; visibilityTimeoutSeconds?: unknown }
    const batchSize = parsePositiveInt(body.batchSize, 10, 1, 50)
    const visibilityTimeoutSeconds = parsePositiveInt(body.visibilityTimeoutSeconds, 300, 30, 86400)

    const messages = await emailQueueRepo.receiveBatch(batchSize, visibilityTimeoutSeconds)
    res.json({
      messages,
      visibilityTimeoutSeconds,
    })
  } catch (err) {
    logDbError(err, 'POST /api/email-queue/receive')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function deleteMessage(req: Request, res: Response): Promise<void> {
  try {
    const body = (req.body || {}) as { eqId?: unknown; receiptHandle?: unknown }
    const eqId = body.eqId != null ? Number(body.eqId) : NaN
    const receiptHandle = typeof body.receiptHandle === 'string' ? body.receiptHandle.trim() : ''

    if (!Number.isInteger(eqId) || eqId < 1) {
      res.status(400).json({ error: 'eqId must be a positive integer' })
      return
    }
    if (!receiptHandle || !UUID_RE.test(receiptHandle)) {
      res.status(400).json({ error: 'receiptHandle must be a UUID' })
      return
    }

    const deleted = await emailQueueRepo.deleteMessage(eqId, receiptHandle)
    if (!deleted) {
      res.status(404).json({ error: 'Message not found or receipt handle does not match' })
      return
    }
    res.json({ success: true, deleted: true })
  } catch (err) {
    logDbError(err, 'POST /api/email-queue/delete')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
