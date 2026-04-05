import { describe, it, expect, beforeAll, afterEach, vi } from 'vitest'
/**
 * Real `requirePositionRequestSubmitAuth` (do not mock ../middleware/auth.ts).
 * Relies on mocks.js for DB/repos only.
 */
import '../helpers/mocks.js'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app

beforeAll(async () => {
  app = await appPromise
})

afterEach(() => {
  vi.unstubAllEnvs()
})

/** Empty body: passes auth middleware, fails controller on first validation (email). */
async function postObjectDeleteEmpty() {
  return request(app).post('/api/submissions/object/delete').send({})
}

describe('POSITION_REQUEST_SUBMIT_ROLE (API)', () => {
  it('returns 401 without session when role is user', async () => {
    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', 'user')
    const res = await postObjectDeleteEmpty()
    expect(res.status).toBe(401)
    expect(res.body).toMatchObject({ error: 'Authentication required' })
  })

  it('returns 401 without session when env unset (default user)', async () => {
    const res = await postObjectDeleteEmpty()
    expect(res.status).toBe(401)
    expect(res.body).toMatchObject({ error: 'Authentication required' })
  })

  it('returns 400 (not 401) without session when role is none', async () => {
    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', 'none')
    const res = await postObjectDeleteEmpty()
    expect(res.status).toBe(400)
    expect(String(res.body.error || '')).toMatch(/email/i)
  })

  it('returns 400 (not 401) without session when role is anonymous', async () => {
    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', 'anonymous')
    const res = await postObjectDeleteEmpty()
    expect(res.status).toBe(400)
    expect(String(res.body.error || '')).toMatch(/email/i)
  })

  it('returns 400 (not 401) without session when role is off', async () => {
    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', 'off')
    const res = await postObjectDeleteEmpty()
    expect(res.status).toBe(400)
    expect(String(res.body.error || '')).toMatch(/email/i)
  })

  it('returns 401 without session when role is reviewer', async () => {
    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', 'reviewer')
    const res = await postObjectDeleteEmpty()
    expect(res.status).toBe(401)
    expect(res.body).toMatchObject({ error: 'Authentication required' })
  })

  it('applies same gate to POST /api/submissions/models (JSON)', async () => {
    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', 'user')
    const res = await request(app).post('/api/submissions/models').send({})
    expect(res.status).toBe(401)

    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', 'none')
    const res2 = await request(app).post('/api/submissions/models').send({})
    expect(res2.status).not.toBe(401)
    expect(res2.status).toBeGreaterThanOrEqual(400)
  })
})
