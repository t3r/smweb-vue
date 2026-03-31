import { Op, QueryTypes } from 'sequelize'
import Author from '../models/Author.js'
import Model from '../models/Model.js'
import { sequelize } from '../config/database.js'

const AUTHOR_SORT_FIELDS = ['id', 'name', 'description']

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
  return { authors: rows, total: count }
}

export async function findById(id: number): Promise<Record<string, unknown> | null> {
  const row = await Author.findByPk(id)
  if (!row) return null
  const modelsCount = await Model.count({ where: { authorId: id } })
  return { ...(row.toJSON() as Record<string, unknown>), modelsCount }
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

export async function findAuthorIdsByEmails(emails: string[]): Promise<Map<string, number>> {
  if (!emails?.length) return new Map()
  const normalized = [...new Set(emails.map((e) => String(e).trim().toLowerCase()).filter(Boolean))]
  if (!normalized.length) return new Map()
  const rows = await Author.findAll({
    attributes: ['id', 'email'],
    where: {
      [Op.or]: normalized.map((email) => ({ email: { [Op.iLike]: email } })),
    },
  })
  const map = new Map<string, number>()
  for (const row of rows || []) {
    const r = row as { id?: number; email?: string }
    const e = r.email != null ? String(r.email).trim().toLowerCase() : null
    if (e != null && r.id != null) map.set(e, r.id)
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
