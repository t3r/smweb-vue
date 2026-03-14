import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/health', () => {
  it('returns 200 when DB is reachable, or 503 when not (e.g. CI without Postgres)', async () => {
    const res = await request(app).get('/api/health')
    if (res.status === 200) {
      expect(res.body).toMatchObject({
        status: 'OK',
        message: 'FlightGear Scenemodels API',
        database: 'reachable',
      })
    } else {
      expect(res.status).toBe(503)
      expect(res.body).toMatchObject({
        status: 'ERROR',
        message: 'Database unreachable',
        database: 'unreachable',
      })
    }
  })
})
