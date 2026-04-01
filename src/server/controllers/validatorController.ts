import type { Request, Response } from 'express'
import * as requestRepo from '../repositories/requestRepository.js'
import * as requestExecutor from '../services/requestExecutor.js'
import * as authorRepo from '../repositories/authorRepository.js'
import * as newsRepo from '../repositories/newsRepository.js'
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
      sig: request.sig,
      requestType: request.type,
      submitterEmail: request.email || '',
      comment: request.comment || '',
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
      sig: request.sig,
      requestType: request.type,
      submitterEmail: request.email || '',
      comment: request.comment || '',
      reason,
    })
    await requestRepo.deleteRequest(sig!)
    res.json({ success: true, message: 'Request rejected and removed' })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/pending/:sig/reject')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
