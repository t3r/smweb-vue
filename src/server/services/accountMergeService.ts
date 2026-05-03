import crypto from 'node:crypto'
import type { Request } from 'express'
import { QueryTypes } from 'sequelize'
import Author from '../models/Author.js'
import { sequelize } from '../config/database.js'
import { ROLE_LEVEL, ROLE_USER } from '../config/authConstants.js'
import * as mergeRepo from '../repositories/accountMergeRepository.js'
import type { MergeRequestRow } from '../repositories/accountMergeRepository.js'
import * as authorRepo from '../repositories/authorRepository.js'
import * as authRepo from '../repositories/authRepository.js'
import * as emailQueueRepo from '../repositories/emailQueueRepository.js'
import { EmailEventType } from '../config/emailEventTypes.js'
import { getSessionUserByAuthorId } from './authService.js'

export const MERGE_TOKEN_TTL_MS = 24 * 60 * 60 * 1000
const MAX_INITIATIONS_PER_HOUR = 3

export class AccountMergeError extends Error {
  constructor(
    message: string,
    public readonly statusCode: 400 | 401 | 403 | 404 | 409 | 429 | 500 = 400
  ) {
    super(message)
    this.name = 'AccountMergeError'
  }
}

/** Structured audit log for account merge (no raw tokens or email addresses). */
function logAccountMerge(step: string, payload: Record<string, unknown> = {}): void {
  const line = JSON.stringify({ step, at: new Date().toISOString(), ...payload })
  console.log(`[account-merge] ${line}`)
}

function mergeThrow(
  message: string,
  statusCode: 400 | 401 | 403 | 404 | 409 | 429 | 500 = 400,
  audit: Record<string, unknown> = {}
): never {
  logAccountMerge('error', { message, statusCode, ...audit })
  throw new AccountMergeError(message, statusCode)
}

function normalizeEmail(email: unknown): string {
  return String(email ?? '').trim().toLowerCase()
}

export function hashMergeToken(rawToken: string): Buffer {
  return crypto.createHash('sha256').update(rawToken, 'utf8').digest()
}

function timingSafeBufEqual(a: Buffer, b: Buffer): boolean {
  if (a.length !== b.length) return false
  try {
    return crypto.timingSafeEqual(a, b)
  } catch {
    return false
  }
}

function pickHigherRole(roleA: string, roleB: string): string {
  const ra = ROLE_LEVEL[roleA] ?? -1
  const rb = ROLE_LEVEL[roleB] ?? -1
  const winner = ra >= rb ? roleA : roleB
  return winner && ROLE_LEVEL[winner] != null ? winner : ROLE_USER
}

async function loadAuthorRow(id: number): Promise<{ id: number; name: string | null; email: string | null; notes: string | null } | null> {
  const row = await Author.findByPk(id, { attributes: ['id', 'name', 'email', 'notes'] })
  if (!row) return null
  const get = (row as { get: (k: string) => unknown }).get.bind(row)
  return {
    id: Number(get('id')),
    name: get('name') != null ? String(get('name')) : null,
    email: get('email') != null ? String(get('email')) : null,
    notes: get('notes') != null ? String(get('notes')) : null,
  }
}

async function countModelsForAuthors(a: number, b: number): Promise<number> {
  const rows = (await sequelize.query(
    `SELECT COUNT(*)::int AS n FROM fgs_models
     WHERE mo_deleted IS NULL AND mo_author IN (:a, :b)`,
    { replacements: { a, b }, type: QueryTypes.SELECT }
  )) as { n: number }[]
  return rows?.[0]?.n ?? 0
}

async function countNewsForAuthors(a: number, b: number): Promise<number> {
  const rows = (await sequelize.query(
    `SELECT COUNT(*)::int AS n FROM fgs_news WHERE ne_author IN (:a, :b)`,
    { replacements: { a, b }, type: QueryTypes.SELECT }
  )) as { n: number }[]
  return rows?.[0]?.n ?? 0
}

async function countOAuthRowsForAuthors(a: number, b: number): Promise<number> {
  const rows = (await sequelize.query(
    `SELECT COUNT(*)::int AS n FROM fgs_extuserids WHERE eu_author_id IN (:a, :b)`,
    { replacements: { a, b }, type: QueryTypes.SELECT }
  )) as { n: number }[]
  return rows?.[0]?.n ?? 0
}

