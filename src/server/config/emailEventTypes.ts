/**
 * Stable event names for `fgs_email_queue.eq_event_type`.
 * Payloads are intentionally small; the mailer expands them when sending.
 *
 * Queue lifecycle (SQS-style; external mailer uses Bearer token `EMAIL_QUEUE_BEARER_TOKEN`):
 * - POST /api/email-queue/receive — claim messages (visibility timeout + receipt handle)
 * - POST /api/email-queue/delete — remove after successful send (receipt handle required).
 *   If send fails, do not delete; after visibility expires the message is offered again.
 */

export const EmailEventType = {
  /** New row in fgs_position_requests; load full request with `sig` or `requestId`. */
  POSITION_REQUEST_CREATED: 'position_request.created',
  /** Request was applied; row is deleted after enqueue — payload is a snapshot. */
  POSITION_REQUEST_ACCEPTED: 'position_request.accepted',
  /** Request was rejected; row is deleted after enqueue — payload is a snapshot. */
  POSITION_REQUEST_REJECTED: 'position_request.rejected',
} as const

export type EmailEventTypeName = (typeof EmailEventType)[keyof typeof EmailEventType]

/** Payload for {@link EmailEventType.POSITION_REQUEST_CREATED} */
export interface PositionRequestCreatedPayload {
  requestId: number
  sig: string
  requestType: string
}

/** Payload for {@link EmailEventType.POSITION_REQUEST_ACCEPTED} */
export interface PositionRequestAcceptedPayload {
  sig: string
  requestType: string
  submitterEmail: string
  comment: string
  reviewerAuthorId?: number
  /** Outcome of executeRequest (modelId, objectId, objectIds, …); mailer builds catalogue links for MODEL_ADD / OBJECTS_ADD */
  executeResult?: unknown
}

/** Payload for {@link EmailEventType.POSITION_REQUEST_REJECTED} */
export interface PositionRequestRejectedPayload {
  sig: string
  requestType: string
  submitterEmail: string
  comment: string
  reason: string
}
