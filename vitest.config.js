import { defineConfig } from 'vitest/config'

/**
 * Vitest config for backend (Node) API tests.
 * Run with: npm test (watch) or npm run test:run (single run).
 */
export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.js'],
    globals: false,
    env: { NODE_ENV: 'test' },
  },
})