export async function initiateMerge(
  sourceAuthorId: number,
  body: { targetEmail?: unknown; targetAuthorId?: unknown }
): Promise<{ mergeRequestId: string; expiresAt: string }> {
  const srcId = Number(sourceAuthorId)
  if (!Number.isInteger(srcId) || srcId < 1) mergeThrow('Invalid session author', 403, { op: 'initiate' })

  let targetId: number | null = null
  let targetResolvedBy: 'authorId' | 'email' | null = null
  const tid = body.targetAuthorId != null ? Number(body.targetAuthorId) : null
  const emailRaw = body.targetEmail != null ? String(body.targetEmail).trim() : ''

  if (tid != null && Number.isInteger(tid) && tid >= 1) {
    targetId = tid
    targetResolvedBy = 'authorId'
  } else if (emailRaw) {
    const byEmail = await authorRepo.findAuthorByEmail(emailRaw)
    targetId = byEmail?.id ?? null
    targetResolvedBy = 'email'
  }

  logAccountMerge('initiate.start', {
    sourceAuthorId: srcId,
    targetAuthorId: targetId,
    targetResolvedBy,
    hadEmailLookup: Boolean(emailRaw),
  })

  if (targetId == null) mergeThrow('Target author not found', 404, { op: 'initiate', sourceAuthorId: srcId })
  if (targetId === srcId) mergeThrow('Cannot merge an author with itself', 400, { op: 'initiate', sourceAuthorId: srcId })

  const target = await loadAuthorRow(targetId)
  if (!target) mergeThrow('Target author not found', 404, { op: 'initiate', sourceAuthorId: srcId, targetAuthorId: targetId })

  const targetEmailNorm = normalizeEmail(target.email)
  if (!targetEmailNorm) {
    mergeThrow('Target author has no email; merge cannot be verified', 400, {
      op: 'initiate',
      sourceAuthorId: srcId,
      targetAuthorId: targetId,
    })
  }

  const nHour = await mergeRepo.countInitiationsInLastHour(srcId)
  if (nHour >= MAX_INITIATIONS_PER_HOUR) {
    mergeThrow('Too many merge requests; try again later', 429, {
      op: 'initiate',
      sourceAuthorId: srcId,
      targetAuthorId: targetId,
      initiationsLastHour: nHour,
    })
  }

  await mergeRepo.cancelOpenRequestsForPair(srcId, targetId)
  logAccountMerge('initiate.cancelled_prior_open', { sourceAuthorId: srcId, targetAuthorId: targetId })

  const rawToken = crypto.randomBytes(32).toString('base64url')
  const tokenHash = hashMergeToken(rawToken)
  const expiresAt = new Date(Date.now() + MERGE_TOKEN_TTL_MS)

  const mergeRequestId = await mergeRepo.insertMergeRequest({
    sourceAuthorId: srcId,
    targetAuthorId: targetId,
    targetEmailSnapshot: targetEmailNorm,
    tokenHash,
    expiresAt,
  })

  const base = process.env.FRONTEND_URL || process.env.CLIENT_URL || 'http://localhost:5173'
  const link = `${base.replace(/\/$/, '')}/merge/confirm?${new URLSearchParams({
    token: rawToken,
    id: mergeRequestId,
  }).toString()}`

  const source = await loadAuthorRow(srcId)
  await emailQueueRepo.enqueue(EmailEventType.ACCOUNT_MERGE_CONFIRM, {
    recipientEmail: target.email?.trim() || targetEmailNorm,
    link,
    sourceName: source?.name || `Author #${srcId}`,
    targetName: target.name || `Author #${targetId}`,
    sourceAuthorId: srcId,
    targetAuthorId: targetId,
    expiresAt: expiresAt.toISOString(),
  })

  logAccountMerge('initiate.email_enqueued', {
    mergeRequestId,
    sourceAuthorId: srcId,
    targetAuthorId: targetId,
    eventType: EmailEventType.ACCOUNT_MERGE_CONFIRM,
  })
  logAccountMerge('initiate.complete', {
    mergeRequestId,
    sourceAuthorId: srcId,
    targetAuthorId: targetId,
    expiresAt: expiresAt.toISOString(),
  })

  return { mergeRequestId, expiresAt: expiresAt.toISOString() }
}

async function loadMergeRequestVerified(
  rawToken: string,
  amrId: string,
  op: string
): Promise<{ row: MergeRequestRow }> {
  const row = await mergeRepo.findById(amrId)
  if (!row || row.amr_confirmed_at != null || row.amr_cancelled_at != null) {
    mergeThrow('Merge request not found or no longer valid', 404, {
      op: 'load_merge_request',
      phase: op,
      mergeRequestId: amrId,
      reason: 'missing_or_terminal',
    })
  }
  const exp =
    row.amr_expires_at instanceof Date
      ? row.amr_expires_at.getTime()
      : new Date(row.amr_expires_at).getTime()
  if (exp < Date.now()) {
    mergeThrow('Merge request expired', 404, {
      op: 'load_merge_request',
      phase: op,
      mergeRequestId: amrId,
      reason: 'expired',
    })
  }

  const tokenHash = hashMergeToken(rawToken)
  const stored = row.amr_token_hash
  const stBuf = Buffer.isBuffer(stored) ? stored : Buffer.from(stored as Uint8Array)
  if (!timingSafeBufEqual(tokenHash, stBuf)) {
    mergeThrow('Merge request not found', 404, {
      op: 'load_merge_request',
      phase: op,
      mergeRequestId: amrId,
      reason: 'token_mismatch',
    })
  }

  logAccountMerge('load_merge_request.ok', {
    phase: op,
    mergeRequestId: amrId,
    sourceAuthorId: row.amr_source_author_id,
    targetAuthorId: row.amr_target_author_id,
  })
  return { row }
}

