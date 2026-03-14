/**
 * Test helper: provides the Express app for supertest without starting the server.
 * - Default: loads mocks first (no real DB). Set TEST_USE_REAL_DB=1 to use .env DB.
 */
async function loadApp() {
  if (!process.env.TEST_USE_REAL_DB) {
    await import('./mocks.js')
  }
  const { app } = await import('../../src/server/app.ts')
  return app
}

export const appPromise = loadApp()
