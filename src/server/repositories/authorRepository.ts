import { Op, QueryTypes } from 'sequelize'
import Author from '../models/Author.js'
import Model from '../models/Model.js'
import { sequelize } from '../config/database.js'

const AUTHOR_SORT_FIELDS = ['id', 'name', 'description']

/** True when the author has at least one row in fgs_extuserids (OAuth / external identity). */
export async function hasLinkedIdentityProvider(authorId: number): Promise<boolean> {
  const safeId = Number(authorId)
  if (!Number.isInteger(safeId) || safeId < 1) return false
  const rows = (await sequelize.query(
    `SELECT EXISTS (SELECT 1 FROM fgs_extuserids WHERE eu_author_id = :authorId) AS "exists"`,
    { replacements: { authorId: safeId }, type: QueryTypes.SELECT }
  )) as { exists: boolean }[]
  return Boolean(rows?.[0]?.exists)
}

/** Which of the given author ids appear in fgs_extuserids (batch for list pages). */
export async function findAuthorIdsWithLinkedIdentity(ids: number[]): Promise<Set<number>> {
  const unique = [...new Set(ids.map((id) => Number(id)).filter((id) => Number.isInteger(id) && id > 0))]
  if (!unique.length) return new Set()
  const rows = (await sequelize.query(
    `SELECT DISTINCT eu_author_id AS id FROM fgs_extuserids WHERE eu_author_id IN (:ids)`,
    { replacements: { ids: unique }, type: QueryTypes.SELECT }
  )) as { id: number }[]
  return new Set(rows.map((r) => Number(r.id)).filter((id) => Number.isInteger(id)))
}

function getAuthorOrder(sortField: string | undefined, sortOrder: number | undefined): [string, string][] {
  const dir = sortOrder === 1 ? 'ASC' : 'DESC'
  const nulls = dir === 'ASC' ? 'NULLS LAST' : 'NULLS FIRST'
  if (!sortField || !AUTHOR_SORT_FIELDS.includes(sortField)) {
    return [['name', 'ASC NULLS LAST'], ['id', 'ASC']]
  }
  if (sortField === 'description') {
    return [['notes', `${dir} ${nulls}`], ['id', 'ASC']]
  }
  return [[sortField, `${dir} ${nulls}`], ['id', 'ASC']]
}

export interface FindAllAuthorsOptions {
  offset?: number
  limit?: number
  sortField?: string
  sortOrder?: number
  name?: string
  description?: string
}

export async function findAll(options: FindAllAuthorsOptions = {}): Promise<{ authors: unknown[]; total: number }> {
  const { offset = 0, limit = 20, sortField, sortOrder, name: nameSearch, description: descSearch } = options
  const where: Record<string, unknown> = {}
  if (nameSearch != null && String(nameSearch).trim() !== '') {
    where.name = { [Op.iLike]: `%${String(nameSearch).trim()}%` }
  }
  if (descSearch != null && String(descSearch).trim() !== '') {
    where.notes = { [Op.iLike]: `%${String(descSearch).trim()}%` }
  }
  const order = getAuthorOrder(sortField, sortOrder)
  const { rows, count } = await Author.findAndCountAll({
    attributes: ['id', 'name', 'email', 'notes'],
    where: Object.keys(where).length ? where : undefined,
    order,
    offset: Number(offset),
    limit: Number(limit),
  })
  const linkedSet = await findAuthorIdsWithLinkedIdentity(rows.map((row) => Number(row.get('id'))))
  const authors = rows.map((row) => {
    const plain = row.get({ plain: true }) as { id: number; name?: string; email?: string; notes?: string }
    return { ...plain, linkedIdentityProvider: linkedSet.has(Number(plain.id)) }
  })
  return { authors, total: count }
}

export async function findById(id: number): Promise<Record<string, unknown> | null> {
  const row = await Author.findByPk(id)
  if (!row) return null
  const safeId = Number(id)
  const [modelsCount, linkedIdentityProvider] = await Promise.all([
    Model.count({ where: { authorId: safeId } }),
    hasLinkedIdentityProvider(safeId),
  ])
  return { ...(row.toJSON() as Record<string, unknown>), modelsCount, linkedIdentityProvider }
}

/** Get author id and name by email (for display). Returns null if not found. */
export async function findAuthorByEmail(email: string): Promise<{ id: number; name: string } | null> {
  const e = String(email).trim().toLowerCase()
  if (!e) return null
  const row = await Author.findOne({
    attributes: ['id', 'name'],
    where: { email: { [Op.iLike]: e } },
  })
  if (!row) return null
  const r = row as unknown as { id: number; name?: string }
  return { id: r.id, name: (r.name != null ? String(r.name).trim() : '') || email }
}

