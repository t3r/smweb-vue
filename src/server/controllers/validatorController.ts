import type { Request, Response } from 'express'
import * as requestRepo from '../repositories/requestRepository.js'
import * as requestExecutor from '../services/requestExecutor.js'
import * as authorRepo from '../repositories/authorRepository.js'
import * as newsRepo from '../repositories/newsRepository.js'
import * as objectRepo from '../repositories/objectRepository.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'
import {
  enqueuePositionRequestAccepted,
  enqueuePositionRequestRejected,
} from '../services/emailQueueEnqueue.js'

/** Build news text for a processed position request. result is the return value of executeRequest (e.g. { modelId } for MODEL_ADD). */
function buildProcessedRequestNewsText(
  type: string,
  content: Record<string, unknown> | null,
  authorDisplay: string,
  reviewerDisplay: string,
  result?: unknown
): string {
  const author = authorDisplay || 'Unknown'
  const reviewer = reviewerDisplay || 'Unknown'
  const res = result as { modelId?: number; objectId?: number; objectIds?: number[] } | undefined
  const requestType = typeof type === 'string' ? type.trim() : ''
  if (!content || typeof content !== 'object') {
    return `${author} had a position request processed, reviewed by ${reviewer}.`
  }
  switch (requestType) {
    case 'OBJECT_UPDATE': {
      const objectId = content.objectId != null ? Number(content.objectId) : null
      const id = Number.isInteger(objectId) && objectId! > 0 ? objectId : null
      return id != null
        ? `${author} has made an update to object #${id}, reviewed by ${reviewer}.`
        : `${author} had an object update request processed, reviewed by ${reviewer}.`
    }
    case 'OBJECT_DELETE': {
      const objId = content.objId != null ? Number(content.objId) : null
      const id = Number.isInteger(objId) && objId! > 0 ? objId : null
      return id != null
        ? `${author} has had object #${id} deleted, reviewed by ${reviewer}.`
        : `${author} had an object delete request processed, reviewed by ${reviewer}.`
    }
    case 'OBJECTS_ADD': {
      const n = Array.isArray(res?.objectIds) ? res.objectIds.length : (Array.isArray(content) ? content.length : 0)
      return n > 0
        ? `${author} has added ${n} object(s), reviewed by ${reviewer}.`
        : `${author} had an objects-add request processed, reviewed by ${reviewer}.`
    }
    case 'MODEL_ADD': {
      const modelId = res?.modelId != null ? Number(res.modelId) : null
      const objectId = res?.objectId != null ? Number(res.objectId) : null
      const hasModel = modelId != null && Number.isInteger(modelId) && modelId > 0
      const hasObject = objectId != null && Number.isInteger(objectId) && objectId > 0
      if (hasModel && hasObject) {
        return `${author} has added model #${modelId} (object #${objectId}), reviewed by ${reviewer}.`
      }
      if (hasModel) {
        return `${author} has added model #${modelId}, reviewed by ${reviewer}.`
      }
      return `${author} has added a new model, reviewed by ${reviewer}.`
    }
    case 'MODEL_UPDATE': {
      const modelid = content.modelid ?? content.modelId
      const id = modelid != null ? Number(modelid) : null
      return id != null && Number.isInteger(id) && id > 0
        ? `${author} has made an update to model #${id}, reviewed by ${reviewer}.`
        : `${author} had a model update request processed, reviewed by ${reviewer}.`
    }
    case 'MODEL_DELETE': {
      const modelId = content.modelId ?? content.modelid
      const id = modelId != null ? Number(modelId) : null
      return id != null && Number.isInteger(id) && id > 0
        ? `${author} has had model #${id} deleted, reviewed by ${reviewer}.`
        : `${author} had a model delete request processed, reviewed by ${reviewer}.`
    }
    default:
      return `${author} had a position request (${requestType || type}) processed, reviewed by ${reviewer}.`
  }
}

