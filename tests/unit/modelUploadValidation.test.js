import { describe, it, expect, vi, beforeEach } from 'vitest'
import sharp from 'sharp'
import { buildTarGz } from '../../src/server/utils/buildTarGz.ts'
import {
  assertFlatUploadFilename,
  assertFileSizeUnderLimit,
  MODEL_UPLOAD_MAX_FILE_BYTES,
  normalizeTextFileBuffer,
  validateAc3dXmlPngNames,
  validateModelFileBuffers,
  validateModelAddFormFields,
  assertModelPathAvailable,
  validateModelfileBase64Package,
  validateThumbnailBase64Input,
} from '../../src/server/utils/modelUploadValidation.ts'
import * as modelRepo from '../../src/server/repositories/modelRepository.ts'
import * as modelgroupRepo from '../../src/server/repositories/modelgroupRepository.ts'

vi.mock('../../src/server/repositories/modelRepository.ts', () => ({
  findIdByPathBasename: vi.fn(),
}))

vi.mock('../../src/server/repositories/modelgroupRepository.ts', () => ({
  existsById: vi.fn(),
}))

async function pngPow2(w = 8, h = 8) {
  return sharp({
    create: { width: w, height: h, channels: 3, background: { r: 80, g: 80, b: 80 } },
  })
    .png()
    .toBuffer()
}

function acLines(textures) {
  const t = textures.map((n) => `texture "${n}"`).join('\n')
  return Buffer.from(`AC3D\n${t}`, 'utf8')
}

beforeEach(() => {
  vi.mocked(modelRepo.findIdByPathBasename).mockResolvedValue(null)
  vi.mocked(modelgroupRepo.existsById).mockImplementation((id) => Promise.resolve(Number(id) === 1))
})

describe('assertFlatUploadFilename', () => {
  it('accepts simple safe names', () => {
    expect(assertFlatUploadFilename('tower.ac')).toBe('tower.ac')
    expect(assertFlatUploadFilename('a-b_1.png')).toBe('a-b_1.png')
  })

  it('rejects path segments and traversal', () => {
    expect(assertFlatUploadFilename('dir/model.ac')).toBeNull()
    expect(assertFlatUploadFilename('..\\evil.ac')).toBeNull()
    expect(assertFlatUploadFilename('../evil.ac')).toBeNull()
    expect(assertFlatUploadFilename('x/../y.ac')).toBeNull()
  })

  it('rejects leading path noise that basename collapses', () => {
    expect(assertFlatUploadFilename('/abs.ac')).toBeNull()
  })
})

describe('assertFileSizeUnderLimit', () => {
  it('allows at limit', () => {
    expect(assertFileSizeUnderLimit(MODEL_UPLOAD_MAX_FILE_BYTES, 'x')).toBeNull()
  })

  it('rejects over limit', () => {
    const err = assertFileSizeUnderLimit(MODEL_UPLOAD_MAX_FILE_BYTES + 1, 'Big')
    expect(err).toContain('2 MB')
  })
})

describe('normalizeTextFileBuffer', () => {
  it('converts CRLF and lone CR to LF', () => {
    const out = normalizeTextFileBuffer(Buffer.from('a\r\nb\rc', 'utf8'))
    expect(out.toString('utf8')).toBe('a\nb\nc')
  })

  it('strips UTF-8 BOM before normalizing', () => {
    const bom = Buffer.from([0xef, 0xbb, 0xbf])
    const out = normalizeTextFileBuffer(Buffer.concat([bom, Buffer.from('AC3D', 'utf8')]))
    expect(out.toString('utf8')).toBe('AC3D')
  })
})

describe('validateAc3dXmlPngNames', () => {
  it('requires matching AC/XML stems', () => {
    expect(validateAc3dXmlPngNames('tower.ac', 'mast.xml', [])).toMatch(/same base name/)
  })

  it('rejects invalid AC extension', () => {
    expect(validateAc3dXmlPngNames('tower.obj', null, [])).toMatch(/\.ac/)
  })

  it('rejects spaces in filename', () => {
    expect(validateAc3dXmlPngNames('my tower.ac', null, [])).toMatch(/\.ac/)
  })
})

