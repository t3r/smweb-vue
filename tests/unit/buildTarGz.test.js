import { describe, it, expect } from 'vitest'
import { buildTarGz } from '../../src/server/utils/buildTarGz.ts'
import { extractTarToMap } from '../../src/server/utils/tarList.ts'

describe('buildTarGz', () => {
  it('produces gzip that round-trips through extractTarToMap', async () => {
    const gz = await buildTarGz([
      { name: 'a/hello.txt', buffer: Buffer.from('hello', 'utf8') },
      { name: 'b/second.txt', buffer: Buffer.from('x', 'utf8') },
    ])
    expect(gz[0]).toBe(0x1f)
    expect(gz[1]).toBe(0x8b)
    const map = extractTarToMap(gz)
    expect(map.get('a/hello.txt')?.toString('utf8')).toBe('hello')
    expect(map.get('b/second.txt')?.toString('utf8')).toBe('x')
  })
})
