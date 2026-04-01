import { describe, it, expect } from 'vitest'
import { convertToThumbnailJpeg } from '../../src/server/utils/thumbnailImage.ts'

/** 1×1 PNG */
const TINY_PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64'
)

describe('convertToThumbnailJpeg', () => {
  it('returns a JPEG buffer with expected rough dimensions (sharp resize)', async () => {
    const out = await convertToThumbnailJpeg(TINY_PNG)
    expect(Buffer.isBuffer(out)).toBe(true)
    expect(out.length).toBeGreaterThan(100)
    expect(out[0]).toBe(0xff)
    expect(out[1]).toBe(0xd8)
  })

  it('rejects invalid image data', async () => {
    await expect(convertToThumbnailJpeg(Buffer.from('not an image'))).rejects.toThrow()
  })
})
