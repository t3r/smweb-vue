import { describe, it, expect, beforeAll } from 'vitest'
import '../helpers/mocks.js'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app

beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/position-requests', () => {
  it('returns 401 when not authenticated', async () => {
    const res = await request(app).get('/api/position-requests')
    expect(res.status).toBe(401)
    expect(res.body).toMatchObject({ error: 'Authentication required' })
  })
})

describe('GET /api/position-requests/pending-count', () => {
  it('returns 401 when not authenticated', async () => {
    const res = await request(app).get('/api/position-requests/pending-count')
    expect(res.status).toBe(401)
  })
})
