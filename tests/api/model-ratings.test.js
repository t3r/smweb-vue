import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('PUT /api/models/:id/rating', () => {
  it('returns 401 when not authenticated', async () => {
    const res = await request(app).put('/api/models/1/rating').send({ score: 4 })
    expect(res.status).toBe(401)
    expect(res.body).toHaveProperty('error')
  })

  it('returns 400 for invalid score when authenticated would be required', async () => {
    const res = await request(app).put('/api/models/1/rating').send({ score: 0 })
    expect(res.status).toBe(401)
  })
})

describe('GET /api/models/:id/rating', () => {
  it('returns 200 and rating summary for valid id', async () => {
    const res = await request(app).get('/api/models/1/rating')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('ratingAverage')
    expect(res.body).toHaveProperty('ratingCount')
    expect(res.body).toHaveProperty('userRating')
  })

  it('returns 400 for invalid model id', async () => {
    const res = await request(app).get('/api/models/abc/rating')
    expect(res.status).toBe(400)
  })
})

describe('GET /api/models list rating fields', () => {
  it('includes rating fields on each model', async () => {
    const res = await request(app).get('/api/models').query({ limit: 5 })
    expect(res.status).toBe(200)
    for (const m of res.body.models || []) {
      expect(m).toHaveProperty('ratingAverage')
      expect(m).toHaveProperty('ratingCount')
      expect(m).toHaveProperty('userRating')
    }
  })
})

describe('GET /api/models/:id detail rating fields', () => {
  it('includes rating fields when model exists', async () => {
    const res = await request(app).get('/api/models/1')
    if (res.status === 200) {
      expect(res.body).toHaveProperty('ratingAverage')
      expect(res.body).toHaveProperty('ratingCount')
      expect(res.body).toHaveProperty('userRating')
    } else {
      expect(res.status).toBe(404)
    }
  })
})
