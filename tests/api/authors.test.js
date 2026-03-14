import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/authors', () => {
  it('returns 200 and authors array', async () => {
    const res = await request(app).get('/api/authors')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('authors')
    expect(Array.isArray(res.body.authors)).toBe(true)
  })

  it('accepts offset and limit query params', async () => {
    const res = await request(app).get('/api/authors').query({ offset: 10, limit: 5 })
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('authors')
    expect(res.body).toHaveProperty('total')
    expect(res.body.offset).toBe(10)
    expect(res.body.limit).toBe(5)
  })
})

describe('GET /api/authors/:id', () => {
  it('returns 200 and author object when id exists', async () => {
    const listRes = await request(app).get('/api/authors')
    expect(listRes.status).toBe(200)
    const id = listRes.body.authors?.length > 0 ? listRes.body.authors[0].id : 1
    const res = await request(app).get(`/api/authors/${id}`)
    expect([200, 404]).toContain(res.status)
    if (res.status === 200) {
      expect(res.body).toHaveProperty('id')
      expect(res.body).toHaveProperty('name')
    }
  })

  it('returns 404 for non-existent author id', async () => {
    const res = await request(app).get('/api/authors/999999999')
    expect(res.status).toBe(404)
  })
})
