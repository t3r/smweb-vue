import crypto from 'node:crypto'
import { Router, type Request, type Response, type NextFunction } from 'express'
import passport from '../config/passport.js'
import { requireAuth } from '../middleware/auth.js'
import * as accountMergeService from '../services/accountMergeService.js'
import { AccountMergeError } from '../services/accountMergeService.js'

const router = Router()
const FRONTEND_URL = process.env.FRONTEND_URL || process.env.CLIENT_URL || 'http://localhost:5173'

/** Must match session secret so HMAC is not guessable. */
function oauthStateSecret(): string {
  return process.env.SESSION_SECRET || 'change-me-in-production'
}

const OAUTH_STATE_TTL_MS = 20 * 60 * 1000

function redirectToFrontend(req: Request, res: Response, path = ''): void {
  const url = `${FRONTEND_URL.replace(/\/$/, '')}${path ? `/${path.replace(/^\//, '')}` : ''}`
  res.redirect(url)
}

function loginErrorParams(reason: string, message = ''): string {
  const params = new URLSearchParams({ auth_error: '1' })
  if (reason) params.set('reason', reason)
  if (message && typeof message === 'string' && message.length < 500) params.set('message', message)
  return '?' + params.toString()
}

function sanitizeErrorMessage(err: unknown): string {
  if (!err || typeof err !== 'object') return ''
  const msg = (err as Error).message || (err as { toString?: () => string }).toString?.() || String(err)
  return msg.slice(0, 200).replace(/\s+/g, ' ').trim()
}

/** Allow only same-app relative paths (no protocol / open redirects). */
function sanitizeReturnTo(raw: unknown): string | null {
  if (raw == null) return null
  const s = String(raw).trim()
  if (!s.startsWith('/') || s.startsWith('//')) return null
  if (s.includes('://') || s.includes('\0') || s.length > 2048) return null
  if (/[\r\n]/.test(s)) return null
  return s
}

/**
 * Put post-login path in OAuth `state` (signed). Session cookies are often not sent on the
 * top-level redirect from GitHub/GitLab back to the callback when SameSite=strict, so
 * req.session.oauthReturnTo was lost while login still succeeded → user always hit home.
 */
function encodeOAuthReturnState(returnTo: string | null): string {
  const payload = { rt: returnTo, t: Date.now() }
  const body = Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url')
  const sig = crypto.createHmac('sha256', oauthStateSecret()).update(body).digest('base64url')
  return `${body}.${sig}`
}

function decodeOAuthReturnState(state: unknown): string | null {
  if (state == null || typeof state !== 'string' || !state.includes('.')) return null
  const dot = state.lastIndexOf('.')
  const body = state.slice(0, dot)
  const sig = state.slice(dot + 1)
  const expected = crypto.createHmac('sha256', oauthStateSecret()).update(body).digest('base64url')
  try {
    const sigBuf = Buffer.from(sig, 'utf8')
    const expBuf = Buffer.from(expected, 'utf8')
    if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) return null
  } catch {
    return null
  }
  try {
    const p = JSON.parse(Buffer.from(body, 'base64url').toString('utf8')) as { rt?: unknown; t?: number }
    if (typeof p.t !== 'number' || Date.now() - p.t > OAUTH_STATE_TTL_MS) return null
    return sanitizeReturnTo(p.rt)
  } catch {
    return null
  }
}

router.get('/me', (req: Request, res: Response) => {
  if (!req.isAuthenticated || !req.isAuthenticated()) {
    res.status(401).json({ user: null })
    return
  }
  res.json({
    user: {
      id: req.user!.id,
      name: req.user!.name,
      email: req.user!.email,
      role: req.user!.role,
    },
  })
})

function requireGitHubConfig(req: Request, res: Response, next: NextFunction): void {
  if (process.env.GITHUB_CLIENT_ID && process.env.GITHUB_CLIENT_SECRET) next()
  else redirectToFrontend(req, res, '?auth_error=config')
}

function requireGitLabConfig(req: Request, res: Response, next: NextFunction): void {
  if (process.env.GITLAB_CLIENT_ID && process.env.GITLAB_CLIENT_SECRET) next()
  else redirectToFrontend(req, res, '?auth_error=config')
}

function requireGoogleConfig(req: Request, res: Response, next: NextFunction): void {
  if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) next()
  else redirectToFrontend(req, res, '?auth_error=config')
}

router.get('/github', requireGitHubConfig, (req, res, next) => {
  const rt = sanitizeReturnTo(req.query.returnTo)
  const state = encodeOAuthReturnState(rt)
  passport.authenticate('github', { scope: ['user:email'], state })(req, res, next)
})

router.get(
  '/github/callback',
  requireGitHubConfig,
  (req, res, next) => {
    passport.authenticate('github', (err: Error | null, user?: Express.User, info?: { message?: string }) => {
      if (err) {
        console.error('[auth/github] Strategy error:', err?.message || err)
        const msg = sanitizeErrorMessage(err)
        redirectToFrontend(req, res, loginErrorParams('strategy_error', msg || 'GitHub authentication failed.'))
        return
      }
      if (!user) {
        console.error('[auth/github] No user returned (info):', info?.message || info)
        redirectToFrontend(req, res, loginErrorParams('no_user', (info?.message as string) || 'No user from GitHub.'))
        return
      }
      req.login(user, (loginErr?: Error) => {
        if (loginErr) {
          console.error('[auth/github] Session login error:', loginErr?.message || loginErr)
          const msg = sanitizeErrorMessage(loginErr)
          redirectToFrontend(req, res, loginErrorParams('session_error', msg || 'Session could not be saved.'))
          return
        }
        const returnPath = decodeOAuthReturnState(req.query.state) ?? ''
        redirectToFrontend(req, res, returnPath)
      })
    })(req, res, next)
  }
)