export async function getPending(req: Request, res: Response): Promise<void> {
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
    logDbError(err, 'GET /api/submissions/pending')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getBySig(req: Request, res: Response): Promise<void> {
  try {
    const sig = Array.isArray(req.params.sig) ? req.params.sig[0] : req.params.sig
    const request = await requestRepo.getRequestBySig(sig)
    if (!request) {
      res.status(404).json({ error: 'Request not found or already processed' })
      return
    }
    res.json(request)
  } catch (err) {
    logDbError(err, 'GET /api/submissions/pending/:sig')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function accept(req: Request, res: Response): Promise<void> {
  try {
    const sig = Array.isArray(req.params.sig) ? req.params.sig[0] : req.params.sig
    const request = await requestRepo.getRequestBySig(sig)
    if (!request) {
      res.status(404).json({ error: 'Request not found or already processed' })
      return
    }
    const result = await requestExecutor.executeRequest(request)
    const authorByEmail = await authorRepo.findAuthorByEmail(request.email)
    const authorDisplay = authorByEmail?.name ?? request.email?.trim() ?? 'Unknown'
    const authorId = authorByEmail?.id ?? 0
    const reviewerDisplay =
      (req.user as { name?: string; email?: string } | undefined)?.name ??
      (req.user as { email?: string } | undefined)?.email ??
      'Unknown'
    const content = request.content as Record<string, unknown> | null
    const text = buildProcessedRequestNewsText(
      request.type,
      content,
      authorDisplay,
      reviewerDisplay,
      result
    )
    await new Promise((r) => setTimeout(r, 50))
    try {
      await newsRepo.insertOne(authorId, text)
    } catch (newsErr) {
      logDbError(newsErr, 'News insert after accept')
    }
    const reviewerAuthorId = (req.user as { id?: number } | undefined)?.id
    let executeResult: unknown = result
    try {
      executeResult = JSON.parse(JSON.stringify(result)) as unknown
    } catch {
      /* keep raw */
    }
    await enqueuePositionRequestAccepted({
      requestType: request.type,
      submitterEmail: request.email || '',
      comment: request.comment || '',
      content: request.content ?? null,
      reviewerAuthorId:
        reviewerAuthorId != null && Number.isInteger(reviewerAuthorId) ? reviewerAuthorId : undefined,
      executeResult,
    })
    await requestRepo.deleteRequest(sig!)
    res.json({ success: true, message: 'Request accepted and applied' })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/pending/:sig/accept')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function reject(req: Request, res: Response): Promise<void> {
  try {
    const sig = Array.isArray(req.params.sig) ? req.params.sig[0] : req.params.sig
    const reason = typeof (req.body as { reason?: string })?.reason === 'string'
      ? (req.body as { reason: string }).reason.trim()
      : ''
    const request = await requestRepo.getRequestBySig(sig)
    if (!request) {
      res.status(404).json({ error: 'Request not found or already processed' })
      return
    }
    if (reason) {
      console.log('[position-request] Rejected', { sig, reason })
    }
    await enqueuePositionRequestRejected({
      requestType: request.type,
      submitterEmail: request.email || '',
      comment: request.comment || '',
      reason,
      content: request.content ?? null,
    })
    await requestRepo.deleteRequest(sig!)
    res.json({ success: true, message: 'Request rejected and removed' })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/pending/:sig/reject')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

/**
 * Scan all pending OBJECT_UPDATE requests and decline (delete without email) any whose
 * submitted values are identical to the current database state.
 * Returns a list of removed request sigs and a count.
 */
export async function purgeUnchangedObjectUpdates(req: Request, res: Response): Promise<void> {
  try {
    const { ok } = await requestRepo.getPendingRequests()
    const candidates = ok.filter((r) => r.type === requestRepo.REQUEST_TYPES.OBJECT_UPDATE)

    const removed: { id: number; sig: string; objectId: number }[] = []
    const skipped: { id: number; sig: string; objectId: number; reason: string }[] = []

    for (const item of candidates) {
      const c = item.details as Record<string, unknown> | null
      if (!c || typeof c !== 'object') continue
      const objectId = c.objectId != null ? Number(c.objectId) : NaN
      if (!Number.isInteger(objectId) || objectId < 1) continue

      // We need the raw content for full field values — re-fetch by sig
      const full = await requestRepo.getRequestBySig(item.sig)
      if (!full) continue
      const fc = full.content as Record<string, unknown>
      const longitude = Number(fc.longitude)
      const latitude = Number(fc.latitude)
      const orientation = Number(fc.orientation ?? 0)
      const offset = fc.offset != null && fc.offset !== '' ? Number(fc.offset) : null
      const modelId = fc.modelId != null ? Number(fc.modelId) : 0

      const existing = await objectRepo.findById(objectId)
      if (!existing) {
        skipped.push({ id: item.id, sig: item.sig, objectId, reason: 'object not found' })
        continue
      }

      const existingOffset = existing.position.offset != null ? Number(existing.position.offset) : null
      const isUnchanged =
        Math.abs(Number(existing.position.lon) - longitude) < 1e-7 &&
        Math.abs(Number(existing.position.lat) - latitude) < 1e-7 &&
        Math.abs((existing.position.heading ?? 0) - orientation) < 1e-4 &&
        (existingOffset === null
          ? offset === null
          : offset !== null && Math.abs(existingOffset - offset) < 1e-4) &&
        Number(existing.modelId) === modelId

      if (isUnchanged) {
        await requestRepo.deleteRequest(item.sig)
        removed.push({ id: item.id, sig: item.sig, objectId })
        console.log(`[purge] Removed unchanged OBJECT_UPDATE spr_id=${item.id} sig=${item.sig} objectId=${objectId}`)
      } else {
        skipped.push({ id: item.id, sig: item.sig, objectId, reason: 'has changes' })
      }
    }

    res.json({
      removed: removed.length,
      removedItems: removed,
      skipped: skipped.length,
      skippedItems: skipped,
    })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/pending/purge-unchanged')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
