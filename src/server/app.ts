import path from 'node:path'
import fs from 'node:fs'
import { fileURLToPath } from 'node:url'
import express from 'express'
import cors from 'cors'
import helmet, { contentSecurityPolicy } from 'helmet'
import morgan from 'morgan'
import dotenv from 'dotenv'
import swaggerUi from 'swagger-ui-express'
import swaggerSpec from './config/swagger.js'
import apiRoutes from './routes/index.js'
import authRoutes from './routes/auth.js'
import { sessionMiddleware } from './config/session.js'
import passport from './config/passport.js'
import { sequelize } from './config/database.js'
import { perIpLimiter, perSessionLimiter } from './middleware/rateLimit.js'
import { CLIENT_ERROR_MESSAGE } from './utils/dbFallback.js'
import { getClientBuildId } from './utils/clientBuildId.js'
import { startOurAirportsSyncScheduler } from './services/ourAirportsSync.js'
import { apiDocsBasicAuth } from './middleware/apiDocsBasicAuth.js'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000
const LISTEN_HOST = process.env.IP?.trim() || '::'

// TRUST_PROXY=1: use X-Forwarded-For / X-Real-IP for req.ip (reverse proxy, API Gateway, …).
if (process.env.TRUST_PROXY === '1' || process.env.TRUST_PROXY === 'true') {
  app.set('trust proxy', 1)
}

const isProduction = process.env.NODE_ENV === 'production'
const rawOrigin = process.env.FRONTEND_URL || process.env.CLIENT_URL || 'http://localhost:5173'

function getFrontendOrigin(): string {
  if (!isProduction) {
    return rawOrigin
  }
  const origin = (rawOrigin || '').trim()
  if (!origin || origin === '*') {
    throw new Error(
      'In production, FRONTEND_URL or CLIENT_URL must be set to the exact frontend origin (e.g. https://scenemodels.example.org). ' +
      'Do not use * or leave it empty.'
    )
  }
  try {
    const u = new URL(origin)
    if (!['http:', 'https:'].includes(u.protocol)) {
      throw new Error('Origin must use http or https')
    }
    return u.origin
  } catch (e) {
    throw new Error(
      `Invalid FRONTEND_URL/CLIENT_URL: ${origin}. Use a full origin URL (e.g. https://example.org).`
    )
  }
}

const FRONTEND_ORIGIN = getFrontendOrigin()

const mapTileSources = [
  'https://tile.openstreetmap.org',
  'https://demotiles.maplibre.org',
] as const

app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        ...contentSecurityPolicy.getDefaultDirectives(),
        'connect-src': ["'self'", ...mapTileSources],
        'img-src': ["'self'", 'data:', 'blob:', ...mapTileSources],
        'worker-src': ["'self'", 'blob:'],
      },
    },
    // Helmet default is no-referrer; OSM tile policy requires a Referer on web tile requests.
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
)
app.use(cors({ origin: FRONTEND_ORIGIN, credentials: true }))
app.use(morgan('combined'))
app.use(express.json())
app.use(express.urlencoded({ extended: true }))
app.use(sessionMiddleware)
app.use(passport.initialize())
app.use(passport.session())

app.use(perIpLimiter)
app.use(perSessionLimiter)

/** Common scanner path; never serve the SPA here. */
app.all('/app.php', (_req, res) => {
  res.status(404).json({ error: 'Not found' })
})

app.use('/api-docs', apiDocsBasicAuth, swaggerUi.serve, swaggerUi.setup(swaggerSpec))

app.get('/api/health', async (_req, res) => {
  try {
    await sequelize.authenticate()
    res.json({ status: 'OK', message: 'FlightGear Scenemodels API', database: 'reachable' })
  } catch {
    res.status(503).json({
      status: 'ERROR',
      message: 'Database unreachable',
      database: 'unreachable',
      error: CLIENT_ERROR_MESSAGE,
    })
  }
})

/** Public: current server build id (git/VERSION/env) for SPA stale-client detection. */
app.get('/api/client-build', (_req, res) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate')
  res.json({ buildId: getClientBuildId() })
})

app.use('/api', apiRoutes)
app.use('/api/auth', authRoutes)

/** Any remaining path under `/api` was not handled by a router (unknown API route). */
app.use('/api', (_req, res) => {
  res.status(404).json({ error: 'Not found' })
})

/** Vite `outDir`: dist/public (sibling of dist/server). */
function getClientDistPath(): string | null {
  const override = process.env.CLIENT_DIST_PATH?.trim()
  if (override) return path.isAbsolute(override) ? override : path.resolve(process.cwd(), override)
  return path.resolve(__dirname, '../public')
}

if (isProduction) {
  const clientDist = getClientDistPath()
  const indexHtml = clientDist ? path.join(clientDist, 'index.html') : ''
  if (clientDist && fs.existsSync(indexHtml)) {
    app.use(
      express.static(clientDist, {
        index: false,
        maxAge: '1d',
        immutable: false,
      })
    )
    /** Hosts that serve the built SPA from this process (typical behind a reverse proxy). */
    app.use((req, res, next) => {
      if (req.method !== 'GET' && req.method !== 'HEAD') {
        next()
        return
      }
      const p = req.path || ''
      if (p.startsWith('/api') || p.startsWith('/api-docs') || p === '/app.php') {
        next()
        return
      }
      res.sendFile(indexHtml, (err) => {
        if (err) next(err)
      })
    })
  } else {
    console.warn(
      '[app] Production mode: no SPA found at',
      indexHtml || clientDist,
      '(set CLIENT_DIST_PATH or run vite build with outDir dist/public)'
    )
  }
}

/** Unmatched routes (e.g. POST to a non-existent path, or no SPA bundle in production). */
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' })
})

const isMainModule = process.argv[1]?.endsWith('app.js') || process.argv[1]?.endsWith('app.ts')
if (isMainModule) {
  const port = Number(PORT)
  const listenPort = Number.isFinite(port) && port >= 0 ? port : 3000
  app.listen(listenPort, LISTEN_HOST, () => {
    const hostForUrl = LISTEN_HOST.includes(':') ? `[${LISTEN_HOST}]` : LISTEN_HOST
    console.log(`Server listening on http://${hostForUrl}:${listenPort}`)
    console.log(`API docs: http://${hostForUrl}:${listenPort}/api-docs`)
    startOurAirportsSyncScheduler()
  })
}

export { app }
