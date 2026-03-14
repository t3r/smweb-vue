import * as authorRepo from '../repositories/authorRepository.js'
import * as authRepo from '../repositories/authRepository.js'

interface AuthorRow {
  id: number
  name: string
  email?: string
  notes?: string
  modelsCount?: number
}

function toApiAuthor(row: AuthorRow | Record<string, unknown> | null, includeEmail = false): Record<string, unknown> | null {
  if (!row) return null
  const r = typeof (row as { toJSON?: () => Record<string, unknown> }).toJSON === 'function'
    ? (row as { toJSON: () => Record<string, unknown> }).toJSON()
    : (row as Record<string, unknown>)
  const out: Record<string, unknown> = {
    id: r.id,
    name: r.name,
    description: r.notes,
    modelsCount: r.modelsCount,
  }
  if (includeEmail) out.email = r.email ?? null
  return out
}

export async function getAuthors(
  offset = 0,
  limit = 20,
  currentAuthorId: number | null = null,
  sortField: string | null = null,
  sortOrder: number | null = null,
  name: string | null = null,
  description: string | null = null
): Promise<{ authors: (Record<string, unknown> | null)[]; total: number; offset: number; limit: number }> {
  const opts: Record<string, unknown> = { offset, limit }
  if (sortField != null) opts.sortField = sortField
  if (sortOrder != null) opts.sortOrder = sortOrder === 1 ? 1 : -1
  if (name != null && String(name).trim() !== '') opts.name = String(name).trim()
  if (description != null && String(description).trim() !== '') opts.description = String(description).trim()
  const { authors: rows, total } = await authorRepo.findAll(opts as authorRepo.FindAllAuthorsOptions)
  const id = currentAuthorId != null ? Number(currentAuthorId) : null
  return {
    authors: (rows as unknown[]).map((row) => toApiAuthor((row as unknown) as AuthorRow, id != null && (row as { id: number }).id === id)),
    total,
    offset: Number(offset),
    limit: Number(limit),
  }
}

export async function getAuthorById(
  id: number,
  currentAuthorId: number | null = null,
  currentUserRole: string | null = null
): Promise<Record<string, unknown> | null> {
  const row = await authorRepo.findById(id)
  if (!row) return null
  const isOwn = currentAuthorId != null && Number(id) === Number(currentAuthorId)
  const author = toApiAuthor((row as unknown) as AuthorRow, isOwn)
  if (!author) return null
  if (isOwn) {
    const lastLogin = await authorRepo.getLastLoginByAuthorId(id)
    if (lastLogin != null) author.lastLogin = lastLogin
  }
  const includeRole = isOwn || currentUserRole === 'admin'
  if (includeRole) {
    const role = await authRepo.getRoleForAuthor(id)
    author.role = role
  }
  return author
}

export async function updateAuthorRole(authorId: number, role: string): Promise<void> {
  await authRepo.setRoleForAuthor(authorId, role)
}
