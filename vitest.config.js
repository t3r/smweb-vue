import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitest/config'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

/**
 * Vitest config for backend (Node) API tests.
 * Run with: npm test (watch) or npm run test:run (single run).
 */
export default defineConfig({
  resolve: {
    alias: {
      // Lambda lives in a subfolder with its own node_modules; without this, vi.mock('@aws-sdk/client-ses')
      // can target a different module instance than handler.mjs loads, so SES sends hit real credentials.
      '@aws-sdk/client-ses': path.resolve(
        __dirname,
        'lambda/email-queue-worker/node_modules/@aws-sdk/client-ses',
      ),
    },
  },
  test: {
    environment: 'node',
    include: ['tests/**/*.test.js'],
    globals: false,
    env: { NODE_ENV: 'test' },
  },
})
