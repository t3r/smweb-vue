import session from 'express-session'
import type { RequestHandler } from 'express'
import type { Store } from 'express-session'
import pg from 'pg'
import connectPgSimple from 'connect-pg-simple'

const DEFAULT_SECRET = 'change-me-in-production'
const MIN_SECRET_LENGTH = 32
const isProduction = process.env.NODE_ENV === 'production'

const SESSION_SECRET = process.env.SESSION_SECRET ?? DEFAULT_SECRET

if (isProduction) {
  if (SESSION_SECRET === DEFAULT_SECRET || SESSION_SECRET.length < MIN_SECRET_LENGTH) {
    throw new Error(
      `In production, SESSION_SECRET must be set and at least ${MIN_SECRET_LENGTH} characters. ` +
        'Set SESSION_SECRET in the environment (e.g. a random string from openssl rand -base64 32).'
    )
  }
}

/** `user_sessions`: sid, sess, expire (see sql/scenemodels-schema.sql). */
const SESSION_TABLE = 'user_sessions'

function useMemorySessionStore(): boolean {
  if (process.env.SESSION_STORE === 'memory') return true
  if (process.env.SESSION_STORE === 'pg') return false
  // Test without real DB: skip PG pool
  if (process.env.NODE_ENV === 'test' && process.env.TEST_USE_REAL_DB !== '1') return true
  return false
}

function createPgSessionStore(): Store {
  const PgSession = connectPgSimple(session)
  const {
    DB_HOST = 'localhost',
    DB_PORT = '5432',
    DB_NAME = 'scenemodels',
    DB_USER = 'postgres',
    DB_PASSWORD = 'postgres',
    DATABASE_URL,
  } = process.env

  const pool = DATABASE_URL
    ? new pg.Pool({ connectionString: DATABASE_URL })
    : new pg.Pool({
        host: DB_HOST,
        port: Number(DB_PORT),
        database: DB_NAME,
        user: DB_USER,
        password: DB_PASSWORD,
      })

  return new PgSession({
    pool,
    tableName: SESSION_TABLE,
    createTableIfMissing: false,
    ttl: 7 * 24 * 60 * 60, // seconds; align with cookie maxAge below
  })
}

const sessionStore: Store | undefined = useMemorySessionStore() ? undefined : createPgSessionStore()

const sessionConfig: Parameters<typeof session>[0] = {
  secret: SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  name: 'flightgear.sid',
  cookie: {
    secure: isProduction && process.env.COOKIE_SECURE !== '0',
    httpOnly: true,
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    // lax: OAuth callback is a top-level GET from the IdP; strict often drops the session cookie there,
    // so pre-login session data was invisible on callback (return URL lived only in session before).
    sameSite: 'lax',
  },
  ...(sessionStore ? { store: sessionStore } : {}),
}

export const sessionMiddleware: RequestHandler = session(sessionConfig)
