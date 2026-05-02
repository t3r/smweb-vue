import crypto from 'crypto'
import zlib from 'zlib'
import { sequelize } from '../config/database.js'
import { QueryTypes } from 'sequelize'
import * as authorRepo from './authorRepository.js'
import * as objectRepo from './objectRepository.js'

export const REQUEST_TYPES = {
  OBJECT_UPDATE: 'OBJECT_UPDATE',
  OBJECT_DELETE: 'OBJECT_DELETE',
  OBJECTS_ADD: 'OBJECTS_ADD',
  MODEL_ADD: 'MODEL_ADD',
  MODEL_UPDATE: 'MODEL_UPDATE',
  MODEL_DELETE: 'MODEL_DELETE',
} as const

const MODEL_FILE_KEYS = ['thumbnail', 'modelfiles', 'modelfile']

/** Safe overview for emails / API (no large base64 blobs). */
export function getRequestContentOverview(type: string, content: unknown): unknown {
  return contentOverview(type, content)
}

function contentOverview(type: string, content: unknown): unknown {
  if (content == null || typeof content !== 'object') return null
  switch (type) {
    case 'OBJECT_UPDATE': {
      const c = content as Record<string, unknown>
      const out: Record<string, unknown> = {
        objectId: c.objectId,
        modelId: c.modelId,
        description: c.description,
        country: c.country,
        longitude: c.longitude,
        latitude: c.latitude,
        offset: c.offset,
        orientation: c.orientation,
      }
      const sid = c.submitterAuthorId
      if (sid != null && Number.isFinite(Number(sid))) out.submitterAuthorId = Number(sid)
      return out
    }
    case 'OBJECT_DELETE': {
      const c = content as Record<string, unknown>
      const out: Record<string, unknown> = { objId: c.objId }
      const sid = c.submitterAuthorId
      if (sid != null && Number.isFinite(Number(sid))) out.submitterAuthorId = Number(sid)
      return out
    }
    case 'OBJECTS_ADD':
      return Array.isArray(content)
        ? (content as Record<string, unknown>[]).map((obj) => ({
            description: obj.description,
            country: obj.country,
            modelId: obj.modelId,
            longitude: obj.longitude,
            latitude: obj.latitude,
            offset: obj.offset,
            orientation: obj.orientation,
          }))
        : null
    case 'MODEL_ADD': {
      const c = content as Record<string, unknown>
      const out: Record<string, unknown> = {}
      if (c.model && typeof c.model === 'object') {
        out.model = { ...(c.model as object) }
        MODEL_FILE_KEYS.forEach((k) => delete (out.model as Record<string, unknown>)[k])
      }
      if (c.object && typeof c.object === 'object') out.object = { ...(c.object as object) }
      if (c.author && typeof c.author === 'object') out.author = { ...(c.author as object) }
      return Object.keys(out).length ? out : null
    }
    case 'MODEL_UPDATE': {
      const out = { ...(content as Record<string, unknown>) }
      MODEL_FILE_KEYS.forEach((k) => delete out[k])
      return Object.keys(out).length ? out : null
    }
    case 'MODEL_DELETE': {
      const c = content as Record<string, unknown>
      const out: Record<string, unknown> = { modelId: c.modelId ?? c.modelid }
      const mid = c.modifiedByAuthorId
      if (mid != null && Number.isFinite(Number(mid))) out.modifiedByAuthorId = Number(mid)
      return out
    }
    default:
      return null
  }
}

function serializeRequest(type: string, content: unknown, email = '', comment = ''): { sig: string; base64: string } {
  const payload = { type, email, comment, content }
  const json = JSON.stringify(payload)
  const gzipped = zlib.gzipSync(Buffer.from(json, 'utf8'))
  const base64 = gzipped.toString('base64')
  const sig = crypto.createHash('sha256').update(`${Date.now()}-${base64}`).digest('hex')
  return { sig, base64 }
}

export async function saveRequest(type: string, content: unknown, email = '', comment = ''): Promise<{ id: number; sig: string }> {
  const { sig, base64 } = serializeRequest(type, content, email, comment)
  const rows = await sequelize.query(
    `INSERT INTO fgs_position_requests (spr_id, spr_hash, spr_base64_sqlz) VALUES (DEFAULT, :sig, :base64) RETURNING spr_id`,
    { replacements: { sig, base64 }, type: QueryTypes.SELECT }
  ) as { spr_id: number }[]
  const row = rows[0]
  return { id: row?.spr_id, sig }
}

interface RequestRow {
  spr_id: number
  spr_hash: string
  spr_base64_sqlz: string
}

function decodeRow(row: RequestRow): { type: string; email: string; comment: string; content: unknown } {
  const buf = Buffer.from(row.spr_base64_sqlz, 'base64')
  let json: string
  try {
    json = zlib.gunzipSync(buf).toString('utf8')
  } catch (err) {
    const e = err as { code?: string; message?: string }
    if (e.code === 'Z_DATA_ERROR' || e.message?.includes('incorrect header check')) {
      json = zlib.inflateSync(buf).toString('utf8')
    } else {
      throw err
    }
  }
  return JSON.parse(json)
}

export async function getRequestBySig(sig: string): Promise<{
  id: number
  sig: string
  type: string
  email: string
  comment: string
  content: unknown
} | null> {
  const rows = await sequelize.query(
    `SELECT spr_id, spr_hash, spr_base64_sqlz FROM fgs_position_requests WHERE spr_hash = :sig`,
    { replacements: { sig }, type: QueryTypes.SELECT }
  ) as RequestRow[]
  if (!rows.length) return null
  const decoded = decodeRow(rows[0])
  return {
    id: rows[0].spr_id,
    sig: rows[0].spr_hash,
    type: decoded.type,
    email: decoded.email,
    comment: decoded.comment,
    content: decoded.content,
  }
}