router.get('/google', requireGoogleConfig, (req, res, next) => {
  const rt = sanitizeReturnTo(req.query.returnTo)
  const state = encodeOAuthReturnState(rt)
  passport.authenticate('google', { scope: ['profile', 'email'], state })(req, res, next)
})

router.get(
  '/google/callback',
  requireGoogleConfig,
  (req, res, next) => {
    passport.authenticate('google', (err: Error | null, user?: Express.User, info?: { message?: string }) => {
      if (err) {
        console.error('[auth/google] Strategy error:', err?.message || err)
        const msg = sanitizeErrorMessage(err)
        redirectToFrontend(req, res, loginErrorParams('strategy_error', msg || 'Google authentication failed.'))
        return
      }
      if (!user) {
        console.error('[auth/google] No user returned (info):', info?.message || info)
        redirectToFrontend(req, res, loginErrorParams('no_user', (info?.message as string) || 'No user from Google.'))
        return
      }
      req.login(user, (loginErr?: Error) => {
        if (loginErr) {
          console.error('[auth/google] Session login error:', loginErr?.message || loginErr)
          const msg = sanitizeErrorMessage(loginErr)
          redirectToFrontend(req, res, loginErrorParams('session_error', msg || 'Session could not be saved.'))
          return
        }
        const returnPath = decodeOAuthReturnState(req.query.state) ?? ''
        redirectToFrontend(req, res, returnPath)
      })
    })(req, res, next)
  }
)

router.get('/gitlab', requireGitLabConfig, (req, res, next) => {
  const rt = sanitizeReturnTo(req.query.returnTo)
  const state = encodeOAuthReturnState(rt)
  passport.authenticate('gitlab', { scope: 'read_user', state })(req, res, next)
})

router.get(
  '/gitlab/callback',
  requireGitLabConfig,
  (req, res, next) => {
    passport.authenticate('gitlab', (err: Error | null, user?: Express.User, info?: { message?: string }) => {
      if (err) {
        console.error('[auth/gitlab] Strategy error:', err?.message || err)
        const msg = sanitizeErrorMessage(err)
        redirectToFrontend(req, res, loginErrorParams('strategy_error', msg || 'GitLab authentication failed.'))
        return
      }
      if (!user) {
        console.error('[auth/gitlab] No user returned (info):', info?.message || info)
        redirectToFrontend(req, res, loginErrorParams('no_user', (info?.message as string) || 'No user from GitLab.'))
        return
      }
      req.login(user, (loginErr?: Error) => {
        if (loginErr) {
          console.error('[auth/gitlab] Session login error:', loginErr?.message || loginErr)
          const msg = sanitizeErrorMessage(loginErr)
          redirectToFrontend(req, res, loginErrorParams('session_error', msg || 'Session could not be saved.'))
          return
        }
        const returnPath = decodeOAuthReturnState(req.query.state) ?? ''
        redirectToFrontend(req, res, returnPath)
      })
    })(req, res, next)
  }
)

function mergeError(res: Response, err: unknown): void {
  if (err instanceof AccountMergeError) {
    res.status(err.statusCode).json({ error: err.message })
    return
  }
  const msg = err instanceof Error ? err.message : String(err)
  console.error('[auth/merge]', msg)
  res.status(500).json({ error: 'Could not complete merge operation' })
}

router.post('/merge/initiate', requireAuth, (req: Request, res: Response) => {
  const uid = req.user?.id
  if (uid == null) {
    res.status(401).json({ error: 'Authentication required' })
    return
  }
  void (async () => {
    try {
      const out = await accountMergeService.initiateMerge(Number(uid), req.body ?? {})
      res.json(out)
    } catch (err) {
      mergeError(res, err)
    }
  })()
})

router.get('/merge/preview', requireAuth, (req: Request, res: Response) => {
  const uid = req.user?.id
  if (uid == null) {
    res.status(401).json({ error: 'Authentication required' })
    return
  }
  const token = typeof req.query.token === 'string' ? req.query.token : ''
  const id = typeof req.query.id === 'string' ? req.query.id : ''
  void (async () => {
    try {
      const data = await accountMergeService.previewMerge(Number(uid), token, id)
      res.json(data)
    } catch (err) {
      mergeError(res, err)
    }
  })()
})

router.post('/merge/confirm', requireAuth, (req: Request, res: Response) => {
  const uid = req.user?.id
  if (uid == null) {
    res.status(401).json({ error: 'Authentication required' })
    return
  }
  const token = typeof req.body?.token === 'string' ? req.body.token : ''
  const id = typeof req.body?.id === 'string' ? req.body.id : ''
  void (async () => {
    try {
      const out = await accountMergeService.confirmMerge(Number(uid), token, id, req)
      res.json(out)
    } catch (err) {
      mergeError(res, err)
    }
  })()
})

router.post('/merge/cancel', requireAuth, (req: Request, res: Response) => {
  const uid = req.user?.id
  if (uid == null) {
    res.status(401).json({ error: 'Authentication required' })
    return
  }
  const id = typeof req.body?.id === 'string' ? req.body.id : ''
  void (async () => {
    try {
      await accountMergeService.cancelMerge(Number(uid), id)
      res.json({ ok: true })
    } catch (err) {
      mergeError(res, err)
    }
  })()
})

router.post('/logout', (req, res, next) => {
  req.logout((err) => {
    if (err) next(err)
    else res.json({ ok: true })
  })
})

export default router
