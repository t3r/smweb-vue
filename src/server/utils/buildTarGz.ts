import tar from 'tar-stream'
import zlib from 'zlib'

export interface TarEntry {
  name: string
  buffer: Buffer
}

/**
 * Build a gzipped tarball from a list of { name, buffer } entries.
 * Returns the gzip buffer (suitable for base64 encoding).
 */
export function buildTarGz(entries: TarEntry[]): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const pack = tar.pack()
    const chunks: Buffer[] = []

    pack.on('data', (chunk: Buffer) => chunks.push(chunk))
    pack.on('error', reject)
    pack.on('end', () => {
      const tarBuffer = Buffer.concat(chunks)
      zlib.gzip(tarBuffer, (err, gzipBuffer) => {
        if (err) reject(err)
        else resolve(gzipBuffer)
      })
    })

    try {
      for (const { name, buffer } of entries) {
        ;(pack as { entry: (h: { name: string; size: number }, b: Buffer) => void }).entry(
          { name, size: buffer.length },
          buffer
        )
      }
      pack.finalize()
    } catch (e) {
      reject(e)
    }
  })
}
