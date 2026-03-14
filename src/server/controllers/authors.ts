import type { Request, Response } from 'express'
import * as authorService from '../services/authorService.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'
import { validateId, validateOffset, validateLimit, validateDescriptionSearch } from '../utils/validateInput.js'

const AUTHOR_SORT_FIELDS = new Set(['id', 'name', 'description'])

export async function getAuthors(req: Request, res: Response): Promise<void> {
  try {
    const { offset, limit, sortField, sortOrder, name, description } = req.query
    const currentAuthorId = req.user?.id ?? null
    const sortFieldVal = sortField && AUTHOR_SORT_FIELDS.has(String(sortField)) ? String(sortField) : null
    const sortOrderVal = sortOrder != null ? (Number(sortOrder) === 1 ? 1 : -1) : null
    const nameVal = validateDescriptionSearch(name)
    const descriptionVal = validateDescriptionSearch(description)
    const data = await authorService.getAuthors(
      validateOffset(offset),
      validateLimit(limit),
      currentAuthorId,
      sortFieldVal,
      sortOrderVal,
      nameVal,
      descriptionVal
    )
    res.json(data)
  } catch (err) {
    logDbError(err, 'GET /api/authors')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function getAuthor(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    if (id == null) {
      res.status(400).json({ error: 'Invalid author id' })
      return
    }
    const currentAuthorId = req.user?.id ?? null
    const currentUserRole = req.user?.role ?? null
    const author = await authorService.getAuthorById(id, currentAuthorId, currentUserRole)
    if (!author) {
      res.status(404).json({ error: 'Author not found' })
      return
    }
    res.json(author)
  } catch (err) {
    logDbError(err, 'GET /api/authors/:id')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

const VALID_ROLES = new Set(['user', 'reviewer', 'admin'])

export async function updateAuthorRole(req: Request, res: Response): Promise<void> {
  try {
    const id = validateId(req.params.id)
    if (id == null) {
      res.status(400).json({ error: 'Invalid author id' })
      return
    }
    const role = (req.body as { role?: string })?.role
    if (!role || typeof role !== 'string' || !VALID_ROLES.has(role)) {
      res.status(400).json({ error: 'Invalid role; use user, reviewer, or admin' })
      return
    }
    await authorService.updateAuthorRole(id, role)
    res.json({ ok: true, role })
  } catch (err) {
    logDbError(err, 'PUT /api/authors/:id/role')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