export async function previewMerge(
  sessionAuthorId: number,
  rawToken: string,
  amrId: string
): Promise<Record<string, unknown>> {
  logAccountMerge('preview.start', { sessionAuthorId, mergeRequestId: amrId })
  const { row } = await loadMergeRequestVerified(rawToken, amrId, 'preview')
  if (row.amr_source_author_id !== sessionAuthorId) {
    mergeThrow('You must be signed in as the account that started this merge', 403, {
      op: 'preview',
      mergeRequestId: amrId,
      sessionAuthorId,
      sourceAuthorId: row.amr_source_author_id,
    })
  }

  const sourceId = row.amr_source_author_id
  const targetId = row.amr_target_author_id
  const keeperId = Math.min(sourceId, targetId)
  const loserId = Math.max(sourceId, targetId)

  const [source, target, roleSource, roleTarget] = await Promise.all([
    loadAuthorRow(sourceId),
    loadAuthorRow(targetId),
    authRepo.getRoleForAuthor(sourceId),
    authRepo.getRoleForAuthor(targetId),
  ])

  const [modelsCount, newsCount, oauthCount] = await Promise.all([
    countModelsForAuthors(sourceId, targetId),
    countNewsForAuthors(sourceId, targetId),
    countOAuthRowsForAuthors(sourceId, targetId),
  ])

  const mergedRole = pickHigherRole(roleSource, roleTarget)

  logAccountMerge('preview.complete', {
    mergeRequestId: row.amr_id,
    sessionAuthorId,
    keeperId,
    loserId,
    counts: { models: modelsCount, news: newsCount, oauthIdentities: oauthCount },
    mergedRole,
  })

  return {
    mergeRequestId: row.amr_id,
    expiresAt:
      row.amr_expires_at instanceof Date
        ? row.amr_expires_at.toISOString()
        : new Date(row.amr_expires_at).toISOString(),
    keeperId,
    loserId,
    source: source ? { id: source.id, name: source.name, email: source.email } : { id: sourceId },
    target: target ? { id: target.id, name: target.name, email: target.email } : { id: targetId },
    counts: { models: modelsCount, news: newsCount, oauthIdentities: oauthCount },
    roles: { source: roleSource, target: roleTarget, merged: mergedRole },
  }
}

async function runMergeTransaction(
  sourceId: number,
  targetId: number,
  snapshotEmail: string,
  amrId: string
): Promise<number> {
  const keeperId = Math.min(sourceId, targetId)
  const loserId = Math.max(sourceId, targetId)

  logAccountMerge('transaction.start', {
    mergeRequestId: amrId,
    sourceId,
    targetId,
    keeperId,
    loserId,
  })

  return sequelize.transaction(async (transaction) => {
    const targetRow = await Author.findByPk(targetId, {
      attributes: ['id', 'email'],
      transaction,
      lock: true,
    })
    if (!targetRow) mergeThrow('Target author disappeared', 409, { op: 'transaction', mergeRequestId: amrId, targetId })
    const currentEmail = normalizeEmail((targetRow as { get: (k: string) => unknown }).get('email'))
    if (currentEmail !== normalizeEmail(snapshotEmail)) {
      mergeThrow('Target email changed since merge was requested; cancel and start again', 409, {
        op: 'transaction',
        mergeRequestId: amrId,
        targetId,
        reason: 'email_snapshot_mismatch',
      })
    }

    await sequelize.query(
      `UPDATE fgs_models SET mo_author = :keeper WHERE mo_author = :loser`,
      { replacements: { keeper: keeperId, loser: loserId }, transaction }
    )
    await sequelize.query(
      `UPDATE fgs_models SET mo_modified_by = :keeper WHERE mo_modified_by = :loser`,
      { replacements: { keeper: keeperId, loser: loserId }, transaction }
    )
    await sequelize.query(
      `UPDATE fgs_news SET ne_author = :keeper WHERE ne_author = :loser`,
      { replacements: { keeper: keeperId, loser: loserId }, transaction }
    )
    await sequelize.query(
      `UPDATE fgs_objects SET ob_modified_by = :keeper WHERE ob_modified_by = :loser`,
      { replacements: { keeper: keeperId, loser: loserId }, transaction }
    )
    await sequelize.query(
      `UPDATE fgs_extuserids SET eu_author_id = :keeper WHERE eu_author_id = :loser`,
      { replacements: { keeper: keeperId, loser: loserId }, transaction }
    )

    const roleK = await authRepo.getRoleForAuthor(keeperId)
    const roleL = await authRepo.getRoleForAuthor(loserId)
    const mergedRole = pickHigherRole(roleK, roleL)
    await authRepo.setRoleForAuthor(keeperId, mergedRole)
    await sequelize.query(`DELETE FROM fgs_user_roles WHERE au_id = :loser`, {
      replacements: { loser: loserId },
      transaction,
    })

    await sequelize.query(
      `UPDATE fgs_authors k
       SET au_email = COALESCE(NULLIF(TRIM(k.au_email), ''), l.au_email),
           au_name = COALESCE(NULLIF(TRIM(k.au_name), ''), l.au_name),
           au_notes = COALESCE(NULLIF(TRIM(k.au_notes), ''), l.au_notes)
       FROM fgs_authors l
       WHERE k.au_id = :keeper AND l.au_id = :loser`,
      { replacements: { keeper: keeperId, loser: loserId }, transaction }
    )

    await sequelize.query(`DELETE FROM fgs_authors WHERE au_id = :loser`, {
      replacements: { loser: loserId },
      transaction,
    })

    await sequelize.query(
      `UPDATE fgs_account_merge_requests
       SET amr_confirmed_at = NOW(),
           amr_keeper_author_id = :keeperId
       WHERE amr_id = CAST(:amrId AS uuid)`,
      { replacements: { keeperId, amrId }, transaction }
    )

    logAccountMerge('transaction.complete', {
      mergeRequestId: amrId,
      keeperId,
      loserId,
    })
    return keeperId
  })
}

