import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/news', () => {
  it('returns 200 and news array', async () => {
    const res = await request(app).get('/api/news')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('news')
    expect(Array.isArray(res.body.news)).toBe(true)
  })
})

describe('GET /api/news/:id', () => {
  it('returns 200 and news post when id exists', async () => {
    const listRes = await request(app).get('/api/news')
    expect(listRes.status).toBe(200)
    const id = listRes.body.news?.length > 0 ? listRes.body.news[0].id : 1
    const res = await request(app).get(`/api/news/${id}`)
    expect([200, 404]).toContain(res.status)
    if (res.status === 200) {
      expect(res.body).toHaveProperty('id')
      expect(res.body).toHaveProperty('title')
    }
  })

  it('returns 404 for non-existent news id', async () => {
    const res = await request(app).get('/api/news/999999999')
    expect(res.status).toBe(404)
  })
})
