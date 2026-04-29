import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('Account merge API (unauthenticated)', () => {
  it('POST /api/auth/merge/initiate returns 401', async () => {
    const res = await request(app).post('/api/auth/merge/initiate').send({ targetEmail: 'a@b.com' })
    expect(res.status).toBe(401)
  })

  it('GET /api/auth/merge/preview returns 401', async () => {
    const res = await request(app)
      .get('/api/auth/merge/preview')
      .query({ token: 'x', id: '00000000-0000-4000-8000-000000000001' })
    expect(res.status).toBe(401)
  })

  it('POST /api/auth/merge/confirm returns 401', async () => {
    const res = await request(app)
      .post('/api/auth/merge/confirm')
      .send({ token: 'x', id: '00000000-0000-4000-8000-000000000001' })
    expect(res.status).toBe(401)
  })

  it('POST /api/auth/merge/cancel returns 401', async () => {
    const res = await request(app)
      .post('/api/auth/merge/cancel')
      .send({ id: '00000000-0000-4000-8000-000000000001' })
    expect(res.status).toBe(401)
  })
})