export interface PendingItem {
  id: number
  sig: string
  type: string
  email: string
  comment: string
  details: unknown
  authorId?: number | null
  authorName?: string | null
}

export interface FailedItem {
  id: number
  sig: string
  error: string
}

export async function getPendingRequests(): Promise<{ ok: PendingItem[]; failed: FailedItem[] }> {
  const rows = await sequelize.query(
    `SELECT spr_id, spr_hash, spr_base64_sqlz FROM fgs_position_requests ORDER BY spr_id ASC`,
    { type: QueryTypes.SELECT }
  ) as RequestRow[]
  const ok: PendingItem[] = []
  const failed: FailedItem[] = []
  const emails: string[] = []
  /** Pending list indices that reference an object id (for catalogue model author). */
  const indicesByObjectId = new Map<number, number[]>()
  for (const row of rows) {
    try {
      const decoded = decodeRow(row)
      if (decoded.email) emails.push(decoded.email)
      const details = getRequestContentOverview(decoded.type, decoded.content)
      const itemIndex = ok.length
      ok.push({
        id: row.spr_id,
        sig: row.spr_hash,
        type: decoded.type,
        email: decoded.email,
        comment: decoded.comment,
        details,
      })
      const c = decoded.content
      if (
        (decoded.type === 'OBJECT_UPDATE' || decoded.type === 'OBJECT_DELETE') &&
        c != null &&
        typeof c === 'object'
      ) {
        const cr = c as Record<string, unknown>
        const oid =
          decoded.type === 'OBJECT_UPDATE' ? Number(cr.objectId) : Number(cr.objId)
        if (Number.isInteger(oid) && oid > 0) {
          const arr = indicesByObjectId.get(oid) ?? []
          arr.push(itemIndex)
          indicesByObjectId.set(oid, arr)
        }
      }
    } catch (err) {
      const msg = (err as Error).message
      console.error(`[request] Failed to decode pending request spr_id=${row.spr_id} spr_hash=${row.spr_hash}: ${msg}`)
      failed.push({ id: row.spr_id, sig: row.spr_hash, error: msg })
    }
  }
  const authorByEmail = await authorRepo.findAuthorsByEmails(emails)
  const objectIds = [...indicesByObjectId.keys()]
  const modelAuthorByObjectId =
    objectIds.length > 0 ? await objectRepo.findModelAuthorIdsByObjectIds(objectIds) : new Map<number, number>()
  for (const [objectId, indices] of indicesByObjectId) {
    const derived = modelAuthorByObjectId.get(objectId)
    if (derived == null) continue
    for (const ii of indices) {
      const d = ok[ii]?.details
      if (d && typeof d === 'object') {
        ;(d as Record<string, unknown>).derivedModelAuthorId = derived
      }
    }
  }
  for (const item of ok) {
    const key = item.email != null ? String(item.email).trim().toLowerCase() : null
    const info = key != null ? authorByEmail.get(key) : undefined
    item.authorId = info?.id ?? null
    item.authorName = info?.name ?? null
  }
  return { ok, failed }
}

export async function deleteRequest(sig: string): Promise<void> {
  await sequelize.query(
    `DELETE FROM fgs_position_requests WHERE spr_hash = :sig`,
    { replacements: { sig } }
  )
}

/** Row count in fgs_position_requests (includes rows that fail decode in reviewer UI). */
export async function countPendingRequests(): Promise<number> {
  const rows = await sequelize.query(
    `SELECT COUNT(*)::int AS c FROM fgs_position_requests`,
    { type: QueryTypes.SELECT }
  ) as { c: number }[]
  const n = rows[0]?.c
  return typeof n === 'number' && Number.isFinite(n) ? n : 0
}

/** Collect object and model IDs that have at least one pending request (for badge/indicator). */
export async function getPendingEntityIds(): Promise<{ objectIds: number[]; modelIds: number[] }> {
  const rows = await sequelize.query(
    `SELECT spr_id, spr_hash, spr_base64_sqlz FROM fgs_position_requests ORDER BY spr_id ASC`,
    { type: QueryTypes.SELECT }
  ) as RequestRow[]
  const objectIds = new Set<number>()
  const modelIds = new Set<number>()
  for (const row of rows) {
    try {
      const decoded = decodeRow(row)
      const type = decoded.type
      const content = decoded.content as Record<string, unknown> | null | undefined
      if (!content || typeof content !== 'object') continue
      if (type === 'OBJECT_DELETE') {
        const id = content.objId != null ? Number(content.objId) : NaN
        if (Number.isInteger(id) && id > 0) objectIds.add(id)
      } else if (type === 'OBJECT_UPDATE') {
        const id = content.objectId != null ? Number(content.objectId) : NaN
        if (Number.isInteger(id) && id > 0) objectIds.add(id)
      } else if (type === 'MODEL_UPDATE' || type === 'MODEL_DELETE') {
        const id = (content.modelid ?? content.modelId) != null ? Number((content.modelid ?? content.modelId)) : NaN
        if (Number.isInteger(id) && id > 0) modelIds.add(id)
      }
    } catch {
      // skip failed decode
    }
  }
  return {
    objectIds: Array.from(objectIds),
    modelIds: Array.from(modelIds),
  }
}
