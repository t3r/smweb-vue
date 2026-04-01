import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/client-build', () => {
  it('returns 200 JSON with buildId and no-store caching', async () => {
    const res = await request(app).get('/api/client-build')
    expect(res.status).toBe(200)
    expect(res.headers['cache-control']).toMatch(/no-store/i)
    expect(typeof res.body.buildId).toBe('string')
    expect(res.body.buildId.length).toBeGreaterThan(0)
  })
})
