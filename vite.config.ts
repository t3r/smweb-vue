import { readFileSync, existsSync } from 'node:fs'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import dotenv from 'dotenv'
import { resolveGitSlug } from './scripts/resolve-git-slug.mjs'
import { isKnownClientHistoryPath } from './src/client/router/isKnownClientHistoryPath'

const projectRoot = dirname(fileURLToPath(import.meta.url))

// Align embed with server `getClientBuildId()`: Express loads `.env` before resolving slug; Vite must too
// or `VITE_APP_GIT_SLUG` / `GIT_SLUG` in .env would mismatch `__FGS_GIT_SLUG__` and trigger a false "update" dialog.
const envPath = resolve(projectRoot, '.env')
if (existsSync(envPath)) {
  dotenv.config({ path: envPath })
}
const envLocalPath = resolve(projectRoot, '.env.local')
if (existsSync(envLocalPath)) {
  dotenv.config({ path: envLocalPath, override: true })
}

const pkg = JSON.parse(readFileSync(resolve(projectRoot, 'package.json'), 'utf8'))

/** HTTPS origin for GitHub (or other) repo page; used for /commit/&lt;sha&gt; links in the footer. */
function repoWebUrl(repository: { url?: string } | string | undefined): string {
  let u = repository && typeof repository === 'object' ? repository.url : ''
  if (typeof u !== 'string') u = ''
  u = u.replace(/^git\+/i, '').replace(/\.git$/i, '')
  if (u.startsWith('git@github.com:')) {
    u = `https://github.com/${u.slice('git@github.com:'.length)}`
  }
  return u || 'https://github.com/t3r/smweb-vue'
}

const appGitSlug = resolveGitSlug()
const appRepoWebUrl = repoWebUrl(pkg.repository)

/** In dev, avoid SPA fallback for paths that are not real app routes (aligns with Express 404 behavior). */
function devStrictHtmlFallback() {
  return {
    name: 'dev-strict-html-fallback',
    enforce: 'pre' as const,
    configureServer(server: import('vite').ViteDevServer) {
      server.middlewares.use((req, res, next) => {
        if (req.method !== 'GET' && req.method !== 'HEAD') {
          next()
          return
        }
        const raw = req.url
        if (raw == null) {
          next()
          return
        }
        const pathname = raw.split('?')[0] || '/'

        if (pathname.startsWith('/api')) {
          next()
          return
        }
        if (
          pathname.startsWith('/@') ||
          pathname.startsWith('/node_modules') ||
          pathname.startsWith('/src') ||
          pathname.startsWith('/.well-known')
        ) {
          next()
          return
        }
        if (pathname.startsWith('/__')) {
          next()
          return
        }
        if (/\.[a-zA-Z0-9]+$/.test(pathname)) {
          next()
          return
        }

        if (isKnownClientHistoryPath(pathname)) {
          next()
          return
        }

        res.statusCode = 404
        res.setHeader('Content-Type', 'application/json; charset=utf-8')
        res.end(JSON.stringify({ error: 'Not found' }))
      })
    },
  }
}

export default defineConfig({
  define: {
    __FGS_GIT_SLUG__: JSON.stringify(appGitSlug),
    __FGS_REPO_WEB_URL__: JSON.stringify(appRepoWebUrl),
  },
  plugins: [vue(), devStrictHtmlFallback()],
  root: 'src/client',
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
  build: {
    // SPA only; tsc writes dist/server (avoid emptyOutDir wiping it).
    outDir: '../../dist/public',
    emptyOutDir: true,
  },
  resolve: {
    alias: {
      '@': resolve(projectRoot, 'src/client'),
      '@shared': resolve(projectRoot, 'src/shared'),
    },
  },
})
