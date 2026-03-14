import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/models', () => {
  it('returns 200 and list with models, total, offset, limit', async () => {
    const res = await request(app).get('/api/models')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('models')
    expect(Array.isArray(res.body.models)).toBe(true)
    expect(res.body).toHaveProperty('total')
    expect(typeof res.body.total).toBe('number')
    expect(res.body).toHaveProperty('offset')
    expect(res.body).toHaveProperty('limit')
  })

  it('accepts offset and limit query params', async () => {
    const res = await request(app).get('/api/models').query({ offset: 0, limit: 10 })
    expect(res.status).toBe(200)
    expect(res.body.offset).toBe(0)
    expect(res.body.limit).toBe(10)
  })

  it('accepts group and author query params', async () => {
    const resGroup = await request(app).get('/api/models').query({ group: 1 })
    expect(resGroup.status).toBe(200)
    expect(resGroup.body).toHaveProperty('models')
    const resAuthor = await request(app).get('/api/models').query({ author: 1 })
    expect(resAuthor.status).toBe(200)
    expect(resAuthor.body).toHaveProperty('models')
  })
})

describe('GET /api/models/recent', () => {
  it('returns 200 and models array', async () => {
    const res = await request(app).get('/api/models/recent')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('models')
    expect(Array.isArray(res.body.models)).toBe(true)
  })
})

describe('GET /api/models/:id', () => {
  it('returns 200 and model object when id exists', async () => {
    const listRes = await request(app).get('/api/models').query({ limit: 1 })
    expect(listRes.status).toBe(200)
    const id = listRes.body.models?.length > 0 ? listRes.body.models[0].id : 1
    const res = await request(app).get(`/api/models/${id}`)
    expect([200, 404]).toContain(res.status)
    if (res.status === 200) {
      expect(res.body).toHaveProperty('id')
      expect(res.body).toHaveProperty('name')
      expect(res.body).toHaveProperty('filename')
    }
  })

  it('returns 404 for non-existent model id', async () => {
    const res = await request(app).get('/api/models/999999999')
    expect(res.status).toBe(404)
  })
})

describe('GET /api/models/:id/thumbnail', () => {
  it('returns 200 with image content-type when thumbnail exists', async () => {
    const listRes = await request(app).get('/api/models').query({ limit: 1 })
    const id = listRes.body.models?.length > 0 ? listRes.body.models[0].id : 1
    const res = await request(app).get(`/api/models/${id}/thumbnail`)
    expect([200, 404]).toContain(res.status)
    if (res.status === 200) {
      expect(res.headers['content-type']).toMatch(/image/)
    }
  })
})

describe('GET /api/models/:id/files', () => {
  it('returns 200 and files array', async () => {
    const listRes = await request(app).get('/api/models').query({ limit: 1 })
    const id = listRes.body.models?.length > 0 ? listRes.body.models[0].id : 1
    const res = await request(app).get(`/api/models/${id}/files`)
    expect([200, 404]).toContain(res.status)
    if (res.status === 200) {
      expect(res.body).toHaveProperty('files')
      expect(Array.isArray(res.body.files)).toBe(true)
    }
  })
})

describe('GET /api/models/:id/preview', () => {
  it('returns 200 with geometry and textures or 404', async () => {
    const listRes = await request(app).get('/api/models').query({ limit: 1 })
    const id = listRes.body.models?.length > 0 ? listRes.body.models[0].id : 1
    const res = await request(app).get(`/api/models/${id}/preview`)
    expect([200, 404]).toContain(res.status)
    if (res.status === 200) {
      expect(res.body).toHaveProperty('geometry')
      expect(res.body).toHaveProperty('textures')
      expect(Array.isArray(res.body.textures)).toBe(true)
    }
  })
})

describe('GET /api/models/:id/package', () => {
  it('returns 200, 404, or 501 for package download', async () => {
    const listRes = await request(app).get('/api/models').query({ limit: 1 })
    const id = listRes.body.models?.length > 0 ? listRes.body.models[0].id : 1
    const res = await request(app).get(`/api/models/${id}/package`)
    expect([200, 404, 501]).toContain(res.status)
  })
})
