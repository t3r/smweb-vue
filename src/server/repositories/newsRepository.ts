import { sequelize } from '../config/database.js'
import { QueryTypes } from 'sequelize'

export interface NewsItem {
  id: number
  timestamp: string
  authorId: number
  authorName: string | null
  text: string
}

/**
 * Fetch recent news entries (newest first).
 */
export async function findRecent(limit = 20, offset = 0): Promise<NewsItem[]> {
  const rows = (await sequelize.query(
    `SELECT n.ne_id AS id, n.ne_timestamp AS timestamp, n.ne_author AS "authorId", a.au_name AS "authorName", n.ne_text AS text
     FROM fgs_news n
     LEFT JOIN fgs_authors a ON a.au_id = n.ne_author
     ORDER BY n.ne_timestamp DESC
     LIMIT :limit OFFSET :offset`,
    {
      replacements: { limit: Number(limit), offset: Number(offset) },
      type: QueryTypes.SELECT,
    }
  )) as { id: number; timestamp: Date; authorId: number; authorName: string | null; text: string }[]
  return rows.map((r) => ({
    id: r.id,
    timestamp: r.timestamp instanceof Date ? r.timestamp.toISOString() : String(r.timestamp),
    authorId: r.authorId,
    authorName: r.authorName != null ? String(r.authorName).trim() || null : null,
    text: r.text ?? '',
  }))
}

export async function getTotalCount(): Promise<number> {
  const rows = (await sequelize.query(
    `SELECT COUNT(*) AS c FROM fgs_news`,
    { type: QueryTypes.SELECT }
  )) as { c: string }[]
  return Number(rows[0]?.c ?? 0)
}

/**
 * Insert a news entry (e.g. position request processed).
 * fgs_news: ne_id (serial), ne_timestamp (set by trigger), ne_author, ne_text.
 * The table has a unique index on ne_timestamp; a short delay before insert reduces collision risk.
 */
export async function insertOne(authorId: number, text: string): Promise<void> {
  const aid = Number(authorId)
  const safeText = String(text).trim() || '—'
  await sequelize.query(
    `INSERT INTO fgs_news (ne_author, ne_text) VALUES (:authorId, :text)`,
    { replacements: { authorId: aid, text: safeText }, type: QueryTypes.INSERT }
  )
}
