import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/airports/by-icao/:icao', () => {
  it('returns 400 for invalid ICAO', async () => {
    const res = await request(app).get('/api/airports/by-icao/!!!')
    expect(res.status).toBe(400)
  })

  it('returns 404 when not in DB (mock)', async () => {
    const res = await request(app).get('/api/airports/by-icao/XXXX')
    expect(res.status).toBe(404)
    expect(res.body.icao).toBe('XXXX')
  })

  it('returns position for EDDF (mock)', async () => {
    const res = await request(app).get('/api/airports/by-icao/EDDF')
    expect(res.status).toBe(200)
    expect(res.body).toMatchObject({
      icao: 'EDDF',
      latitude: 50.026706,
      longitude: 8.55835,
    })
  })
})
