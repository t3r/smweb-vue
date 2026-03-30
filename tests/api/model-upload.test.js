import { describe, it, expect, beforeAll, beforeEach, vi } from 'vitest'
import request from 'supertest'
import sharp from 'sharp'
import { buildTarGz } from '../../src/server/utils/buildTarGz.ts'
import { normalizeTextFileBuffer } from '../../src/server/utils/modelUploadValidation.ts'

vi.mock('../../src/server/middleware/auth.ts', () => ({
  requireAuth: (_req, _res, next) => next(),
  requireRole: () => (_req, _res, next) => next(),
}))

import { appPromise } from '../helpers/app.js'

let app
/** Same module instance as controllers (for spies on named exports). */
let uploadValidation
let modelgroupRepo

beforeAll(async () => {
  app = await appPromise
  uploadValidation = await import('../../src/server/utils/modelUploadValidation.ts')
  modelgroupRepo = await import('../../src/server/repositories/modelgroupRepository.ts')
})

async function pow2Png(w = 8, h = 8) {
  return sharp({
    create: { width: w, height: h, channels: 3, background: { r: 90, g: 90, b: 90 } },
  })
    .png()
    .toBuffer()
}

function acBuffer(textures) {
  const lines = ['AC3D', ...textures.map((n) => `texture "${n}"`)]
  return Buffer.from(lines.join('\n'), 'utf8')
}

async function validTarGz(baseName, { withXml = true } = {}) {
  const png = await pow2Png()
  const ac = normalizeTextFileBuffer(acBuffer(['tex.png']))
  const entries = [
    { name: `${baseName}.ac`, buffer: ac },
    { name: 'tex.png', buffer: png },
  ]
  if (withXml) {
    const xml = Buffer.from(
      `<?xml version="1.0" encoding="UTF-8" ?>\n<PropertyList><path>${baseName}.ac</path></PropertyList>`,
      'utf8'
    )
    entries.splice(1, 0, { name: `${baseName}.xml`, buffer: xml })
  }
  const tar = await buildTarGz(entries)
  return { gzip: tar, baseName, pathToSubmit: withXml ? `${baseName}.xml` : `${baseName}.ac` }
}

beforeEach(() => {
  vi.mocked(modelgroupRepo.existsById).mockImplementation((id) => Promise.resolve(Number(id) === 1))
})

function jsonBody(overrides = {}) {
  const id = `t${Date.now()}${Math.random().toString(16).slice(2, 8)}`
  return {
    name: `Model ${id}`,
    filename: `${id}.xml`,
    description: 'd',
    authorId: 2,
    groupId: 1,
    longitude: 8.5,
    latitude: 52.0,
    country: 'de',
    offset: '',
    heading: 0,
    gplAccepted: true,
    email: 'u@example.com',
    comment: '',
    ...overrides,
  }
}