describe('validateModelFileBuffers', () => {
  it('accepts minimal valid AC + optional XML + textures', async () => {
    const tex = await pngPow2()
    const err = await validateModelFileBuffers({
      acBuffer: acLines(['t.png']),
      acFilename: 'm.ac',
      xmlBuffer: Buffer.from(
        '<?xml version="1.0" encoding="UTF-8" ?>\n<PropertyList><path>m.ac</path></PropertyList>',
        'utf8'
      ),
      xmlFilename: 'm.xml',
      pngFiles: [{ name: 't.png', buffer: tex }],
    })
    expect(err).toBeNull()
  })

  it('rejects AC without AC3D header', async () => {
    const err = await validateModelFileBuffers({
      acBuffer: Buffer.from('OBJ\n', 'utf8'),
      acFilename: 'm.ac',
      xmlBuffer: null,
      xmlFilename: null,
      pngFiles: [],
    })
    expect(err).toMatch(/AC3D/)
  })

  it('rejects missing PNG for referenced texture', async () => {
    const err = await validateModelFileBuffers({
      acBuffer: acLines(['missing.png']),
      acFilename: 'm.ac',
      xmlBuffer: null,
      xmlFilename: null,
      pngFiles: [],
    })
    expect(err).toMatch(/missing\.png/)
  })

  it('rejects non-power-of-two PNG dimensions', async () => {
    const bad = await sharp({
      create: { width: 3, height: 3, channels: 3, background: '#000' },
    })
      .png()
      .toBuffer()
    const err = await validateModelFileBuffers({
      acBuffer: acLines(['t.png']),
      acFilename: 'm.ac',
      xmlBuffer: null,
      xmlFilename: null,
      pngFiles: [{ name: 't.png', buffer: bad }],
    })
    expect(err).toMatch(/powers of 2/)
  })

  it('rejects XML without UTF-8 declaration', async () => {
    const err = await validateModelFileBuffers({
      acBuffer: acLines([]),
      acFilename: 'm.ac',
      xmlBuffer: Buffer.from('<PropertyList><path>m.ac</path></PropertyList>', 'utf8'),
      xmlFilename: 'm.xml',
      pngFiles: [],
    })
    expect(err).toMatch(/encoding="UTF-8"/)
  })

  it('rejects path element not matching AC filename', async () => {
    const err = await validateModelFileBuffers({
      acBuffer: acLines([]),
      acFilename: 'model.ac',
      xmlBuffer: Buffer.from(
        '<?xml version="1.0" encoding="UTF-8" ?>\n<PropertyList><path>other.ac</path></PropertyList>',
        'utf8'
      ),
      xmlFilename: 'model.xml',
      pngFiles: [],
    })
    expect(err).toMatch(/must be "model\.ac"/)
  })

  it('rejects garbage passed off as PNG', async () => {
    const err = await validateModelFileBuffers({
      acBuffer: acLines(['t.png']),
      acFilename: 'm.ac',
      xmlBuffer: null,
      xmlFilename: null,
      pngFiles: [{ name: 't.png', buffer: Buffer.from('not a png', 'utf8') }],
    })
    expect(err).toMatch(/PNG/)
  })
})

describe('validateModelAddFormFields', () => {
  const base = {
    name: 'N',
    description: '',
    comment: '',
    email: 'a@b.co',
    groupId: 1,
    authorId: 2,
    latitudeRaw: '0',
    longitudeRaw: '0',
    countryRaw: 'de',
    offsetRaw: '',
    headingRaw: '0',
  }

  it('accepts valid minimal fields', async () => {
    expect(await validateModelAddFormFields(base)).toBeNull()
  })

  it('rejects pipe in name (legacy delimiter)', async () => {
    expect(await validateModelAddFormFields({ ...base, name: 'a|b' })).toMatch(/\|/)
  })

  it('rejects long name', async () => {
    expect(await validateModelAddFormFields({ ...base, name: 'x'.repeat(101) })).toMatch(/100/)
  })

  it('rejects invalid email', async () => {
    const msg = await validateModelAddFormFields({ ...base, email: 'not-an-email' })
    expect(msg).toMatch(/valid email/)
  })

  it('rejects email longer than 50 characters', async () => {
    const long = `${'x'.repeat(46)}@y.co`
    expect(long.length).toBeGreaterThan(50)
    const msg = await validateModelAddFormFields({ ...base, email: long })
    expect(msg).toMatch(/50/)
  })

  it('rejects non-existent model group', async () => {
    vi.mocked(modelgroupRepo.existsById).mockResolvedValueOnce(false)
    expect(await validateModelAddFormFields({ ...base, groupId: 99 })).toMatch(/does not exist/)
  })

  it('requires author details when authorId is Other (1)', async () => {
    expect(
      await validateModelAddFormFields({
        ...base,
        authorId: 1,
        authorNew: { name: '', email: '' },
      })
    ).toMatch(/Other/)
    expect(
      await validateModelAddFormFields({
        ...base,
        authorId: 1,
        authorNew: { name: 'New', email: 'bad' },
      })
    ).toMatch(/author email/)
  })

  it('rejects latitude/longitude out of range', async () => {
    expect(await validateModelAddFormFields({ ...base, latitudeRaw: '91' })).toMatch(/Latitude/)
    expect(await validateModelAddFormFields({ ...base, longitudeRaw: '-181' })).toMatch(/Longitude/)
  })

  it('rejects offset at boundaries (open interval)', async () => {
    expect(await validateModelAddFormFields({ ...base, offsetRaw: '1000' })).toMatch(/offset/)
    expect(await validateModelAddFormFields({ ...base, offsetRaw: '-1000' })).toMatch(/offset/)
  })

  it('accepts offset just inside bounds', async () => {
    expect(await validateModelAddFormFields({ ...base, offsetRaw: '999.9' })).toBeNull()
    expect(await validateModelAddFormFields({ ...base, offsetRaw: '-999.9' })).toBeNull()
  })

  it('rejects heading 360 and negative', async () => {
    expect(await validateModelAddFormFields({ ...base, headingRaw: '360' })).toMatch(/Heading/)
    expect(await validateModelAddFormFields({ ...base, headingRaw: '-1' })).toMatch(/Heading/)
  })

  it('rejects invalid country', async () => {
    expect(await validateModelAddFormFields({ ...base, countryRaw: 'de4' })).toMatch(/Country/)
    expect(await validateModelAddFormFields({ ...base, countryRaw: 'd-e' })).toMatch(/Country/)
  })
})

