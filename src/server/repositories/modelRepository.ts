import { Op } from 'sequelize'
import Model from '../models/Model.js'
import Author from '../models/Author.js'
import ModelGroup from '../models/ModelGroup.js'
import { cache, cacheTtlSeconds } from '../config/cache.js'
import * as objectRepo from './objectRepository.js'

const CACHE_KEY_MODELFILE = (id: number): string => `model:modelfile:${id}`

const SORT_FIELDS = ['id', 'name', 'lastUpdated', 'group', 'author']

function getOrder(sortField: string | undefined, sortOrder: number | undefined): [string | string[], string][] | [string, string, string][] {
  const dir = sortOrder === 1 ? 'ASC' : 'DESC'
  const nulls = dir === 'ASC' ? 'NULLS LAST' : 'NULLS FIRST'
  if (!sortField || !SORT_FIELDS.includes(sortField)) {
    return [['modified', 'DESC NULLS LAST']]
  }
  switch (sortField) {
    case 'id':
      return [['id', `${dir} ${nulls}`]]
    case 'name':
      return [
        ['name', `${dir} ${nulls}`],
        ['path', `${dir} ${nulls}`],
      ]
    case 'lastUpdated':
      return [['modified', `${dir} NULLS LAST`]]
    case 'group':
      return [['ModelGroup', 'name', `${dir} ${nulls}`] as [string, string, string]]
    case 'author':
      return [['Author', 'name', `${dir} ${nulls}`] as [string, string, string]]
    default:
      return [['modified', 'DESC NULLS LAST']]
  }
}

export interface FindAllModelsOptions {
  offset?: number
  limit?: number
  group?: number
  author?: number
  /** Partial case-insensitive match on author name (joined Author row). */
  authorSearch?: string
  sortField?: string
  sortOrder?: number
  search?: string
}

const notDeletedWhere = { deleted: null }

export async function findAll(options: FindAllModelsOptions = {}): Promise<{ models: unknown[]; total: number }> {
  const { offset = 0, limit = 20, group, author, authorSearch, sortField, sortOrder, search } = options
  const where: Record<string, unknown> = { ...notDeletedWhere }
  if (group != null) where.shared = group
  if (author != null) where.authorId = author
  if (search != null && String(search).trim() !== '') {
    const term = `%${String(search).trim()}%`
    ;(where as Record<string, unknown>)[Op.or as unknown as string] = [
      { name: { [Op.iLike]: term } },
      { path: { [Op.iLike]: term } },
    ]
  }
  const authorTrim = authorSearch != null ? String(authorSearch).trim() : ''
  const authorInclude: {
    model: typeof Author
    attributes: string[]
    required: boolean
    where?: Record<string, unknown>
  } = { model: Author, attributes: ['id', 'name'], required: true }
  if (authorTrim !== '') {
    authorInclude.where = { name: { [Op.iLike]: `%${authorTrim}%` } }
  }
  const order = getOrder(sortField, sortOrder) as [string, string][]
  const { rows, count } = await Model.findAndCountAll({
    where,
    include: [
      authorInclude,
      { model: ModelGroup, attributes: ['id', 'name'], required: true },
    ],
    offset: Number(offset),
    limit: Number(limit),
    order,
  })
  return { models: rows, total: count }
}

export async function findRecent(limit = 10): Promise<unknown[]> {
  const rows = await Model.findAll({
    where: notDeletedWhere,
    include: [
      { model: Author, attributes: ['id', 'name'], required: true },
      { model: ModelGroup, attributes: ['id', 'name'], required: true },
    ],
    limit: Number(limit),
    order: [['modified', 'DESC NULLS LAST']],
  })
  return rows
}

export async function findById(id: number): Promise<unknown> {
  return Model.findOne({
    where: { id: Number(id), ...notDeletedWhere },
    include: [
      { model: Author, attributes: ['id', 'name', 'email'], required: false },
      { model: ModelGroup, attributes: ['id', 'name'], required: false },
    ],
  })
}