describe('POST /api/submissions/models (JSON)', () => {
  it('returns 201 on happy path with XML + textures', async () => {
    const id = `j${Date.now()}`
    const { gzip, pathToSubmit } = await validTarGz(id, { withXml: true })
    const thumb = (await pow2Png(4, 4)).toString('base64')
    const res = await request(app)
      .post('/api/submissions/models')
      .send({
        ...jsonBody({ filename: pathToSubmit }),
        modelfileBase64: gzip.toString('base64'),
        thumbnailBase64: thumb,
      })
    expect(res.status).toBe(201)
    expect(res.body).toMatchObject({ id: expect.any(Number), sig: expect.any(String) })
  })

  it('returns 201 with AC-only package when filename matches .ac', async () => {
    const id = `ja${Date.now()}`
    const { gzip, pathToSubmit } = await validTarGz(id, { withXml: false })
    const thumb = (await pow2Png(4, 4)).toString('base64')
    const res = await request(app)
      .post('/api/submissions/models')
      .send({
        ...jsonBody({ filename: pathToSubmit }),
        modelfileBase64: gzip.toString('base64'),
        thumbnailBase64: thumb,
      })
    expect(res.status).toBe(201)
  })

  it('returns 400 when gplAccepted is not true', async () => {
    const res = await request(app)
      .post('/api/submissions/models')
      .send({ ...jsonBody(), gplAccepted: false, modelfileBase64: 'eA==', thumbnailBase64: (await pow2Png(4, 4)).toString('base64') })
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/GPL/)
  })

  it('returns 400 when model path already exists', async () => {
    const spy = vi
      .spyOn(uploadValidation, 'assertModelPathAvailable')
      .mockResolvedValue('Filename "taken.ac" is already used by another model.')
    try {
      const id = `dup${Date.now()}`
      const { gzip, pathToSubmit } = await validTarGz(id)
      const res = await request(app)
        .post('/api/submissions/models')
        .send({
          ...jsonBody({ filename: pathToSubmit }),
          modelfileBase64: gzip.toString('base64'),
          thumbnailBase64: (await pow2Png(4, 4)).toString('base64'),
        })
      expect(res.status).toBe(400)
      expect(res.body.error).toMatch(/already used/)
    } finally {
      spy.mockRestore()
    }
  })

  it('returns 400 when model family does not exist', async () => {
    vi.mocked(modelgroupRepo.existsById).mockResolvedValueOnce(false)
    const id = `nf${Date.now()}`
    const { gzip, pathToSubmit } = await validTarGz(id)
    const res = await request(app)
      .post('/api/submissions/models')
      .send({
        ...jsonBody({ filename: pathToSubmit, groupId: 999 }),
        modelfileBase64: gzip.toString('base64'),
        thumbnailBase64: (await pow2Png(4, 4)).toString('base64'),
      })
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/does not exist/)
  })

  it('returns 400 for invalid modelfile archive', async () => {
    const res = await request(app)
      .post('/api/submissions/models')
      .send({
        ...jsonBody(),
        modelfileBase64: Buffer.from('not-a-tar').toString('base64'),
        thumbnailBase64: (await pow2Png(4, 4)).toString('base64'),
      })
    expect(res.status).toBe(400)
    expect(String(res.body.error)).toMatch(/empty|valid gzip|tar|package/i)
  })

  it('returns 400 when filename does not match archive primary file', async () => {
    const id = `mis${Date.now()}`
    const { gzip } = await validTarGz(id)
    const res = await request(app)
      .post('/api/submissions/models')
      .send({
        ...jsonBody({ filename: 'other.xml' }),
        modelfileBase64: gzip.toString('base64'),
        thumbnailBase64: (await pow2Png(4, 4)).toString('base64'),
      })
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/match/)
  })

  it('returns 400 for invalid thumbnail base64', async () => {
    const id = `th${Date.now()}`
    const { gzip, pathToSubmit } = await validTarGz(id)
    const res = await request(app)
      .post('/api/submissions/models')
      .send({
        ...jsonBody({ filename: pathToSubmit }),
        modelfileBase64: gzip.toString('base64'),
        thumbnailBase64: Buffer.from('not an image').toString('base64'),
      })
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/thumbnail|image/i)
  })

  it('returns 400 for invalid author id', async () => {
    const id = `au${Date.now()}`
    const { gzip, pathToSubmit } = await validTarGz(id)
    const res = await request(app)
      .post('/api/submissions/models')
      .send({
        ...jsonBody({ filename: pathToSubmit, authorId: 1000 }),
        modelfileBase64: gzip.toString('base64'),
        thumbnailBase64: (await pow2Png(4, 4)).toString('base64'),
      })
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/author|Invalid/)
  })

  it('returns 400 when Other author missing details', async () => {
    const id = `ot${Date.now()}`
    const { gzip, pathToSubmit } = await validTarGz(id)
    const res = await request(app)
      .post('/api/submissions/models')
      .send({
        ...jsonBody({ filename: pathToSubmit, authorId: 1, authorNew: { name: '', email: '' } }),
        modelfileBase64: gzip.toString('base64'),
        thumbnailBase64: (await pow2Png(4, 4)).toString('base64'),
      })
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/Other/)
  })
})

