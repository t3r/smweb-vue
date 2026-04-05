import { describe, it, expect, afterEach, vi } from 'vitest'

afterEach(() => {
  vi.unstubAllEnvs()
  vi.resetModules()
})

describe('getPositionRequestSubmitRequiredRole', () => {
  async function load() {
    const m = await import('../../src/server/config/positionRequestSubmitAuth.ts')
    return m.getPositionRequestSubmitRequiredRole
  }

  it('defaults to user when unset', async () => {
    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', '')
    const get = await load()
    expect(get()).toBe('user')
  })

  it('returns user when set to user', async () => {
    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', 'user')
    const get = await load()
    expect(get()).toBe('user')
  })

  it('returns none for anonymous aliases', async () => {
    for (const v of ['none', 'anonymous', 'off', 'NONE']) {
      vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', v)
      vi.resetModules()
      const get = await load()
      expect(get()).toBe('none')
      vi.unstubAllEnvs()
      vi.resetModules()
    }
  })

  it('returns reviewer, tester, or admin when set', async () => {
    for (const role of ['reviewer', 'tester', 'admin']) {
      vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', role)
      vi.resetModules()
      const get = await load()
      expect(get()).toBe(role)
      vi.unstubAllEnvs()
      vi.resetModules()
    }
  })

  it('falls back to user for invalid role', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    vi.stubEnv('POSITION_REQUEST_SUBMIT_ROLE', 'not-a-role')
    const get = await load()
    expect(get()).toBe('user')
    expect(warn).toHaveBeenCalled()
    warn.mockRestore()
  })
})