export async function confirmMerge(
  sessionAuthorId: number,
  rawToken: string,
  amrId: string,
  req: Request
): Promise<{ keeperAuthorId: number }> {
  logAccountMerge('confirm.start', { sessionAuthorId, mergeRequestId: amrId })
  const { row } = await loadMergeRequestVerified(rawToken, amrId, 'confirm')
  if (row.amr_source_author_id !== sessionAuthorId) {
    mergeThrow('You must be signed in as the account that started this merge', 403, {
      op: 'confirm',
      mergeRequestId: amrId,
      sessionAuthorId,
      sourceAuthorId: row.amr_source_author_id,
    })
  }

  const sourceId = row.amr_source_author_id
  const targetId = row.amr_target_author_id

  const keeperId = await runMergeTransaction(sourceId, targetId, row.amr_target_email_at_create, amrId)

  const sessionUser = await getSessionUserByAuthorId(keeperId)
  if (!sessionUser) {
    mergeThrow('Could not reload session user after merge', 500, {
      op: 'confirm',
      mergeRequestId: amrId,
      keeperAuthorId: keeperId,
    })
  }

  try {
    await new Promise<void>((resolve, reject) => {
      req.login(sessionUser as unknown as Express.User, (err: Error | undefined) => {
        if (err) reject(err)
        else resolve()
      })
    })
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err)
    logAccountMerge('confirm.session_login_failed', {
      mergeRequestId: amrId,
      keeperAuthorId: keeperId,
      message: msg,
    })
    throw err
  }

  logAccountMerge('confirm.complete', {
    mergeRequestId: amrId,
    keeperAuthorId: keeperId,
    sourceAuthorId: sourceId,
    targetAuthorId: targetId,
  })

  return { keeperAuthorId: keeperId }
}

export async function cancelMerge(sessionAuthorId: number, amrId: string): Promise<void> {
  logAccountMerge('cancel.start', { sessionAuthorId, mergeRequestId: amrId })
  const row = await mergeRepo.findById(amrId)
  if (!row) mergeThrow('Merge request not found', 404, { op: 'cancel', mergeRequestId: amrId, sessionAuthorId })
  if (row.amr_confirmed_at != null || row.amr_cancelled_at != null) {
    mergeThrow('Merge request is no longer pending', 409, {
      op: 'cancel',
      mergeRequestId: amrId,
      sessionAuthorId,
      reason: 'not_pending',
    })
  }
  if (row.amr_source_author_id !== sessionAuthorId) {
    mergeThrow('Forbidden', 403, {
      op: 'cancel',
      mergeRequestId: amrId,
      sessionAuthorId,
      sourceAuthorId: row.amr_source_author_id,
    })
  }
  await mergeRepo.markCancelled(amrId)
  logAccountMerge('cancel.complete', {
    mergeRequestId: amrId,
    sessionAuthorId,
    sourceAuthorId: row.amr_source_author_id,
    targetAuthorId: row.amr_target_author_id,
  })
}
