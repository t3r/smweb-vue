import { EmailEventType } from '../config/emailEventTypes.js'
import * as emailQueueRepo from '../repositories/emailQueueRepository.js'

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
}): Promise<void> {
  await safeEnqueue(EmailEventType.POSITION_REQUEST_CREATED, {
    requestId: params.requestId,
    sig: params.sig,
    requestType: params.requestType,
  })
}

export async function enqueuePositionRequestAccepted(params: {
  sig: string
  requestType: string
  submitterEmail: string
  comment: string
  reviewerAuthorId?: number
  executeResult?: unknown
}): Promise<void> {
  await safeEnqueue(EmailEventType.POSITION_REQUEST_ACCEPTED, {
    sig: params.sig,
    requestType: params.requestType,
    submitterEmail: params.submitterEmail,
    comment: params.comment,
    ...(params.reviewerAuthorId != null ? { reviewerAuthorId: params.reviewerAuthorId } : {}),
    ...(params.executeResult !== undefined ? { executeResult: params.executeResult } : {}),
  })
}

export async function enqueuePositionRequestRejected(params: {
  sig: string
  requestType: string
  submitterEmail: string
  comment: string
  reason: string
}): Promise<void> {
  await safeEnqueue(EmailEventType.POSITION_REQUEST_REJECTED, {
    sig: params.sig,
    requestType: params.requestType,
    submitterEmail: params.submitterEmail,
    comment: params.comment,
    reason: params.reason,
  })
}
