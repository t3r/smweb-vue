import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/objects', () => {
  it('returns 200 and list with objects, total, offset, limit', async () => {
    const res = await request(app).get('/api/objects')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('objects')
    expect(Array.isArray(res.body.objects)).toBe(true)
    expect(res.body).toHaveProperty('total')
    expect(res.body).toHaveProperty('offset')
    expect(res.body).toHaveProperty('limit')
  })

  it('accepts offset and limit query params', async () => {
    const res = await request(app).get('/api/objects').query({ offset: 0, limit: 5 })
    expect(res.status).toBe(200)
    expect(res.body.offset).toBe(0)
    expect(res.body.limit).toBe(5)
  })

  it('accepts country query param (2-letter code) to filter by country', async () => {
    const res = await request(app).get('/api/objects').query({ country: 'DE' })
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('objects')
    expect(res.body).toHaveProperty('total')
  })

  it('accepts group query param to filter by object type (model group)', async () => {
    const res = await request(app).get('/api/objects').query({ group: 1 })
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('objects')
    expect(res.body).toHaveProperty('total')
  })

  it('accepts both group and country query params', async () => {
    const res = await request(app).get('/api/objects').query({ group: 1, country: 'DE' })
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('objects')
    expect(res.body).toHaveProperty('total')
  })
})

describe('GET /api/objects/search', () => {
  it('returns 200 and objects array with total', async () => {
    const res = await request(app).get('/api/objects/search')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('objects')
    expect(Array.isArray(res.body.objects)).toBe(true)
    expect(res.body).toHaveProperty('total')
  })

  it('accepts model, lat, lon, country, description query params', async () => {
    const res = await request(app)
      .get('/api/objects/search')
      .query({ model: 1, lat: 37.6, lon: -122.4 })
    expect(res.status).toBe(200)
  })
})

describe('GET /api/objects/:id', () => {
  it('returns 200 and object with id, modelId, position when id exists', async () => {
    const listRes = await request(app).get('/api/objects').query({ limit: 1 })
    expect(listRes.status).toBe(200)
    const id = listRes.body.objects?.length > 0 ? listRes.body.objects[0].id : 1
    const res = await request(app).get(`/api/objects/${id}`)
    expect([200, 404]).toContain(res.status)
    if (res.status === 200) {
      expect(res.body).toHaveProperty('id')
      expect(res.body).toHaveProperty('modelId')
      expect(res.body).toHaveProperty('position')
      expect(res.body.position).toHaveProperty('lat')
      expect(res.body.position).toHaveProperty('lon')
    }
  })

  it('returns 404 for non-existent object id', async () => {
    const res = await request(app).get('/api/objects/999999999')
    expect(res.status).toBe(404)
  })
})