describe('assertModelPathAvailable', () => {
  it('returns error when path taken', async () => {
    vi.mocked(modelRepo.findIdByPathBasename).mockResolvedValueOnce(42)
    expect(await assertModelPathAvailable('taken.ac')).toMatch(/already used/)
  })
})

describe('validateModelfileBase64Package', () => {
  it('accepts gzipped tar with ac, xml, png aligned with filename', async () => {
    const png = await pngPow2()
    const ac = normalizeTextFileBuffer(acLines(['tex.png']))
    const xml = Buffer.from(
      '<?xml version="1.0" encoding="UTF-8" ?>\n<PropertyList><path>u.ac</path></PropertyList>',
      'utf8'
    )
    const tar = await buildTarGz([
      { name: 'u.ac', buffer: ac },
      { name: 'u.xml', buffer: xml },
      { name: 'tex.png', buffer: png },
    ])
    expect(await validateModelfileBase64Package(tar.toString('base64'), 'u.xml')).toBeNull()
  })

  it('rejects empty / invalid archive', async () => {
    expect(await validateModelfileBase64Package(Buffer.from('nope').toString('base64'), 'x.ac')).toMatch(/empty|valid/)
  })

  it('rejects tarball with two AC files', async () => {
    const ac = normalizeTextFileBuffer(acLines([]))
    const tar = await buildTarGz([
      { name: 'a.ac', buffer: ac },
      { name: 'b.ac', buffer: ac },
    ])
    expect(await validateModelfileBase64Package(tar.toString('base64'), 'a.ac')).toMatch(/exactly one/)
  })

  it('rejects two XML files', async () => {
    const ac = normalizeTextFileBuffer(acLines([]))
    const xml = Buffer.from(
      '<?xml version="1.0" encoding="UTF-8" ?>\n<PropertyList><path>x.ac</path></PropertyList>',
      'utf8'
    )
    const tar = await buildTarGz([
      { name: 'x.ac', buffer: ac },
      { name: 'x.xml', buffer: xml },
      { name: 'copy.xml', buffer: xml },
    ])
    expect(await validateModelfileBase64Package(tar.toString('base64'), 'x.xml')).toMatch(/at most one/)
  })

  it('rejects path/filename in archive entry', async () => {
    const ac = normalizeTextFileBuffer(acLines([]))
    const tar = await buildTarGz([{ name: 'sub/m.ac', buffer: ac }])
    expect(await validateModelfileBase64Package(tar.toString('base64'), 'm.ac')).toMatch(/Invalid file name/)
  })

  it('rejects declared filename not matching archive primary name', async () => {
    const ac = normalizeTextFileBuffer(acLines([]))
    const tar = await buildTarGz([{ name: 'model.ac', buffer: ac }])
    expect(await validateModelfileBase64Package(tar.toString('base64'), 'other.ac')).toMatch(/match/)
  })

  it('rejects oversized member inside archive', async () => {
    const huge = Buffer.alloc(MODEL_UPLOAD_MAX_FILE_BYTES + 1, 0x41)
    const tar = await buildTarGz([{ name: 'big.ac', buffer: huge }])
    expect(await validateModelfileBase64Package(tar.toString('base64'), 'big.ac')).toMatch(/exceeds/)
  })
})

describe('validateThumbnailBase64Input', () => {
  it('accepts tiny valid png', async () => {
    const b64 = (await pngPow2(4, 4)).toString('base64')
    expect(await validateThumbnailBase64Input(b64)).toBeNull()
  })

  it('rejects empty and invalid', async () => {
    expect(await validateThumbnailBase64Input('')).toMatch(/empty/)
    expect(await validateThumbnailBase64Input(Buffer.from('zzz').toString('base64'))).toMatch(/valid image/)
  })
})