/** Legacy STG lookup: `mo_path` matches the XML filename (e.g. `windturbine.xml`). */
export async function findIdByPathBasename(basename: string): Promise<number | null> {
  const name = String(basename || '').trim()
  if (!name) return null
  const row = await Model.findOne({
    where: { path: name, ...notDeletedWhere },
    attributes: ['id'],
    raw: true,
  }) as { id?: number } | null
  return row?.id != null ? Number(row.id) : null
}

export async function findModelfileBase64ById(id: number): Promise<string | null> {
  const key = CACHE_KEY_MODELFILE(id)
  if (cacheTtlSeconds > 0) {
    const cached = cache.get<string>(key)
    if (cached !== undefined) return cached
  }
  const row = await Model.findOne({
    where: { id: Number(id), ...notDeletedWhere },
    attributes: ['modelfile'],
    raw: true,
  }) as { modelfile?: string } | null
  const value = row?.modelfile ?? null
  if (cacheTtlSeconds > 0 && value != null) cache.set(key, value, cacheTtlSeconds)
  return value
}

export async function findThumbnailById(id: number): Promise<{ buffer: Buffer } | null> {
  const row = await Model.findOne({
    where: { id: Number(id), ...notDeletedWhere },
    attributes: ['thumbfile'],
    raw: true,
  }) as { thumbfile?: string } | null
  if (!row?.thumbfile) return null
  const buffer = Buffer.from(row.thumbfile, 'base64')
  return buffer.length > 0 ? { buffer } : null
}

/** Raw base64 text in `mo_thumbfile` (for merging model updates without re-upload). */
export async function findThumbfileBase64StringById(id: number): Promise<string | null> {
  const row = await Model.findOne({
    where: { id: Number(id), ...notDeletedWhere },
    attributes: ['thumbfile'],
    raw: true,
  }) as { thumbfile?: string | null } | null
  const t = row?.thumbfile
  if (t == null || String(t).trim() === '') return null
  return String(t)
}

export interface InsertModelData {
  path: string
  authorId: number
  name?: string
  notes?: string
  thumbfileBase64?: string
  modelfileBase64: string
  shared: number
  modifiedBy?: number
}

export async function insertOne(data: InsertModelData): Promise<{ id: number }> {
  const { path, authorId, name, notes, thumbfileBase64, modelfileBase64, shared, modifiedBy } = data
  const row = await Model.create({
    path,
    authorId: Number(authorId),
    name: name || '',
    notes: notes || '',
    thumbfile: thumbfileBase64 || null,
    modelfile: modelfileBase64,
    shared: Number(shared),
    modifiedBy: modifiedBy != null ? Number(modifiedBy) : undefined,
  })
  return { id: (row as unknown as { id: number }).id }
}

export interface UpdateModelData {
  path?: string
  authorId?: number
  name?: string
  notes?: string
  thumbfileBase64?: string
  modelfileBase64?: string
  shared?: number
  modifiedBy?: number
}

export async function updateOne(id: number, data: UpdateModelData): Promise<void> {
  const numId = Number(id)
  const { path, authorId, name, notes, thumbfileBase64, modelfileBase64, shared, modifiedBy } = data
  await Model.update(
    {
      path,
      authorId: authorId != null ? Number(authorId) : undefined,
      name: name != null ? name : undefined,
      notes: notes != null ? notes : undefined,
      thumbfile: thumbfileBase64 != null ? thumbfileBase64 : undefined,
      modelfile: modelfileBase64 != null ? modelfileBase64 : undefined,
      shared: shared != null ? Number(shared) : undefined,
      modifiedBy: modifiedBy != null ? Number(modifiedBy) : undefined,
    },
    { where: { id: numId } }
  )
  if (cacheTtlSeconds > 0) cache.del(CACHE_KEY_MODELFILE(numId))
}

export async function deleteOne(id: number, modifiedBy?: number): Promise<void> {
  const numId = Number(id)
  const objectCount = await objectRepo.countActiveByModelId(numId)
  if (objectCount > 0) {
    throw new Error(`Cannot delete model: ${objectCount} object(s) still reference this model`)
  }
  await Model.update(
    {
      deleted: new Date(),
      modifiedBy: modifiedBy != null ? Number(modifiedBy) : undefined,
    },
    { where: { id: numId } }
  )
  if (cacheTtlSeconds > 0) cache.del(CACHE_KEY_MODELFILE(numId))
}
