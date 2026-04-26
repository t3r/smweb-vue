import { timingSafeEqual } from 'node:crypto'
import type { Request, Response, NextFunction } from 'express'

const REALM = 'API documentation'

function timingSafeStringEqual(a: string, b: string): boolean {
  const max = 512
  const bufA = Buffer.alloc(max, 0)
  const bufB = Buffer.alloc(max, 0)
  Buffer.from(a, 'utf8').copy(bufA, 0, 0, max)
  Buffer.from(b, 'utf8').copy(bufB, 0, 0, max)
  return timingSafeEqual(bufA, bufB)
}

/**
 * HTTP Basic Auth for `/api-docs`.
 * Set `API_DOCS_USERNAME` and `API_DOCS_PASSWORD` (both non-empty). If either is missing, the route responds 503.
 */
export function apiDocsBasicAuth(req: Request, res: Response, next: NextFunction): void {
  const expectedUser = (process.env.API_DOCS_USERNAME ?? '').trim()
  const expectedPass = (process.env.API_DOCS_PASSWORD ?? '').trim()
  if (!expectedUser || !expectedPass) {
    res.status(503).json({
      error: 'API documentation is disabled until API_DOCS_USERNAME and API_DOCS_PASSWORD are set.',
    })
    return
  }

  const header = req.headers.authorization
  if (typeof header !== 'string' || !header.startsWith('Basic ')) {
    res.setHeader('WWW-Authenticate', `Basic realm="${REALM}"`)
    res.status(401).end()
    return
  }

  let decoded = ''
  try {
    decoded = Buffer.from(header.slice(6).trim(), 'base64').toString('utf8')
  } catch {
    res.setHeader('WWW-Authenticate', `Basic realm="${REALM}"`)
    res.status(401).end()
    return
  }

  const colon = decoded.indexOf(':')
  const user = colon >= 0 ? decoded.slice(0, colon) : ''
  const pass = colon >= 0 ? decoded.slice(colon + 1) : ''

  if (!timingSafeStringEqual(user, expectedUser) || !timingSafeStringEqual(pass, expectedPass)) {
    res.setHeader('WWW-Authenticate', `Basic realm="${REALM}"`)
    res.status(401).end()
    return
  }

  next()
}
