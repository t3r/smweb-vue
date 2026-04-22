import { EmailEventType } from '../config/emailEventTypes.js'
import * as emailQueueRepo from '../repositories/emailQueueRepository.js'
import * as requestRepo from '../repositories/requestRepository.js'

function logEnqueueError(eventType: string, err: unknown): void {
  const msg = err instanceof Error ? err.message : String(err)
  console.error(`[email-queue] enqueue failed (${eventType}):`, msg)
}

/** Insert a row; never throws — logs on failure so HTTP handlers are not broken. */
export async function safeEnqueue(eventType: string, payload: Record<string, unknown>): Promise<void> {
  try {
    await emailQueueRepo.enqueue(eventType, payload)
  } catch (err) {
    logEnqueueError(eventType, err)
  }
}

export async function enqueuePositionRequestCreated(params: {
  requestId: number
  sig: string
  requestType: string
  /** Raw request content (used to build a safe overview for reviewer emails). */
  content?: unknown
  comment?: string
}): Promise<void> {
  const overview =
    params.content !== undefined ? requestRepo.getRequestContentOverview(params.requestType, params.content) : undefined
  const commentTrimmed = params.comment != null ? String(params.comment).trim() : ''
  await safeEnqueue(EmailEventType.POSITION_REQUEST_CREATED, {
    requestId: params.requestId,
    sig: params.sig,
    requestType: params.requestType,
    ...(overview != null ? { contentOverview: overview } : {}),
    ...(commentTrimmed !== '' ? { comment: commentTrimmed } : {}),
  })
}

export async function enqueuePositionRequestAccepted(params: {
  requestType: string
  submitterEmail: string
  comment: string
  /** Raw request content (safe overview for submitter email). */
  content?: unknown
  reviewerAuthorId?: number
  executeResult?: unknown
}): Promise<void> {
  const overview =
    params.content !== undefined
      ? requestRepo.getRequestContentOverview(params.requestType, params.content)
      : undefined
  await safeEnqueue(EmailEventType.POSITION_REQUEST_ACCEPTED, {
    requestType: params.requestType,
    submitterEmail: params.submitterEmail,
    comment: params.comment,
    ...(overview != null ? { contentOverview: overview } : {}),
    ...(params.reviewerAuthorId != null ? { reviewerAuthorId: params.reviewerAuthorId } : {}),
    ...(params.executeResult !== undefined ? { executeResult: params.executeResult } : {}),
  })
}

export async function enqueuePositionRequestRejected(params: {
  requestType: string
  submitterEmail: string
  comment: string
  reason: string
  content?: unknown
}): Promise<void> {
  const overview =
    params.content !== undefined
      ? requestRepo.getRequestContentOverview(params.requestType, params.content)
      : undefined
  await safeEnqueue(EmailEventType.POSITION_REQUEST_REJECTED, {
    requestType: params.requestType,
    submitterEmail: params.submitterEmail,
    comment: params.comment,
    reason: params.reason,
    ...(overview != null ? { contentOverview: overview } : {}),
  })
}
