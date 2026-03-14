import sharp from 'sharp'

const THUMBNAIL_WIDTH = 320
const THUMBNAIL_HEIGHT = 240

/**
 * Convert an image buffer (any supported format) to JPEG and scale to 320x240.
 * Returns the JPEG buffer; throws if the input is not a valid image.
 */
export async function convertToThumbnailJpeg(inputBuffer: Buffer): Promise<Buffer> {
  return sharp(inputBuffer)
    .resize(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT, { fit: 'cover' })
    .jpeg()
    .toBuffer()
}
