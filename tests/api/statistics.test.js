import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/statistics', () => {
  it('returns 200 and model/object/author counts shape', async () => {
    const res = await request(app).get('/api/statistics')
    expect(res.status).toBe(200)
    expect(res.body).toMatchObject({
      models: expect.any(Number),
      objects: expect.any(Number),
      authors: expect.any(Number),
    })
  })
})
