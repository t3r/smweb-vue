import { describe, it, expect, beforeAll, beforeEach, afterEach } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app

beforeAll(async () => {
  app = await appPromise
})

const saved = {}

beforeEach(() => {
  saved.API_DOCS_USERNAME = process.env.API_DOCS_USERNAME
  saved.API_DOCS_PASSWORD = process.env.API_DOCS_PASSWORD
})

afterEach(() => {
  if (saved.API_DOCS_USERNAME === undefined) delete process.env.API_DOCS_USERNAME
  else process.env.API_DOCS_USERNAME = saved.API_DOCS_USERNAME
  if (saved.API_DOCS_PASSWORD === undefined) delete process.env.API_DOCS_PASSWORD
  else process.env.API_DOCS_PASSWORD = saved.API_DOCS_PASSWORD
})

describe('GET /api-docs', () => {
  it('returns 503 when credentials are not configured', async () => {
    delete process.env.API_DOCS_USERNAME
    delete process.env.API_DOCS_PASSWORD
    const res = await request(app).get('/api-docs')
    expect(res.status).toBe(503)
    expect(res.body.error).toMatch(/API_DOCS_USERNAME/)
  })

  it('returns 401 without Authorization when credentials are set', async () => {
    process.env.API_DOCS_USERNAME = 'docuser'
    process.env.API_DOCS_PASSWORD = 'docpass'
    const res = await request(app).get('/api-docs')
    expect(res.status).toBe(401)
    expect(res.headers['www-authenticate']).toMatch(/Basic/)
  })

  it('returns 401 for wrong password', async () => {
    process.env.API_DOCS_USERNAME = 'docuser'
    process.env.API_DOCS_PASSWORD = 'docpass'
    const bad = Buffer.from('docuser:wrong').toString('base64')
    const res = await request(app).get('/api-docs').set('Authorization', `Basic ${bad}`)
    expect(res.status).toBe(401)
  })

  it('returns HTML for valid Basic credentials', async () => {
    process.env.API_DOCS_USERNAME = 'docuser'
    process.env.API_DOCS_PASSWORD = 'docpass'
    const token = Buffer.from('docuser:docpass').toString('base64')
    const res = await request(app).get('/api-docs').redirects(1).set('Authorization', `Basic ${token}`)
    expect(res.status).toBe(200)
    expect(res.type).toMatch(/html/)
  })
})
