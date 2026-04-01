import { createRequire } from 'node:module'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitest/config'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
/** Resolve like the root package.json (where devDependencies live), not like lambda/.../handler.mjs */
const rootRequire = createRequire(path.join(__dirname, 'package.json'))

const LAMBDA_HANDLER_DEPS = ['@aws-sdk/client-ses', 'handlebars']

/**
 * handler.mjs lives under lambda/email-queue-worker/src/. Without this, vite-node often keeps these
 * imports "external" and Node resolves them from that directory — no node_modules on CI after root-only
 * npm ci — ERR_MODULE_NOT_FOUND. Pin them to the repo root install instead.
 */
function resolveLambdaHandlerDepsFromRoot() {
  const idSet = new Set(LAMBDA_HANDLER_DEPS)
  return {
    name: 'vitest-resolve-lambda-deps-from-root',
    enforce: 'pre',
    resolveId(source) {
      if (!idSet.has(source)) return null
      try {
        return rootRequire.resolve(source)
      } catch {
        return null
      }
    },
  }
}

/**
 * Vitest config for backend (Node) API tests.
 * Run with: npm test (watch) or npm run test:run (single run).
 */
export default defineConfig({
  plugins: [resolveLambdaHandlerDepsFromRoot()],
  ssr: {
    // Process these through Vite so the plugin + root resolution apply; otherwise they stay external
    // and Node walks from lambda/.../src and fails without lambda/node_modules.
    noExternal: LAMBDA_HANDLER_DEPS,
  },
  test: {
    environment: 'node',
    include: ['tests/**/*.test.js'],
    globals: false,
    env: { NODE_ENV: 'test' },
  },
})
