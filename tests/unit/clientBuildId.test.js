import { describe, it, expect, afterEach } from 'vitest'
import { getClientBuildId } from '../../src/server/utils/clientBuildId.ts'

describe('getClientBuildId', () => {
  const saved = { ...process.env }

  afterEach(() => {
    for (const k of ['VITE_APP_GIT_SLUG', 'GIT_SLUG']) {
      if (saved[k] === undefined) delete process.env[k]
      else process.env[k] = saved[k]
    }
  })

  it('prefers VITE_APP_GIT_SLUG', () => {
    process.env.VITE_APP_GIT_SLUG = 'build-from-vite'
    delete process.env.GIT_SLUG
    expect(getClientBuildId()).toBe('build-from-vite')
  })

  it('falls back to GIT_SLUG', () => {
    delete process.env.VITE_APP_GIT_SLUG
    process.env.GIT_SLUG = 'build-from-git'
    expect(getClientBuildId()).toBe('build-from-git')
  })

  it('returns a non-empty id when env vars are unset (VERSION/git/dev)', () => {
    delete process.env.VITE_APP_GIT_SLUG
    delete process.env.GIT_SLUG
    const id = getClientBuildId()
    expect(typeof id).toBe('string')
    expect(id.length).toBeGreaterThan(0)
  })
})
