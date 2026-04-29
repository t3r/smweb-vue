import { QueryTypes } from 'sequelize'
import { sequelize } from '../config/database.js'

export interface MergeRequestRow {
  amr_id: string
  amr_source_author_id: number
  amr_target_author_id: number
  amr_target_email_at_create: string
  amr_token_hash: Buffer
  amr_created_at: Date
  amr_expires_at: Date
  amr_confirmed_at: Date | null
  amr_cancelled_at: Date | null
  amr_keeper_author_id: number | null
}

/** Cancel open requests for the same (source, target) so a replacement can be inserted (unique index). */
export async function cancelOpenRequestsForPair(sourceAuthorId: number, targetAuthorId: number): Promise<void> {
  await sequelize.query(
    `UPDATE fgs_account_merge_requests
     SET amr_cancelled_at = NOW()
     WHERE amr_source_author_id = :sourceId
       AND amr_target_author_id = :targetId
       AND amr_confirmed_at IS NULL
       AND amr_cancelled_at IS NULL`,
    { replacements: { sourceId: sourceAuthorId, targetId: targetAuthorId } }
  )
}

export async function countInitiationsInLastHour(sourceAuthorId: number): Promise<number> {
  const rows = (await sequelize.query(
    `SELECT COUNT(*)::int AS n
     FROM fgs_account_merge_requests
     WHERE amr_source_author_id = :sourceId
       AND amr_created_at >= NOW() - INTERVAL '1 hour'`,
    {
      replacements: { sourceId: sourceAuthorId },
      type: QueryTypes.SELECT,
    }
  )) as { n: number }[]
  return rows?.[0]?.n ?? 0
}

export async function insertMergeRequest(params: {
  sourceAuthorId: number
  targetAuthorId: number
  targetEmailSnapshot: string
  tokenHash: Buffer
  expiresAt: Date
}): Promise<string> {
  const rows = (await sequelize.query(
    `INSERT INTO fgs_account_merge_requests (
       amr_source_author_id, amr_target_author_id, amr_target_email_at_create,
       amr_token_hash, amr_expires_at
     )
     VALUES (:sourceId, :targetId, :emailSnap, :tokenHash, :expiresAt)
     RETURNING amr_id::text AS id`,
    {
      replacements: {
        sourceId: params.sourceAuthorId,
        targetId: params.targetAuthorId,
        emailSnap: params.targetEmailSnapshot.slice(0, 64),
        tokenHash: params.tokenHash,
        expiresAt: params.expiresAt,
      },
      type: QueryTypes.SELECT,
    }
  )) as { id: string }[]
  const id = rows?.[0]?.id
  if (!id) throw new Error('insertMergeRequest: no id returned')
  return id
}

export async function findById(amrId: string): Promise<MergeRequestRow | null> {
  const rows = (await sequelize.query(
    `SELECT
       amr_id::text AS "amr_id",
       amr_source_author_id AS "amr_source_author_id",
       amr_target_author_id AS "amr_target_author_id",
       amr_target_email_at_create AS "amr_target_email_at_create",
       amr_token_hash AS "amr_token_hash",
       amr_created_at AS "amr_created_at",
       amr_expires_at AS "amr_expires_at",
       amr_confirmed_at AS "amr_confirmed_at",
       amr_cancelled_at AS "amr_cancelled_at",
       amr_keeper_author_id AS "amr_keeper_author_id"
     FROM fgs_account_merge_requests
     WHERE amr_id = CAST(:id AS uuid)`,
    { replacements: { id: amrId }, type: QueryTypes.SELECT }
  )) as MergeRequestRow[]
  const row = rows?.[0]
  if (!row) return null
  return row
}

export async function markCancelled(amrId: string): Promise<void> {
  await sequelize.query(
    `UPDATE fgs_account_merge_requests
     SET amr_cancelled_at = NOW()
     WHERE amr_id = CAST(:id AS uuid)
       AND amr_confirmed_at IS NULL`,
    { replacements: { id: amrId } }
  )
}
