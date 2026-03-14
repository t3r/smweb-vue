import { sequelize } from '../config/database.js'
import { QueryTypes } from 'sequelize'

const MAX_ATTEMPTS = 5

export interface EmailQueueRow {
  eq_id: number
  eq_event_type: string
  eq_payload: Record<string, unknown>
  eq_attempts: number
}

export interface ReceivedEmailMessage {
  eqId: number
  receiptHandle: string
  eventType: string
  payload: Record<string, unknown>
  attempts: number
  createdAt: string
}

function normalizePayload(raw: unknown): Record<string, unknown> {
  if (raw != null && typeof raw === 'object' && !Array.isArray(raw)) {
    return raw as Record<string, unknown>
  }
  return {}
}

export async function enqueue(eventType: string, payload: Record<string, unknown>): Promise<number> {
  const json = JSON.stringify(payload ?? {})
  const rows = await sequelize.query(
    `INSERT INTO fgs_email_queue (eq_event_type, eq_payload)
     VALUES (:eventType, CAST(:payload AS jsonb))
     RETURNING eq_id`,
    {
      replacements: { eventType, payload: json },
      type: QueryTypes.SELECT,
    }
  ) as { eq_id: number }[]
  const id = rows[0]?.eq_id
  if (id == null) throw new Error('enqueue: no eq_id returned')
  return id
}

/**
 * Claim up to `batchSize` visible messages (not in flight, attempts below cap).
 * Sets visibility deadline and a new receipt handle per row.
 */
export async function receiveBatch(batchSize: number, visibilitySeconds: number): Promise<ReceivedEmailMessage[]> {
  const limit = Math.min(Math.max(1, Math.floor(batchSize)), 50)
  const vis = Math.min(Math.max(1, Math.floor(visibilitySeconds)), 86400)

  const rows = await sequelize.transaction(async (transaction) => {
    const out = await sequelize.query(
      `WITH candidates AS (
        SELECT eq_id
        FROM fgs_email_queue
        WHERE (eq_in_flight_until IS NULL OR eq_in_flight_until <= NOW())
          AND eq_attempts < :maxAttempts
        ORDER BY eq_created_at ASC
        LIMIT :limit
        FOR UPDATE SKIP LOCKED
      )
      UPDATE fgs_email_queue q
      SET eq_in_flight_until = NOW() + (:visSeconds * INTERVAL '1 second'),
          eq_receipt_handle = gen_random_uuid()
      FROM candidates c
      WHERE q.eq_id = c.eq_id
      RETURNING q.eq_id, q.eq_event_type, q.eq_payload, q.eq_attempts, q.eq_created_at, q.eq_receipt_handle`,
      {
        replacements: { limit, maxAttempts: MAX_ATTEMPTS, visSeconds: vis },
        transaction,
        type: QueryTypes.SELECT,
      }
    )
    return out as {
      eq_id: number
      eq_event_type: string
      eq_payload: unknown
      eq_attempts: number
      eq_created_at: Date | string
      eq_receipt_handle: string
    }[]
  })

  return rows.map((r) => ({
    eqId: r.eq_id,
    receiptHandle: String(r.eq_receipt_handle),
    eventType: r.eq_event_type,
    payload: normalizePayload(r.eq_payload),
    attempts: Number(r.eq_attempts) || 0,
    createdAt:
      r.eq_created_at instanceof Date ? r.eq_created_at.toISOString() : String(r.eq_created_at),
  }))
}

/** Permanently remove a message (SQS DeleteMessage). Receipt handle must match current in-flight receipt. */
export async function deleteMessage(eqId: number, receiptHandle: string): Promise<boolean> {
  const rows = await sequelize.query(
    `DELETE FROM fgs_email_queue
     WHERE eq_id = :id AND eq_receipt_handle = CAST(:handle AS uuid)
     RETURNING eq_id`,
    {
      replacements: { id: eqId, handle: receiptHandle },
      type: QueryTypes.SELECT,
    }
  ) as { eq_id: number }[]

  return rows.length > 0
}

export { MAX_ATTEMPTS as EMAIL_QUEUE_MAX_ATTEMPTS }
