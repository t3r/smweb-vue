import { Router, type Request, type Response, type NextFunction } from 'express'
import passport from '../config/passport.js'

const router = Router()
const FRONTEND_URL = process.env.FRONTEND_URL || process.env.CLIENT_URL || 'http://localhost:5173'

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

router.get('/github', requireGitHubConfig, (req, res, next) => {
  passport.authenticate('github', { scope: ['user:email'] })(req, res, next)
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
        redirectToFrontend(req, res, '')
      })
    })(req, res, next)
  }
)

router.get('/gitlab', requireGitLabConfig, (req, res, next) => {
  passport.authenticate('gitlab', { scope: 'read_user' })(req, res, next)
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
        redirectToFrontend(req, res, '')
      })
    })(req, res, next)
  }
)

router.post('/logout', (req, res, next) => {
  req.logout((err) => {
    if (err) next(err)
    else res.json({ ok: true })
  })
})

export default router
