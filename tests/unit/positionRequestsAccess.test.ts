import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('../../src/server/repositories/authorRepository.js', () => ({
  findAuthorsByEmails: vi.fn(),
}))

vi.mock('../../src/server/repositories/objectRepository.js', () => ({
  findModelAuthorIdsByObjectIds: vi.fn(),
}))

import * as authorRepo from '../../src/server/repositories/authorRepository.js'
import * as objectRepo from '../../src/server/repositories/objectRepository.js'
import {
  contentAuthorIdFromQueuedPayload,
  filterPendingQueueItemsForSession,
  isReviewerOrAbove,
  sessionMayAccessDecodedPendingRequest,
  sessionMayAccessPendingModelTarball,
} from '../../src/server/utils/positionRequestsAccess.js'

describe('positionRequestsAccess', () => {
  beforeEach(() => {
    vi.mocked(authorRepo.findAuthorsByEmails).mockResolvedValue(new Map())
    vi.mocked(objectRepo.findModelAuthorIdsByObjectIds).mockResolvedValue(new Map())
  })

  describe('sessionMayAccessPendingModelTarball', () => {
    it('denies without user', () => {
      expect(sessionMayAccessPendingModelTarball(undefined, 'MODEL_UPDATE')).toBe(false)
    })

    it('allows role user for MODEL_ADD and MODEL_UPDATE', () => {
      const u = { id: 20, email: 'x@y.com', role: 'user' as const }
      expect(sessionMayAccessPendingModelTarball(u, 'MODEL_UPDATE')).toBe(true)
      expect(sessionMayAccessPendingModelTarball(u, 'MODEL_ADD')).toBe(true)
    })

    it('denies role user for other request types', () => {
      const u = { id: 20, email: 'x@y.com', role: 'user' as const }
      expect(sessionMayAccessPendingModelTarball(u, 'OBJECT_UPDATE')).toBe(false)
    })

    it('allows reviewer for any type', () => {
      const u = { id: 1, role: 'reviewer' as const }
      expect(sessionMayAccessPendingModelTarball(u, 'OBJECT_DELETE')).toBe(true)
    })
  })

  describe('isReviewerOrAbove', () => {
    it('is true for reviewer, tester, and admin', () => {
      expect(isReviewerOrAbove('reviewer')).toBe(true)
      expect(isReviewerOrAbove('tester')).toBe(true)
      expect(isReviewerOrAbove('admin')).toBe(true)
    })

    it('is false for user and unknown', () => {
      expect(isReviewerOrAbove('user')).toBe(false)
      expect(isReviewerOrAbove(undefined)).toBe(false)
    })
  })

  describe('filterPendingQueueItemsForSession', () => {
    const rows = [
      { email: 'a@example.com', authorId: 1 },
      { email: 'b@example.com', authorId: 2 },
    ]

    it('returns no rows without a user', () => {
      expect(filterPendingQueueItemsForSession(rows, undefined)).toEqual([])
    })

    it('returns all rows for a reviewer', () => {
      expect(filterPendingQueueItemsForSession(rows, { id: 99, email: 'x@y.com', role: 'reviewer' })).toEqual(rows)
    })

    it('filters by session email (case-insensitive)', () => {
      const out = filterPendingQueueItemsForSession(rows, { id: 3, email: 'A@Example.com', role: 'user' })
      expect(out).toEqual([{ email: 'a@example.com', authorId: 1 }])
    })

    it('filters by author id when email differs', () => {
      const out = filterPendingQueueItemsForSession(rows, { id: 2, email: 'other@example.com', role: 'user' })
      expect(out).toEqual([{ email: 'b@example.com', authorId: 2 }])
    })

    it('includes row when catalogue author id is only on details.model.author (contact email ≠ session email)', () => {
      const items = [
        {
          type: 'MODEL_ADD',
          email: 'contact@submit.com',
          authorId: null,
          details: { model: { author: 7, name: 'M' } },
        },
      ]
      const out = filterPendingQueueItemsForSession(items, {
        id: 7,
        email: 'oauth-login@example.com',
        role: 'user',
      })
      expect(out).toEqual(items)
    })

    it('includes MODEL_UPDATE row when author id is on details root', () => {
      const items = [
        {
          type: 'MODEL_UPDATE',
          email: 'x@y.com',
          authorId: null,
          details: { author: 9, name: 'N' },
        },
      ]
      const out = filterPendingQueueItemsForSession(items, { id: 9, email: 'z@z.com', role: 'user' })
      expect(out).toEqual(items)
    })

    it('includes OBJECT_UPDATE when only derivedModelAuthorId matches session (legacy queue)', () => {
      const items = [
        {
          type: 'OBJECT_UPDATE',
          email: 'guest@anon.net',
          authorId: null,
          details: { objectId: 100, modelId: 5, derivedModelAuthorId: 20 },
        },
      ]
      const out = filterPendingQueueItemsForSession(items, {
        id: 20,
        email: 'login@example.com',
        role: 'user',
      })
      expect(out).toEqual(items)
    })
  })

  describe('contentAuthorIdFromQueuedPayload', () => {
    it('reads model.author first', () => {
      expect(contentAuthorIdFromQueuedPayload({ model: { author: 3 } })).toBe(3)
    })

    it('coerces model.author object id', () => {
      expect(contentAuthorIdFromQueuedPayload({ model: { author: { id: 11 } } })).toBe(11)
    })

    it('falls back to root author', () => {
      expect(contentAuthorIdFromQueuedPayload({ author: 4, name: 'x' })).toBe(4)
    })

    it('reads modifiedByAuthorId (MODEL_DELETE)', () => {
      expect(contentAuthorIdFromQueuedPayload({ modelId: 9, modifiedByAuthorId: 20 })).toBe(20)
    })

    it('reads submitterAuthorId (OBJECT_UPDATE / OBJECT_DELETE)', () => {
      expect(contentAuthorIdFromQueuedPayload({ objectId: 1, submitterAuthorId: 20 })).toBe(20)
    })

    it('reads derivedModelAuthorId after payload author fields', () => {
      expect(
        contentAuthorIdFromQueuedPayload({
          objectId: 1,
          derivedModelAuthorId: 20,
        }),
      ).toBe(20)
    })

    it('returns null for empty', () => {
      expect(contentAuthorIdFromQueuedPayload(null)).toBe(null)
      expect(contentAuthorIdFromQueuedPayload({})).toBe(null)
    })
  })

  describe('sessionMayAccessDecodedPendingRequest', () => {
    it('allows reviewers regardless of payload', async () => {
      const ok = await sessionMayAccessDecodedPendingRequest(
        { id: 1, role: 'reviewer' },
        { email: 'nope@x.com', content: {} },
      )
      expect(ok).toBe(true)
    })

    it('allows submitter when request email matches session email', async () => {
      const ok = await sessionMayAccessDecodedPendingRequest(
        { id: 5, email: 'Sub@Example.com', role: 'user' },
        { email: 'sub@example.com', content: {} },
      )
      expect(authorRepo.findAuthorsByEmails).not.toHaveBeenCalled()
      expect(ok).toBe(true)
    })

    it('allows when author resolved from submit email matches session author id', async () => {
      const m = new Map<string, { id: number; name: string | null }>()
      m.set('sub@example.com', { id: 7, name: 'S' })
      vi.mocked(authorRepo.findAuthorsByEmails).mockResolvedValueOnce(m)
      const ok = await sessionMayAccessDecodedPendingRequest(
        { id: 7, email: 'login@example.com', role: 'user' },
        { email: 'sub@example.com', content: {} },
      )
      expect(ok).toBe(true)
    })

    it('allows when content.author matches session id', async () => {
      const ok = await sessionMayAccessDecodedPendingRequest(
        { id: 42, email: 'x@y.com', role: 'user' },
        { email: 'other@z.com', content: { author: 42 } },
      )
      expect(ok).toBe(true)
    })

    it('allows when content.model.author matches session id', async () => {
      const ok = await sessionMayAccessDecodedPendingRequest(
        { id: 42, email: 'x@y.com', role: 'user' },
        { email: 'other@z.com', content: { model: { author: 42 } } },
      )
      expect(ok).toBe(true)
    })

    it('denies when nothing matches', async () => {
      const ok = await sessionMayAccessDecodedPendingRequest(
        { id: 1, email: 'a@b.com', role: 'user' },
        { email: 'c@d.com', content: { author: 99 } },
      )
      expect(ok).toBe(false)
    })

    it('allows OBJECT_UPDATE when session id matches catalogue model author for object', async () => {
      const m = new Map<number, number>()
      m.set(55, 20)
      vi.mocked(objectRepo.findModelAuthorIdsByObjectIds).mockResolvedValueOnce(m)
      const ok = await sessionMayAccessDecodedPendingRequest(
        { id: 20, email: 'x@y.com', role: 'user' },
        { email: 'other@z.com', type: 'OBJECT_UPDATE', content: { objectId: 55, modelId: 1 } },
      )
      expect(ok).toBe(true)
    })
  })
})
