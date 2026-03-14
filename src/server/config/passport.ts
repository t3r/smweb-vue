import passport from 'passport'
import GitHubStrategy from 'passport-github2'
import GitLabStrategy from 'passport-gitlab2'
import { findOrCreateUser, AUTH_PROVIDER_GITHUB, AUTH_PROVIDER_GITLAB } from '../services/authService.js'

const GITHUB_CLIENT_ID = process.env.GITHUB_CLIENT_ID
const GITHUB_CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET
const GITLAB_CLIENT_ID = process.env.GITLAB_CLIENT_ID
const GITLAB_CLIENT_SECRET = process.env.GITLAB_CLIENT_SECRET
const GITLAB_BASE_URL = process.env.GITLAB_BASE_URL || 'https://gitlab.com'

function buildCallbackUrl(provider: string): string {
  const base = process.env.API_BASE_URL || process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`
  return `${base.replace(/\/$/, '')}/api/auth/${provider}/callback`
}

if (GITHUB_CLIENT_ID && GITHUB_CLIENT_SECRET) {
  passport.use(
    new GitHubStrategy(
      {
        clientID: GITHUB_CLIENT_ID,
        clientSecret: GITHUB_CLIENT_SECRET,
        callbackURL: buildCallbackUrl('github'),
        scope: ['user:email'],
      },
      async (
        _accessToken: string,
        _refreshToken: string,
        profile: { id: string; displayName?: string; username?: string; emails?: { value: string }[]; _json?: { name?: string; email?: string } },
        done: (err: Error | null, user?: Express.User) => void
      ) => {
        try {
          const externalId = String(profile.id)
          const displayName = profile.displayName || profile.username || profile._json?.name || ''
          const email = profile.emails?.[0]?.value || profile._json?.email || ''
          const user = await findOrCreateUser(AUTH_PROVIDER_GITHUB, externalId, displayName, email)
          done(null, user)
        } catch (err) {
          console.error('[passport/github] findOrCreateUser error:', (err as Error)?.message || err)
          if ((err as Error)?.stack) console.error((err as Error).stack)
          done(err as Error)
        }
      }
    )
  )
}

if (GITLAB_CLIENT_ID && GITLAB_CLIENT_SECRET) {
  passport.use(
    new GitLabStrategy(
      {
        clientID: GITLAB_CLIENT_ID,
        clientSecret: GITLAB_CLIENT_SECRET,
        callbackURL: buildCallbackUrl('gitlab'),
        baseURL: GITLAB_BASE_URL,
        scope: ['read_user'],
        scopeSeparator: ' ', // GitLab expects space-separated scopes (RFC 6749)
      },
      async (
        _accessToken: string,
        _refreshToken: string,
        profile: { id: string; displayName?: string; username?: string; emails?: { value: string }[]; _json?: { name?: string; email?: string } },
        done: (err: Error | null, user?: Express.User) => void
      ) => {
        try {
          const externalId = String(profile.id)
          const displayName = profile.displayName || profile.username || profile._json?.name || ''
          const email = profile.emails?.[0]?.value || profile._json?.email || ''
          const user = await findOrCreateUser(AUTH_PROVIDER_GITLAB, externalId, displayName, email)
          done(null, user)
        } catch (err) {
          console.error('[passport/gitlab] findOrCreateUser error:', (err as Error)?.message || err)
          if ((err as Error)?.stack) console.error((err as Error).stack)
          done(err as Error)
        }
      }
    )
  )
}

passport.serializeUser((user, done) => {
  done(null, user)
})

passport.deserializeUser((user, done) => {
  done(null, user as Express.User)
})

export default passport
