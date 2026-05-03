import zlib from 'zlib'

export interface TarEntry {
  name: string
  size: number
}

/** Max bytes after gzip decompress or raw ustar tar (mitigates gzip/tar bombs). */
export const MAX_TAR_DECOMPRESSED_BYTES = 50_000_000

/** Max declared size for a single regular file in the tar header (octal field abuse). */
export const MAX_TAR_ENTRY_BYTES = MAX_TAR_DECOMPRESSED_BYTES

/** Max regular-file entries processed (header-loop DoS). */
export const MAX_TAR_FILE_ENTRIES = 500

function gunzipLimited(input: Buffer): Buffer | null {
  try {
    return zlib.gunzipSync(input, { maxOutputLength: MAX_TAR_DECOMPRESSED_BYTES })
  } catch {
    return null
  }
}

/** Parse ustar size field; reject negative, non-finite, or oversized (decompression-bomb headers). */
function readTarEntrySize(buf: Buffer, offset: number): number | null {
  if (offset + 136 > buf.length) return null
  const raw = buf.subarray(offset + 124, offset + 136).toString('utf8').trim()
  const n = parseInt(raw, 8) || 0
  if (!Number.isFinite(n) || n < 0) return null
  if (n > MAX_TAR_ENTRY_BYTES) return null
  return n
}

function advanceOffset(offset: number, size: number, bufLen: number): number | null {
  const blocks = Math.ceil(size / 512) * 512
  const next = offset + 512 + blocks
  if (!Number.isFinite(next) || next > bufLen) return null
  return next
}

export function listTarEntries(buffer: Buffer): TarEntry[] {
  if (!buffer || buffer.length < 2) return []
  let buf = buffer
  if (buffer[0] === 0x1f && buffer[1] === 0x8b) {
    const out = gunzipLimited(buffer)
    if (!out) return []
    buf = out
  }
  if (buf.length > MAX_TAR_DECOMPRESSED_BYTES) return []
  if (buf.length < 512) return []
  const entries: TarEntry[] = []
  let offset = 0
  let fileCount = 0
  while (offset + 512 <= buf.length) {
    const name = buf.subarray(offset, offset + 100).toString('utf8').replace(/\0/g, '').trim()
    const size = readTarEntrySize(buf, offset)
    if (size === null) return []
    const typeflag = buf[offset + 156]
    if (name.length > 0) {
      const isFile = typeflag === 0 || typeflag === 0x30
      if (isFile) {
        fileCount += 1
        if (fileCount > MAX_TAR_FILE_ENTRIES) return []
        if (offset + 512 + size > buf.length) return []
        entries.push({ name, size })
      }
    }
    const next = advanceOffset(offset, size, buf.length)
    if (next === null) return []
    offset = next
    if (offset >= buf.length) break
  }
  return entries
}

function getTarBuffer(buffer: Buffer): Buffer | null {
  if (!buffer || buffer.length < 2) return null
  if (buffer[0] === 0x1f && buffer[1] === 0x8b) {
    const out = gunzipLimited(buffer)
    if (!out || out.length < 512) return null
    if (out.length > MAX_TAR_DECOMPRESSED_BYTES) return null
    return out
  }
  if (buffer.length > MAX_TAR_DECOMPRESSED_BYTES) return null
  if (buffer.length < 512) return null
  return buffer
}

/** Extract all regular files from a tar or gzip+tar buffer into a map (name → contents). */
export function extractTarToMap(buffer: Buffer): Map<string, Buffer> {
  const map = new Map<string, Buffer>()
  const buf = getTarBuffer(buffer)
  if (!buf) return map
  let offset = 0
  let fileCount = 0
  let totalPayload = 0
  while (offset + 512 <= buf.length) {
    const name = buf.subarray(offset, offset + 100).toString('utf8').replace(/\0/g, '').trim()
    const size = readTarEntrySize(buf, offset)
    if (size === null) return new Map()
    const typeflag = buf[offset + 156]
    if (name.length > 0) {
      const isFile = typeflag === 0 || typeflag === 0x30
      if (isFile && size > 0) {
        if (offset + 512 + size > buf.length) return new Map()
        fileCount += 1
        if (fileCount > MAX_TAR_FILE_ENTRIES) return new Map()
        if (totalPayload + size > MAX_TAR_DECOMPRESSED_BYTES) return new Map()
        totalPayload += size
        map.set(name, Buffer.from(buf.subarray(offset + 512, offset + 512 + size)))
      }
    }
    const next = advanceOffset(offset, size, buf.length)
    if (next === null) return new Map()
    offset = next
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
  let fileCount = 0
  let totalPayload = 0
  while (offset + 512 <= buf.length) {
    const entryName = buf.subarray(offset, offset + 100).toString('utf8').replace(/\0/g, '').trim()
    const size = readTarEntrySize(buf, offset)
    if (size === null) return null
    const typeflag = buf[offset + 156]
    const isFile = typeflag === 0 || typeflag === 0x30

    if (entryName === name) {
      if (isFile && size > 0) {
        if (offset + 512 + size > buf.length) return null
        fileCount += 1
        if (fileCount > MAX_TAR_FILE_ENTRIES) return null
        if (totalPayload + size > MAX_TAR_DECOMPRESSED_BYTES) return null
        totalPayload += size
        return Buffer.from(buf.subarray(offset + 512, offset + 512 + size))
      }
      if (isFile && size === 0) {
        const next = advanceOffset(offset, size, buf.length)
        if (next === null) return null
        offset = next
        return Buffer.alloc(0)
      }
      const next = advanceOffset(offset, size, buf.length)
      if (next === null) return null
      offset = next
      return null
    }

    if (entryName.length > 0 && isFile && size > 0) {
      fileCount += 1
      if (fileCount > MAX_TAR_FILE_ENTRIES) return null
      totalPayload += size
      if (totalPayload > MAX_TAR_DECOMPRESSED_BYTES) return null
    }

    const next = advanceOffset(offset, size, buf.length)
    if (next === null) return null
    offset = next
    if (offset >= buf.length) break
  }
  return null
}
