import { QueryTypes } from 'sequelize'
import { sequelize } from '../config/database.js'
import * as authorRepo from './authorRepository.js'
import { ROLE_USER } from '../config/authConstants.js'

export async function findExternalUser(authority: number, externalId: string): Promise<{ authorId: number } | null> {
  const rows = (await sequelize.query(
    `SELECT eu_author_id AS "authorId"
     FROM fgs_extuserids
     WHERE eu_authority::text = :authority AND eu_external_id = :externalId
     LIMIT 1`,
    {
      replacements: { authority: String(authority), externalId: String(externalId) },
      type: QueryTypes.SELECT,
    }
  )) as unknown as { authorId: number }[]
  const row = rows?.[0]
  if (!row?.authorId) return null
  return { authorId: row.authorId }
}

export async function findOrCreateExternalUser(
  authority: number,
  externalId: string,
  name = '',
  email = ''
): Promise<{ authorId: number }> {
  const existing = await findExternalUser(authority, externalId)
  if (existing) {
    await sequelize.query(
      `UPDATE fgs_extuserids SET eu_lastlogin = CURRENT_TIMESTAMP
       WHERE eu_authority::text = :authority AND eu_external_id = :externalId`,
      { replacements: { authority: String(authority), externalId: String(externalId) } }
    )
    return { authorId: existing.authorId }
  }
  let authorId: number
  const emailTrimmed = typeof email === 'string' ? email.trim() : ''
  if (emailTrimmed) {
    const rows = (await sequelize.query(
      `SELECT au_id AS "authorId" FROM fgs_authors
       WHERE LOWER(TRIM(au_email)) = LOWER(TRIM(:email))
       LIMIT 1`,
      {
        replacements: { email: emailTrimmed },
        type: QueryTypes.SELECT,
      }
    )) as unknown as { authorId: number }[]
    const match = rows?.[0]
    authorId = match?.authorId
  }

  if (!authorId) {
    const created = await authorRepo.insertOne(name || 'Unknown', email || '')
    authorId = created.id
  }

  await sequelize.query(
    `INSERT INTO fgs_extuserids (eu_authority, eu_external_id, eu_author_id, eu_lastlogin)
     VALUES (CAST(:authority AS integer), :externalId, :authorId, CURRENT_TIMESTAMP)`,
    {
      replacements: {
        authority: String(authority),
        externalId: String(externalId),
        authorId,
      },
    }
  )
  await ensureUserRole(authorId, ROLE_USER)
  return { authorId }
}

export async function getRoleForAuthor(authorId: number): Promise<string> {
  try {
    const rows = (await sequelize.query(
      `SELECT role FROM fgs_user_roles WHERE au_id = :authorId LIMIT 1`,
      {
        replacements: { authorId: Number(authorId) },
        type: QueryTypes.SELECT,
      }
    )) as unknown as { role: string }[]
    const row = rows?.[0]
    return row?.role && ['user', 'reviewer', 'tester', 'admin'].includes(row.role) ? row.role : ROLE_USER
  } catch {
    return ROLE_USER
  }
}

async function ensureUserRole(authorId: number, role: string): Promise<void> {
  try {
    await sequelize.query(
      `INSERT INTO fgs_user_roles (au_id, role) VALUES (:authorId, :role)
       ON CONFLICT (au_id) DO NOTHING`,
      { replacements: { authorId: Number(authorId), role } }
    )
  } catch {
    // Table may not exist yet
  }
}

const VALID_ROLES = ['user', 'reviewer', 'tester', 'admin']

export async function setRoleForAuthor(authorId: number, role: string): Promise<void> {
  if (!VALID_ROLES.includes(role)) throw new Error('Invalid role')
  await sequelize.query(
    `INSERT INTO fgs_user_roles (au_id, role) VALUES (:authorId, :role)
     ON CONFLICT (au_id) DO UPDATE SET role = EXCLUDED.role`,
    { replacements: { authorId: Number(authorId), role } }
  )
}
