import zlib from 'zlib'

export interface TarEntry {
  name: string
  size: number
}

export function listTarEntries(buffer: Buffer): TarEntry[] {
  if (!buffer || buffer.length < 512) return []
  let buf = buffer
  if (buffer[0] === 0x1f && buffer[1] === 0x8b) {
    try {
      buf = zlib.gunzipSync(buffer)
    } catch {
      return []
    }
  }
  const entries: TarEntry[] = []
  let offset = 0
  while (offset + 512 <= buf.length) {
    const name = buf.subarray(offset, offset + 100).toString('utf8').replace(/\0/g, '').trim()
    const sizeStr = buf.subarray(offset + 124, offset + 136).toString('utf8').trim()
    const typeflag = buf[offset + 156]
    const size = parseInt(sizeStr, 8) || 0
    if (name.length > 0) {
      const isFile = typeflag === 0 || typeflag === 0x30
      if (isFile) entries.push({ name, size })
    }
    offset += 512 + Math.ceil(size / 512) * 512
    if (offset >= buf.length) break
  }
  return entries
}

function getTarBuffer(buffer: Buffer): Buffer | null {
  if (!buffer || buffer.length < 512) return null
  if (buffer[0] === 0x1f && buffer[1] === 0x8b) {
    try {
      return zlib.gunzipSync(buffer)
    } catch {
      return null
    }
  }
  return buffer
}

/** Extract all regular files from a tar or gzip+tar buffer into a map (name → contents). */
export function extractTarToMap(buffer: Buffer): Map<string, Buffer> {
  const map = new Map<string, Buffer>()
  const buf = getTarBuffer(buffer)
  if (!buf) return map
  let offset = 0
  while (offset + 512 <= buf.length) {
    const name = buf.subarray(offset, offset + 100).toString('utf8').replace(/\0/g, '').trim()
    const sizeStr = buf.subarray(offset + 124, offset + 136).toString('utf8').trim()
    const typeflag = buf[offset + 156]
    const size = parseInt(sizeStr, 8) || 0
    if (name.length > 0) {
      const isFile = typeflag === 0 || typeflag === 0x30
      if (isFile && size > 0 && offset + 512 + size <= buf.length) {
        map.set(name, Buffer.from(buf.subarray(offset + 512, offset + 512 + size)))
      }
    }
    offset += 512 + Math.ceil(size / 512) * 512
    if (offset >= buf.length) break
  }
  return map
}

export function getTarFileContent(buffer: Buffer, requestedName: string): Buffer | null {
  const buf = getTarBuffer(buffer)
  if (!buf || !requestedName || typeof requestedName !== 'string') return null
  const name = requestedName.trim()
  if (!name) return null
  let offset = 0
  while (offset + 512 <= buf.length) {
    const entryName = buf.subarray(offset, offset + 100).toString('utf8').replace(/\0/g, '').trim()
    const sizeStr = buf.subarray(offset + 124, offset + 136).toString('utf8').trim()
    const typeflag = buf[offset + 156]
    const size = parseInt(sizeStr, 8) || 0
    if (entryName === name) {
      const isFile = typeflag === 0 || typeflag === 0x30
      if (isFile && size > 0 && offset + 512 + size <= buf.length) {
        return Buffer.from(buf.subarray(offset + 512, offset + 512 + size))
      }
      return isFile ? Buffer.alloc(0) : null
    }
    offset += 512 + Math.ceil(size / 512) * 512
    if (offset >= buf.length) break
  }
  return null
}
