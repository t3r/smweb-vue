import { describe, it, expect } from 'vitest'
import { parseCsvLine, iterateCsvRecords } from '../../src/server/utils/csv.js'

describe('parseCsvLine', () => {
  it('splits simple comma fields', () => {
    expect(parseCsvLine('a,b,c')).toEqual(['a', 'b', 'c'])
  })

  it('handles quoted commas', () => {
    expect(parseCsvLine('"a,b",c')).toEqual(['a,b', 'c'])
  })

  it('handles escaped quotes', () => {
    expect(parseCsvLine('"say ""hi""",x')).toEqual(['say "hi"', 'x'])
  })
})

describe('iterateCsvRecords', () => {
  it('yields header and rows with unix newlines', () => {
    const text = 'a,b\n1,2\n3,4\n'
    const rows = [...iterateCsvRecords(text)]
    expect(rows).toEqual([
      ['a', 'b'],
      ['1', '2'],
      ['3', '4'],
    ])
  })

  it('handles CRLF', () => {
    const text = 'a,b\r\n1,2\r\n'
    const rows = [...iterateCsvRecords(text)]
    expect(rows).toEqual([
      ['a', 'b'],
      ['1', '2'],
    ])
  })
})
