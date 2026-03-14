import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/countries', () => {
  it('returns 200 and list of countries with code and name', async () => {
    const res = await request(app).get('/api/countries')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('countries')
    expect(Array.isArray(res.body.countries)).toBe(true)
    if (res.body.countries.length > 0) {
      expect(res.body.countries[0]).toHaveProperty('code')
      expect(res.body.countries[0]).toHaveProperty('name')
    }
  })
})
