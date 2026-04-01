import { describe, it, expect, afterEach } from 'vitest'
import { resolveGitSlug } from '../../scripts/resolve-git-slug.mjs'

describe('resolveGitSlug', () => {
  const saved = { ...process.env }

  afterEach(() => {
    for (const k of ['VITE_APP_GIT_SLUG', 'GIT_SLUG']) {
      if (saved[k] === undefined) delete process.env[k]
      else process.env[k] = saved[k]
    }
  })

  it('prefers VITE_APP_GIT_SLUG over GIT_SLUG', () => {
    process.env.VITE_APP_GIT_SLUG = '  vite-slug  '
    process.env.GIT_SLUG = 'git-slug'
    expect(resolveGitSlug()).toBe('vite-slug')
  })

  it('uses GIT_SLUG when VITE_APP_GIT_SLUG is unset', () => {
    delete process.env.VITE_APP_GIT_SLUG
    process.env.GIT_SLUG = 'from-git-env'
    expect(resolveGitSlug()).toBe('from-git-env')
  })

  it('returns a non-empty string when env overrides are cleared (git or dev)', () => {
    delete process.env.VITE_APP_GIT_SLUG
    delete process.env.GIT_SLUG
    const slug = resolveGitSlug()
    expect(typeof slug).toBe('string')
    expect(slug.length).toBeGreaterThan(0)
  })
})
