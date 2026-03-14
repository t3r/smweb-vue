import crypto from 'crypto'
import type { Request, Response, NextFunction } from 'express'

/**
 * Validates `Authorization: Bearer <token>` against `EMAIL_QUEUE_BEARER_TOKEN`.
 * Used for external mailer access to /api/email-queue/receive and /delete.
 */
export function requireEmailQueueBearer(req: Request, res: Response, next: NextFunction): void {
  const expected = process.env.EMAIL_QUEUE_BEARER_TOKEN?.trim()
  if (!expected) {
    res.status(503).json({ error: 'Email queue API is not configured (EMAIL_QUEUE_BEARER_TOKEN)' })
    return
  }

  const header = req.headers.authorization
  if (typeof header !== 'string' || !header.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header; expected Bearer token' })
    return
  }

  const token = header.slice(7).trim()
  const a = Buffer.from(token, 'utf8')
  const b = Buffer.from(expected, 'utf8')
  if (a.length !== b.length) {
    res.status(401).json({ error: 'Invalid token' })
    return
  }
  try {
    if (!crypto.timingSafeEqual(a, b)) {
      res.status(401).json({ error: 'Invalid token' })
      return
    }
  } catch {
    res.status(401).json({ error: 'Invalid token' })
    return
  }

  next()
}
