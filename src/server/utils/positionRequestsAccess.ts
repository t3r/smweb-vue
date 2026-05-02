import { hasMinimumRole } from '../config/authConstants.js'
import * as authorRepo from '../repositories/authorRepository.js'
import * as objectRepo from '../repositories/objectRepository.js'

export type SessionUser = { id?: number; email?: string; role?: string }

export function isReviewerOrAbove(role?: string): boolean {
  return hasMinimumRole(role, 'reviewer')
}

/**
 * Pending MODEL_ADD / MODEL_UPDATE tarball and thumbnail are readable by any signed-in user
 * (same visibility as GET /position-requests). Other request types use sessionMayAccessDecodedPendingRequest.
 */
export function sessionMayAccessPendingModelTarball(user: SessionUser | undefined, requestType: string): boolean {
  if (!user) return false
  if (isReviewerOrAbove(user.role)) return true
  return requestType === 'MODEL_ADD' || requestType === 'MODEL_UPDATE'
}

/** Accept author id as number, numeric string, or `{ id: number }` (overview / legacy payloads). */
function coerceAuthorIdField(v: unknown): number | null {
  if (v == null) return null
  if (typeof v === 'number' && Number.isFinite(v)) return v
  if (typeof v === 'string') {
    const n = Number(v.trim())
    return Number.isFinite(n) ? n : null
  }
  if (typeof v === 'object' && v !== null && 'id' in v) {
    const n = Number((v as { id?: unknown }).id)
    return Number.isFinite(n) ? n : null
  }
  return null
}

/**
 * Directory / session author id from queued payload (API `details` overview or raw `content`).
 * Uses `model.author`, root `author`, `modifiedByAuthorId` (MODEL_DELETE), `submitterAuthorId` (OBJECT_UPDATE),
 * and `derivedModelAuthorId` (OBJECT_UPDATE / OBJECT_DELETE from DB: model owner for the object).
 */
export function contentAuthorIdFromQueuedPayload(payload: unknown): number | null {
  if (payload == null || typeof payload !== 'object') return null
  const c = payload as Record<string, unknown>
  const modBy = c.modifiedByAuthorId
  if (modBy != null && Number.isFinite(Number(modBy))) return Number(modBy)
  const sub = c.submitterAuthorId
  if (sub != null && Number.isFinite(Number(sub))) return Number(sub)
  const model = c.model as Record<string, unknown> | undefined
  const fromModel = coerceAuthorIdField(model?.author)
  if (fromModel != null) return fromModel
  const fromRoot = coerceAuthorIdField(c.author)
  if (fromRoot != null) return fromRoot
  const derived = c.derivedModelAuthorId
  if (derived != null && Number.isFinite(Number(derived))) return Number(derived)
  return null
}

/** Reviewers/testers/admins see the full queue; other signed-in users only matching rows. */
export function filterPendingQueueItemsForSession<
  T extends { email?: string | null; authorId?: number | null; type?: string; details?: unknown },
>(items: T[], user: SessionUser | undefined): T[] {
  if (!user) return []
  if (isReviewerOrAbove(user.role)) return items
  const ue = (user.email ?? '').trim().toLowerCase()
  return items.filter((item) => {
    const ie = (item.email ?? '').trim().toLowerCase()
    if (ue && ie && ue === ie) return true
    if (user.id != null && item.authorId != null && Number(item.authorId) === Number(user.id)) return true
    const fromPayload = contentAuthorIdFromQueuedPayload(item.details)
    if (user.id != null && fromPayload != null && Number(fromPayload) === Number(user.id)) return true
    return false
  })
}

/**
 * Whether the signed-in user may read this pending request (list row, full payload, or package URLs).
 * Reviewers: always. Others: submitter email, linked author from that email, or content `author` / `model.author`.
 */
async function modelAuthorIdFromObjectScopedContent(
  type: string | undefined,
  content: unknown,
): Promise<number | null> {
  if (type !== 'OBJECT_UPDATE' && type !== 'OBJECT_DELETE') return null
  if (content == null || typeof content !== 'object') return null
  const c = content as Record<string, unknown>
  const oid =
    type === 'OBJECT_UPDATE' ? Number(c.objectId) : Number(c.objId)
  if (!Number.isInteger(oid) || oid < 1) return null
  const map = await objectRepo.findModelAuthorIdsByObjectIds([oid])
  return map.get(oid) ?? null
}

export async function sessionMayAccessDecodedPendingRequest(
  user: SessionUser | undefined,
  decoded: { email?: string; content?: unknown; type?: string },
): Promise<boolean> {
  if (!user) return false
  if (isReviewerOrAbove(user.role)) return true
  const ue = (user.email ?? '').trim().toLowerCase()
  const se = (decoded.email ?? '').trim().toLowerCase()
  if (ue && se && ue === se) return true
  if (decoded.email != null && String(decoded.email).trim()) {
    const map = await authorRepo.findAuthorsByEmails([String(decoded.email)])
    const author = map.get(se)
    if (author?.id != null && user.id != null && Number(author.id) === Number(user.id)) return true
  }
  const pid = contentAuthorIdFromQueuedPayload(decoded.content)
  if (pid != null && user.id != null && Number(pid) === Number(user.id)) return true
  const derived = await modelAuthorIdFromObjectScopedContent(decoded.type, decoded.content)
  if (derived != null && user.id != null && Number(derived) === Number(user.id)) return true
  return false
}
