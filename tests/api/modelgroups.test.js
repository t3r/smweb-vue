import { describe, it, expect, beforeAll } from 'vitest'
import request from 'supertest'
import { appPromise } from '../helpers/app.js'

let app
beforeAll(async () => {
  app = await appPromise
})

describe('GET /api/modelgroups', () => {
  it('returns 200 and list of groups with id, name, path', async () => {
    const res = await request(app).get('/api/modelgroups')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('groups')
    expect(Array.isArray(res.body.groups)).toBe(true)
    if (res.body.groups.length > 0) {
      expect(res.body.groups[0]).toHaveProperty('id')
      expect(res.body.groups[0]).toHaveProperty('name')
      expect(res.body.groups[0]).toHaveProperty('path')
    }
  })
})
