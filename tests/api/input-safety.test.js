/**
 * API tests: hostile query/path inputs should not produce 500s and should use safe defaults or 4xx.
 * Complements unit tests on validateInput.ts.
 */
import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/objects — injection-style query params', () => {
  it('returns 200 for malicious sortField (ignored; not passed to SQL as identifier from user string)', async () => {
    const res = await request(app)
      .get('/api/objects')
      .query({ sortField: "id; DROP TABLE fgs_objects;--", sortOrder: 1 })
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('objects')
  })

  it('returns 200 for non-numeric limit/offset (defaults applied)', async () => {
    const res = await request(app)
      .get('/api/objects')
      .query({ limit: "1' OR '1'='1", offset: '5; DELETE FROM x;--' })
    expect(res.status).toBe(200)
    expect(res.body.limit).toBe(20)
    expect(res.body.offset).toBe(0)
  })

  it('returns 200 when country is not exactly two letters (filter disabled)', async () => {
    const res = await request(app).get('/api/objects').query({ country: "DE' OR 1=1--" })
    expect(res.status).toBe(200)
  })

  it('returns 200 for malicious group/model ids (treated as absent)', async () => {
    const res = await request(app).get('/api/objects').query({ group: "1 OR 1=1", model: 'UNION SELECT' })
    expect(res.status).toBe(200)
  })
})

describe('GET /api/objects/:id — path injection', () => {
  it('returns 400 for non-integer id', async () => {
    const res = await request(app).get("/api/objects/1' OR '1'='1")
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/invalid/i)
  })

  it('returns 400 for float id', async () => {
    const res = await request(app).get('/api/objects/1.5')
    expect(res.status).toBe(400)
  })
})

describe('GET /api/models/:id and file — path / query safety', () => {
  it('returns 400 for non-numeric model id in path', async () => {
    const res = await request(app).get('/api/models/union-select-1')
    expect(res.status).toBe(400)
  })

  it('returns 400 for path traversal in file name query', async () => {
    const res = await request(app).get('/api/models/1/file').query({ name: '../../../etc/passwd' })
    expect(res.status).toBe(400)
  })

  it('returns 400 for empty file name', async () => {
    const res = await request(app).get('/api/models/1/file').query({ name: '' })
    expect(res.status).toBe(400)
  })
})

describe('GET /api/authors — query safety', () => {
  it('returns 200 for invalid sortField string', async () => {
    const res = await request(app).get('/api/authors').query({ sortField: 'name; DROP TABLE fgs_authors;--' })
    expect(res.status).toBe(200)
  })

  it('returns 400 for invalid author id', async () => {
    const res = await request(app).get("/api/authors/abc' OR 1=1--")
    expect(res.status).toBe(400)
  })
})

describe('GET /api/objects/map — bbox', () => {
  it('returns 400 for non-numeric bbox (no SQL)', async () => {
    const res = await request(app).get('/api/objects/map').query({ bbox: "0,0,1,1'; DROP TABLE--" })
    expect(res.status).toBe(400)
  })

  it('returns 400 for wrong arity bbox', async () => {
    const res = await request(app).get('/api/objects/map').query({ bbox: '1,2,3' })
    expect(res.status).toBe(400)
  })
})

describe('GET /api/countries/at — lon/lat', () => {
  it('returns 400 for non-numeric lon/lat', async () => {
    const res = await request(app).get('/api/countries/at').query({ lon: "0; SELECT 1", lat: '10' })
    expect(res.status).toBe(400)
  })
})

describe('GET /api/news — limit/offset coercion', () => {
  it('returns 200 when limit/offset are hostile strings (coerced to numbers or defaults)', async () => {
    const res = await request(app).get('/api/news').query({ limit: "20; DROP TABLE", offset: '0 OR 1=1' })
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('news')
  })
})
