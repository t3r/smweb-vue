import passport from 'passport'
import GitHubStrategy from 'passport-github2'
import GitLabStrategy from 'passport-gitlab2'
import { Strategy as GoogleStrategy } from 'passport-google-oauth20'
import type { Profile as GoogleProfile } from 'passport-google-oauth20'
import {
  findOrCreateUser,
  getSessionUserByAuthorId,
  AUTH_PROVIDER_GITHUB,
  AUTH_PROVIDER_GOOGLE,
  AUTH_PROVIDER_GITLAB,
} from '../services/authService.js'

const GITHUB_CLIENT_ID = process.env.GITHUB_CLIENT_ID
const GITHUB_CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET
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

if (GOOGLE_CLIENT_ID && GOOGLE_CLIENT_SECRET) {
  passport.use(
    new GoogleStrategy(
      {
        clientID: GOOGLE_CLIENT_ID,
        clientSecret: GOOGLE_CLIENT_SECRET,
        callbackURL: buildCallbackUrl('google'),
        scope: ['profile', 'email'],
      },
      async (
        _accessToken: string,
        _refreshToken: string,
        profile: GoogleProfile,
        done: (err: Error | null, user?: Express.User) => void
      ) => {
        try {
          const externalId = String(profile.id)
          const displayName =
            profile.displayName ||
            [profile.name?.givenName, profile.name?.familyName].filter(Boolean).join(' ').trim() ||
            ''
          const email = profile.emails?.[0]?.value || profile._json?.email || ''
          const user = await findOrCreateUser(AUTH_PROVIDER_GOOGLE, externalId, displayName, email)
          done(null, user)
        } catch (err) {
          console.error('[passport/google] findOrCreateUser error:', (err as Error)?.message || err)
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
  const id = (user as { id: number }).id
  done(null, id)
})

function deserializePayloadToAuthorId(payload: unknown): number | null {
  if (typeof payload === 'number' && Number.isInteger(payload) && payload >= 1) return payload
  if (payload && typeof payload === 'object' && 'id' in payload) {
    const id = Number((payload as { id: unknown }).id)
    if (Number.isInteger(id) && id >= 1) return id
  }
  return null
}

passport.deserializeUser((payload: unknown, done) => {
  void (async () => {
    try {
      const authorId = deserializePayloadToAuthorId(payload)
      if (authorId == null) {
        done(null, false)
        return
      }
      const user = await getSessionUserByAuthorId(authorId)
      if (!user) {
        done(null, false)
        return
      }
      done(null, user as Express.User)
    } catch (err) {
      done(err as Error)
    }
  })()
})

export default passport
