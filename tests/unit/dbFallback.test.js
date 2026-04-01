import { describe, it, expect, vi, afterEach } from 'vitest'
import {
  isDbConnectionError,
  inTestWithoutDb,
  logDbError,
  CLIENT_ERROR_MESSAGE,
} from '../../src/server/utils/dbFallback.ts'

describe('CLIENT_ERROR_MESSAGE', () => {
  it('is a generic string', () => {
    expect(CLIENT_ERROR_MESSAGE).toBe('An error occurred')
  })
})

describe('isDbConnectionError', () => {
  it('returns false for null/undefined', () => {
    expect(isDbConnectionError(null)).toBe(false)
    expect(isDbConnectionError(undefined)).toBe(false)
  })

  it('detects connection error codes', () => {
    expect(isDbConnectionError({ code: 'ECONNREFUSED' })).toBe(true)
    expect(isDbConnectionError({ code: 'ENOTFOUND' })).toBe(true)
    expect(isDbConnectionError({ code: 'ETIMEDOUT' })).toBe(true)
    expect(isDbConnectionError({ code: 'ECONNRESET' })).toBe(true)
  })

  it('detects Sequelize connection errors', () => {
    expect(isDbConnectionError({ name: 'SequelizeConnectionError' })).toBe(true)
    expect(isDbConnectionError({ name: 'SequelizeConnectionRefusedError' })).toBe(true)
    expect(isDbConnectionError({ name: 'SequelizeTimeoutError' })).toBe(true)
  })

  it('detects connect/relation/auth messages', () => {
    expect(isDbConnectionError({ message: 'connect ECONNREFUSED 127.0.0.1:5432' })).toBe(true)
    expect(isDbConnectionError({ message: 'relation "foo" does not exist' })).toBe(true)
    expect(isDbConnectionError({ message: 'password authentication failed' })).toBe(true)
    expect(isDbConnectionError({ message: 'Query timeout' })).toBe(true)
  })

  it('returns false for unrelated errors', () => {
    expect(isDbConnectionError({ code: 'EINVAL', message: 'bad arg' })).toBe(false)
    expect(isDbConnectionError(new Error('validation failed'))).toBe(false)
  })
})

describe('inTestWithoutDb', () => {
  it('is true in test env when error looks like DB failure', () => {
    expect(process.env.NODE_ENV).toBe('test')
    expect(inTestWithoutDb({ code: 'ECONNREFUSED' })).toBe(true)
  })

  it('is false when err is null', () => {
    expect(inTestWithoutDb(null)).toBe(false)
  })
})

describe('logDbError', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('logs name, code, and message', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
    logDbError({ name: 'SequelizeError', code: '42P01', message: 'missing table' }, 'GET /x')
    expect(spy).toHaveBeenCalledWith(expect.stringMatching(/\[db\] \[GET \/x\].*SequelizeError.*42P01.*missing table/))
  })

  it('no-ops for falsy err', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
    logDbError(null, 'ctx')
    expect(spy).not.toHaveBeenCalled()
  })
})