describe('POST /api/submissions/models/upload (multipart)', () => {
  it('returns 201 on happy path', async () => {
    const id = `m${Date.now()}`
    const png = await pow2Png()
    const ac = normalizeTextFileBuffer(acBuffer(['tex.png']))
    const xml = Buffer.from(
      `<?xml version="1.0" encoding="UTF-8" ?>\n<PropertyList><path>${id}.ac</path></PropertyList>`,
      'utf8'
    )
    const thumb = await sharp({
      create: { width: 16, height: 16, channels: 3, background: '#333' },
    })
      .jpeg()
      .toBuffer()

    const res = await request(app)
      .post('/api/submissions/models/upload')
      .field('name', `Upload ${id}`)
      .field('description', '')
      .field('comment', '')
      .field('email', 'sub@example.com')
      .field('latitude', '52')
      .field('longitude', '8')
      .field('country', 'de')
      .field('offset', '')
      .field('heading', '0')
      .field('groupId', '1')
      .field('authorId', '2')
      .field('gplAccepted', 'true')
      .attach('thumbnail', thumb, 'thumb.jpg')
      .attach('ac3d', ac, `${id}.ac`)
      .attach('xml', xml, `${id}.xml`)
      .attach('png', png, 'tex.png')

    expect(res.status).toBe(201)
    expect(res.body).toMatchObject({ id: expect.any(Number), sig: expect.any(String) })
  })

  it('returns 400 without thumbnail', async () => {
    const id = `nx${Date.now()}`
    const ac = acBuffer([])
    const res = await request(app)
      .post('/api/submissions/models/upload')
      .field('name', 'x')
      .field('email', 'a@b.co')
      .field('latitude', '0')
      .field('longitude', '0')
      .field('country', 'us')
      .field('groupId', '1')
      .field('authorId', '2')
      .field('gplAccepted', 'true')
      .attach('ac3d', ac, `${id}.ac`)
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/thumbnail/)
  })

  it('returns 400 without AC', async () => {
    const thumb = await sharp({
      create: { width: 8, height: 8, channels: 3, background: '#000' },
    })
      .png()
      .toBuffer()
    const res = await request(app)
      .post('/api/submissions/models/upload')
      .field('name', 'x')
      .field('email', 'a@b.co')
      .field('latitude', '0')
      .field('longitude', '0')
      .field('country', 'us')
      .field('groupId', '1')
      .field('authorId', '2')
      .field('gplAccepted', 'true')
      .attach('thumbnail', thumb, 't.png')
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/AC3D/)
  })

  it('returns 400 when AC/XML basenames differ', async () => {
    const thumb = await pow2Png(4, 4)
    const ac = normalizeTextFileBuffer(acBuffer([]))
    const xml = Buffer.from(
      '<?xml version="1.0" encoding="UTF-8" ?>\n<PropertyList><path>a.ac</path></PropertyList>',
      'utf8'
    )
    const res = await request(app)
      .post('/api/submissions/models/upload')
      .field('name', 'Mismatch')
      .field('email', 'a@b.co')
      .field('latitude', '0')
      .field('longitude', '0')
      .field('country', 'us')
      .field('groupId', '1')
      .field('authorId', '2')
      .field('gplAccepted', 'true')
      .attach('thumbnail', thumb, 'thumb.png')
      .attach('ac3d', ac, 'model.ac')
      .attach('xml', xml, 'other.xml')
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/same base name/)
  })

  it('returns 400 for AC filename containing .. (traversal)', async () => {
    const thumb = await pow2Png(4, 4)
    const ac = normalizeTextFileBuffer(acBuffer([]))
    const res = await request(app)
      .post('/api/submissions/models/upload')
      .field('name', 'Bad name field')
      .field('email', 'a@b.co')
      .field('latitude', '0')
      .field('longitude', '0')
      .field('country', 'us')
      .field('groupId', '1')
      .field('authorId', '2')
      .field('gplAccepted', 'true')
      .attach('thumbnail', thumb, 'thumb.png')
      .attach('ac3d', ac, 'model..ac')
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/AC3D file name/)
  })

  it('returns 400 when AC is not valid AC3D', async () => {
    const thumb = await pow2Png(4, 4)
    const id = `bad${Date.now()}`
    const res = await request(app)
      .post('/api/submissions/models/upload')
      .field('name', 'Bad ac')
      .field('email', 'a@b.co')
      .field('latitude', '0')
      .field('longitude', '0')
      .field('country', 'us')
      .field('groupId', '1')
      .field('authorId', '2')
      .field('gplAccepted', 'true')
      .attach('thumbnail', thumb, 'thumb.png')
      .attach('ac3d', Buffer.from('hello world'), `${id}.ac`)
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/AC3D/)
  })

  it('returns 400 when texture is missing for AC reference', async () => {
    const thumb = await pow2Png(4, 4)
    const id = `tex${Date.now()}`
    const ac = normalizeTextFileBuffer(acBuffer(['missing.png']))
    const res = await request(app)
      .post('/api/submissions/models/upload')
      .field('name', 'No tex')
      .field('email', 'a@b.co')
      .field('latitude', '0')
      .field('longitude', '0')
      .field('country', 'us')
      .field('groupId', '1')
      .field('authorId', '2')
      .field('gplAccepted', 'true')
      .attach('thumbnail', thumb, 'thumb.png')
      .attach('ac3d', ac, `${id}.ac`)
    expect(res.status).toBe(400)
    expect(res.body.error).toMatch(/missing\.png/)
  })

  it('returns 400 for duplicate model path', async () => {
    const spy = vi
      .spyOn(uploadValidation, 'assertModelPathAvailable')
      .mockResolvedValue('Filename "x.ac" is already used by another model.')
    try {
      const id = `dp${Date.now()}`
      const png = await pow2Png()
      const ac = normalizeTextFileBuffer(acBuffer(['tex.png']))
      const xml = Buffer.from(
        `<?xml version="1.0" encoding="UTF-8" ?>\n<PropertyList><path>${id}.ac</path></PropertyList>`,
        'utf8'
      )
      const thumb = await pow2Png(4, 4)
      const res = await request(app)
        .post('/api/submissions/models/upload')
        .field('name', 'Dup path')
        .field('email', 'a@b.co')
        .field('latitude', '0')
        .field('longitude', '0')
        .field('country', 'us')
        .field('groupId', '1')
        .field('authorId', '2')
        .field('gplAccepted', 'true')
        .attach('thumbnail', thumb, 'thumb.png')
        .attach('ac3d', ac, `${id}.ac`)
        .attach('xml', xml, `${id}.xml`)
        .attach('png', png, 'tex.png')
      expect(res.status).toBe(400)
      expect(res.body.error).toMatch(/already used/)
    } finally {
      spy.mockRestore()
    }
  })
})
