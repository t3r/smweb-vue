import * as authRepo from '../repositories/authRepository.js'
import Author from '../models/Author.js'
import { AUTH_PROVIDER_GITHUB, AUTH_PROVIDER_GOOGLE, AUTH_PROVIDER_GITLAB } from '../config/authConstants.js'

export interface SessionUser {
  id: number
  name: string
  email: string
  role: string
}

export async function findOrCreateUser(
  authority: number,
  externalId: string,
  displayName = '',
  email = ''
): Promise<SessionUser> {
  const { authorId } = await authRepo.findOrCreateExternalUser(
    authority,
    externalId,
    displayName || 'Unknown',
    email || ''
  )
  const role = await authRepo.getRoleForAuthor(authorId)
  const author = await Author.findByPk(authorId, { attributes: ['id', 'name', 'email'] })
  return {
    id: authorId,
    name: (String((author as { get?: (k: string) => unknown })?.get?.('name') ?? displayName)) || 'User',
    email: (String((author as { get?: (k: string) => unknown })?.get?.('email') ?? email)) || '',
    role,
  }
}

/** Load current name, email, role from DB for session restore (role must stay in sync with fgs_user_roles). */
export async function getSessionUserByAuthorId(authorId: number): Promise<SessionUser | null> {
  if (!Number.isInteger(authorId) || authorId < 1) return null
  const author = await Author.findByPk(authorId, { attributes: ['id', 'name', 'email'] })
  if (!author) return null
  const role = await authRepo.getRoleForAuthor(authorId)
  const row = author as { get?: (k: string) => unknown }
  return {
    id: authorId,
    name: String(row.get?.('name') ?? 'User') || 'User',
    email: String(row.get?.('email') ?? '') || '',
    role,
  }
}

export { AUTH_PROVIDER_GITHUB, AUTH_PROVIDER_GOOGLE, AUTH_PROVIDER_GITLAB }
