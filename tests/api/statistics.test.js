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
      pendingRequests: expect.any(Number),
    })
  })
})

describe('GET /api/statistics/history', () => {
  it('returns 200 and series array of dated points', async () => {
    const res = await request(app).get('/api/statistics/history')
    expect(res.status).toBe(200)
    expect(Array.isArray(res.body.series)).toBe(true)
    expect(res.body.series.length).toBeGreaterThan(0)
    expect(res.body.series[0]).toMatchObject({
      date: expect.any(String),
      models: expect.any(Number),
      objects: expect.any(Number),
      authors: expect.any(Number),
    })
  })
})