/** Match submitter emails to author id and display name (for position-request queues). */
export async function findAuthorsByEmails(
  emails: string[]
): Promise<Map<string, { id: number; name: string | null }>> {
  if (!emails?.length) return new Map()
  const normalized = [...new Set(emails.map((e) => String(e).trim().toLowerCase()).filter(Boolean))]
  if (!normalized.length) return new Map()
  const rows = await Author.findAll({
    attributes: ['id', 'email', 'name'],
    where: {
      [Op.or]: normalized.map((email) => ({ email: { [Op.iLike]: email } })),
    },
  })
  const map = new Map<string, { id: number; name: string | null }>()
  const rowList = (rows || []) as { id?: number; email?: string; name?: string | null }[]
  for (const inputNorm of normalized) {
    const found = rowList.find((r) => {
      if (r.email == null || r.id == null) return false
      return String(r.email).trim().toLowerCase() === inputNorm
    })
    if (!found?.id) continue
    const rawName = found.name != null ? String(found.name).trim() : ''
    const entry = { id: found.id, name: rawName !== '' ? rawName : null }
    map.set(inputNorm, entry)
    const dbKey = String(found.email).trim().toLowerCase()
    if (dbKey !== inputNorm) map.set(dbKey, entry)
  }
  return map
}

export async function getLastLoginByAuthorId(authorId: number): Promise<string | null> {
  const rows = (await sequelize.query(
    `SELECT MAX(eu_lastlogin) AS "lastLogin" FROM fgs_extuserids WHERE eu_author_id = :authorId`,
    {
      replacements: { authorId: Number(authorId) },
      type: QueryTypes.SELECT,
    }
  )) as unknown as { lastLogin: Date | string | null }[]
  const row = rows?.[0]
  const val = row?.lastLogin
  if (val == null) return null
  return val instanceof Date ? val.toISOString() : String(val)
}

export async function insertOne(name: string, email: string): Promise<{ id: number }> {
  const row = (await Author.create({ name, email })) as unknown as { id: number }
  return { id: row.id }
}

/** Updates au_notes. Pass null to clear. Returns whether a row was updated. */
export async function updateNotesById(id: number, notes: string | null): Promise<boolean> {
  const safeId = Number(id)
  if (!Number.isInteger(safeId) || safeId < 1) return false
  const [updated] = await Author.update({ notes }, { where: { id: safeId } })
  return updated > 0
}

export interface AuthorLeaderboardEntry {
  id: number
  name: string | null
  count: number
}

/** Non-deleted models attributed to `mo_author`, ordered by count. */
export async function findTopModelAuthorsAllTime(limit = 3): Promise<AuthorLeaderboardEntry[]> {
  const safeLimit = Math.min(Math.max(Number(limit) || 3, 1), 50)
  const rows = (await sequelize.query(
    `
    SELECT a.au_id AS id, a.au_name AS name, COUNT(m.mo_id)::int AS count
    FROM fgs_models m
    INNER JOIN fgs_authors a ON a.au_id = m.mo_author
    WHERE m.mo_deleted IS NULL AND m.mo_author IS NOT NULL
    GROUP BY a.au_id, a.au_name
    ORDER BY count DESC, a.au_name ASC NULLS LAST, a.au_id ASC
    LIMIT :limit
    `,
    { replacements: { limit: safeLimit }, type: QueryTypes.SELECT }
  )) as { id: number; name: string | null; count: number }[]
  return rows.map((r) => ({
    id: Number(r.id),
    name: r.name != null ? String(r.name) : null,
    count: Number(r.count) || 0,
  }))
}

/**
 * Models with `mo_modified` in the last `days`, credited to `COALESCE(mo_modified_by, mo_author)`.
 */
export async function findTopModelAuthorsRecentDays(days: number, limit = 3): Promise<AuthorLeaderboardEntry[]> {
  const safeDays = Math.min(Math.max(Number(days) || 180, 1), 3650)
  const safeLimit = Math.min(Math.max(Number(limit) || 3, 1), 50)
  const since = new Date()
  since.setUTCDate(since.getUTCDate() - safeDays)
  since.setUTCHours(0, 0, 0, 0)
  const rows = (await sequelize.query(
    `
    SELECT a.au_id AS id, a.au_name AS name, COUNT(*)::int AS count
    FROM fgs_models m
    INNER JOIN fgs_authors a ON a.au_id = COALESCE(m.mo_modified_by, m.mo_author)
    WHERE m.mo_deleted IS NULL
      AND COALESCE(m.mo_modified_by, m.mo_author) IS NOT NULL
      AND m.mo_modified >= :since
    GROUP BY a.au_id, a.au_name
    ORDER BY count DESC, a.au_name ASC NULLS LAST, a.au_id ASC
    LIMIT :limit
    `,
    { replacements: { since, limit: safeLimit }, type: QueryTypes.SELECT }
  )) as { id: number; name: string | null; count: number }[]
  return rows.map((r) => ({
    id: Number(r.id),
    name: r.name != null ? String(r.name) : null,
    count: Number(r.count) || 0,
  }))
}
