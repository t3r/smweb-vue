import { describe, it, expect } from 'vitest'
import zlib from 'zlib'
import {
  listTarEntries,
  extractTarToMap,
  getTarFileContent,
  MAX_TAR_DECOMPRESSED_BYTES,
} from '../../src/server/utils/tarList.ts'

/** Minimal POSIX ustar header (512 bytes) + file body padded to 512 multiple. */
function makeTarWithOneFile(name, content) {
  const body = Buffer.from(content, 'utf8')
  const header = Buffer.alloc(512, 0)
  const nameBuf = Buffer.from(name.slice(0, 100), 'utf8')
  nameBuf.copy(header, 0)
  const sizeOct = body.length.toString(8) + '\0'
  Buffer.from(sizeOct.padStart(11, '0'), 'ascii').copy(header, 124)
  header[156] = 0x30
  const block = Math.ceil(body.length / 512) * 512
  const padded = Buffer.alloc(block)
  body.copy(padded)
  const end = Buffer.alloc(1024, 0)
  return Buffer.concat([header, padded, end])
}

describe('listTarEntries', () => {
  it('returns [] for empty or tiny buffer', () => {
    expect(listTarEntries(Buffer.alloc(0))).toEqual([])
    expect(listTarEntries(Buffer.from([1]))).toEqual([])
  })

  it('returns [] for invalid gzip', () => {
    const bad = Buffer.from([0x1f, 0x8b, 0x00, 0x00])
    expect(listTarEntries(bad)).toEqual([])
  })

  it('lists one file from plain tar', () => {
    const tar = makeTarWithOneFile('model.ac', 'hello')
    const entries = listTarEntries(tar)
    expect(entries).toEqual([{ name: 'model.ac', size: 5 }])
  })

  it('lists from gzip-compressed tar', () => {
    const tar = makeTarWithOneFile('a.txt', 'x')
    const gz = zlib.gzipSync(tar)
    expect(listTarEntries(gz)).toEqual([{ name: 'a.txt', size: 1 }])
  })
})

describe('extractTarToMap', () => {
  it('returns empty map for invalid input', () => {
    expect([...extractTarToMap(Buffer.alloc(0)).entries()]).toEqual([])
    expect([...extractTarToMap(Buffer.from([0x1f, 0x8b, 1])).entries()]).toEqual([])
  })

  it('extracts file contents', () => {
    const tar = makeTarWithOneFile('readme.txt', 'abc')
    const m = extractTarToMap(tar)
    expect(m.get('readme.txt')?.toString('utf8')).toBe('abc')
  })

  it('returns empty map when tar header declares file larger than max entry size', () => {
    const header = Buffer.alloc(512, 0)
    Buffer.from('x.txt', 'utf8').copy(header, 0)
    const bogusSizeOct = (MAX_TAR_DECOMPRESSED_BYTES + 1).toString(8) + '\0'
    Buffer.from(bogusSizeOct.padStart(12, '0'), 'ascii').copy(header, 124)
    header[156] = 0x30
    const end = Buffer.alloc(1024, 0)
    const tar = Buffer.concat([header, end])
    expect(extractTarToMap(tar).size).toBe(0)
    expect(listTarEntries(tar)).toEqual([])
  })
})

describe('getTarFileContent', () => {
  it('returns null for missing name or buffer', () => {
    const tar = makeTarWithOneFile('only.txt', 'z')
    expect(getTarFileContent(tar, '')).toBeNull()
    expect(getTarFileContent(Buffer.alloc(0), 'only.txt')).toBeNull()
  })

  it('returns buffer for matching entry', () => {
    const tar = makeTarWithOneFile('nested/path.xml', '<x/>')
    const buf = getTarFileContent(tar, 'nested/path.xml')
    expect(buf?.toString('utf8')).toBe('<x/>')
  })
})
