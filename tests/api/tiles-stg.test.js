import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/tiles/:tile/stg', () => {
  it('returns 400 text/plain for invalid tile', async () => {
    const res = await request(app).get('/api/tiles/not-a-tile/stg')
    expect(res.status).toBe(400)
    expect(res.headers['content-type']).toMatch(/text\/plain/)
    expect(res.text).toMatch(/invalid/i)
  })

  it('returns 404 text/plain when tile has no content (mocked / empty DB)', async () => {
    const res = await request(app).get('/api/tiles/99/stg')
    expect(res.status).toBe(404)
    expect(res.headers['content-type']).toMatch(/text\/plain/)
  })

  it('returns 200 text/plain with STG body for a tile with content (mocked)', async () => {
    const res = await request(app).get('/api/tiles/42/stg')
    expect(res.status).toBe(200)
    expect(res.headers['content-type']).toMatch(/text\/plain/)
    expect(res.text).toContain('OBJECT_STATIC')
    expect(res.text.endsWith('\n')).toBe(true)
  })
})
