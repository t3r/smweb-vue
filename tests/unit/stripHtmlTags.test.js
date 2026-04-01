import { describe, it, expect } from 'vitest'
import { stripHtmlTags } from '../../src/server/utils/stripHtmlTags.ts'

describe('stripHtmlTags', () => {
  it('removes simple tags', () => {
    expect(stripHtmlTags('hello <b>world</b>')).toBe('hello world')
    expect(stripHtmlTags('<p>x</p>')).toBe('x')
  })

  it('iterates until no nested tag pairs remain', () => {
    expect(stripHtmlTags('a <b><i>x</i></b> b')).toBe('a x b')
  })

  it('preserves text when no complete <...> tag (no closing angle)', () => {
    expect(stripHtmlTags('a < b')).toBe('a < b')
  })

  it('removes substring that matches <...> even in prose (limitation of regex strip)', () => {
    expect(stripHtmlTags('a < b and c > d')).toBe('a  d')
  })

  it('handles empty and no tags', () => {
    expect(stripHtmlTags('')).toBe('')
    expect(stripHtmlTags('plain')).toBe('plain')
  })
})
