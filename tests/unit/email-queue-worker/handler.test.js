import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

const sesSend = vi.fn().mockResolvedValue({})

vi.mock('@aws-sdk/client-ses', () => ({
  SESClient: vi.fn().mockImplementation(function MockSES() {
    return { send: sesSend }
  }),
  /** Real constructor: handler uses `new SendEmailCommand(params)`. */
  SendEmailCommand: function SendEmailCommand(input) {
    this.input = input
  },
}))

import {
  handler,
  getApiBaseUrl,
  withTemplateUrls,
  enrichAcceptedPayload,
  summarizePositionRequestCreatedLines,
  renderBody,
  renderDigestBody,
  renderSubject,
  partitionBatch,
  buildItemRow,
  isQueueMessage,
  resolveRecipients,
} from '../../../lambda/email-queue-worker/src/handler.mjs'

function msg(overrides) {
  return {
    eqId: 1,
    receiptHandle: 'rh-1',
    eventType: 'position_request.created',
    payload: {},
    attempts: 0,
    createdAt: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

describe('email-queue-worker handler', () => {
  beforeEach(() => {
    vi.stubEnv('API_BASE_URL', 'https://site.example')
    vi.stubEnv('EMAIL_QUEUE_BEARER_TOKEN', 'secret-token')
    vi.stubEnv('SES_FROM', 'noreply@example.com')
    vi.stubEnv('NOTIFY_REVIEWER_EMAILS', 'reviewer@example.com')
    vi.stubEnv('AWS_REGION', 'eu-central-1')
    delete process.env.QUEUE_BATCH_SIZE
    delete process.env.VISIBILITY_TIMEOUT_SEC
    sesSend.mockClear()
  })

  afterEach(() => {
    vi.unstubAllEnvs()
  })

  describe('getApiBaseUrl', () => {
    it('strips trailing slash', () => {
      vi.stubEnv('API_BASE_URL', 'https://api.test/')
      expect(getApiBaseUrl()).toBe('https://api.test')
    })

    it('returns empty when unset', () => {
      vi.stubEnv('API_BASE_URL', '')
      expect(getApiBaseUrl()).toBe('')
    })
  })

  describe('withTemplateUrls', () => {
    it('adds positionRequestsUrl when base set', () => {
      vi.stubEnv('API_BASE_URL', 'https://x.org')
      const o = withTemplateUrls({ a: 1 })
      expect(o.apiBaseUrl).toBe('https://x.org')
      expect(o.positionRequestsUrl).toBe('https://x.org/position-requests')
      expect(o.a).toBe(1)
    })

    it('leaves positionRequestsUrl empty without base', () => {
      vi.stubEnv('API_BASE_URL', '')
      const o = withTemplateUrls({})
      expect(o.positionRequestsUrl).toBe('')
    })
  })

  describe('enrichAcceptedPayload', () => {
    it('adds model and object links for MODEL_ADD', () => {
      vi.stubEnv('API_BASE_URL', 'https://app.example')
      const out = enrichAcceptedPayload({
        requestType: 'MODEL_ADD',
        executeResult: { modelId: 10, objectId: 20 },
      })
      expect(out.hasDetailLinks).toBe(true)
      expect(out.detailLinks).toEqual([
        { label: 'Model #10', href: 'https://app.example/models/10' },
        { label: 'Object #20', href: 'https://app.example/objects/20' },
      ])
    })

    it('adds object links for OBJECTS_ADD', () => {
      vi.stubEnv('API_BASE_URL', 'https://app.example')
      const out = enrichAcceptedPayload({
        requestType: 'OBJECTS_ADD',
        executeResult: { objectIds: [5, 6] },
      })
      expect(out.detailLinks).toHaveLength(2)
      expect(out.detailLinks[0].href).toBe('https://app.example/objects/5')
      expect(out.detailLinks[1].href).toBe('https://app.example/objects/6')
    })

    it('skips invalid ids', () => {
      vi.stubEnv('API_BASE_URL', 'https://app.example')
      const out = enrichAcceptedPayload({
        requestType: 'MODEL_ADD',
        executeResult: { modelId: 0, objectId: -1 },
      })
      expect(out.hasDetailLinks).toBe(false)
      expect(out.detailLinks).toEqual([])
    })

    it('no links without API_BASE_URL', () => {
      vi.stubEnv('API_BASE_URL', '')
      const out = enrichAcceptedPayload({
        requestType: 'MODEL_ADD',
        executeResult: { modelId: 1, objectId: 2 },
      })
      expect(out.hasDetailLinks).toBe(false)
    })

    it('no links for other request types', () => {
      vi.stubEnv('API_BASE_URL', 'https://app.example')
      const out = enrichAcceptedPayload({
        requestType: 'MODEL_UPDATE',
        executeResult: { modelId: 99 },
      })
      expect(out.detailLinks).toEqual([])
    })
  })

  describe('isQueueMessage', () => {
    it('accepts valid message shape', () => {
      expect(isQueueMessage(msg({}))).toBe(true)
    })

    it('rejects missing fields', () => {
      expect(isQueueMessage(null)).toBe(false)
      expect(isQueueMessage({ eqId: 1 })).toBe(false)
      expect(isQueueMessage({ eqId: 1, receiptHandle: 'x' })).toBe(false)
    })
  })

  describe('buildItemRow', () => {
    it('merges payload and row index', () => {
      const m = msg({
        eqId: 7,
        payload: { note: 'abc', requestType: 'X' },
      })
      const row = buildItemRow(m, 3)
      expect(row.row).toBe(3)
      expect(row.eqId).toBe(7)
      expect(row.note).toBe('abc')
      expect(row.requestType).toBe('X')
    })
  })

  describe('partitionBatch', () => {
    it('groups all created into one group', () => {
      const a = msg({ eqId: 1, eventType: 'position_request.created' })
      const b = msg({ eqId: 2, eventType: 'position_request.created' })
      const { groups, unknownType, orphanSubmitter } = partitionBatch([a, b])
      expect(groups).toHaveLength(1)
      expect(groups[0].eventType).toBe('position_request.created')
      expect(groups[0].messages).toHaveLength(2)
      expect(unknownType).toEqual([])
      expect(orphanSubmitter).toEqual([])
    })

    it('groups accepted by submitter email', () => {
      const a = msg({
        eqId: 1,
        eventType: 'position_request.accepted',
        payload: { submitterEmail: 'a@x.com' },
      })
      const b = msg({
        eqId: 2,
        eventType: 'position_request.accepted',
        payload: { submitterEmail: 'b@x.com' },
      })
      const c = msg({
        eqId: 3,
        eventType: 'position_request.accepted',
        payload: { submitterEmail: 'a@x.com' },
      })
      const { groups } = partitionBatch([a, b, c])
      const accepted = groups.filter((g) => g.eventType === 'position_request.accepted')
      expect(accepted).toHaveLength(2)
      const sizes = accepted.map((g) => g.messages.length).sort()
      expect(sizes).toEqual([1, 2])
    })

    it('normalizes submitter key case', () => {
      const a = msg({
        eqId: 1,
        eventType: 'position_request.rejected',
        payload: { submitterEmail: 'User@Example.COM' },
      })
      const b = msg({
        eqId: 2,
        eventType: 'position_request.rejected',
        payload: { submitterEmail: 'user@example.com' },
      })
      const { groups } = partitionBatch([a, b])
      const rej = groups.find((g) => g.eventType === 'position_request.rejected')
      expect(rej.messages).toHaveLength(2)
    })

    it('sends accepted without submitter to orphans', () => {
      const m = msg({
        eqId: 9,
        eventType: 'position_request.accepted',
        payload: {},
      })
      const { orphanSubmitter, groups } = partitionBatch([m])
      expect(orphanSubmitter).toHaveLength(1)
      expect(groups.some((g) => g.eventType === 'position_request.accepted')).toBe(false)
    })

    it('puts unknown event types aside', () => {
      const m = msg({ eqId: 1, eventType: 'custom.event' })
      const { unknownType, groups } = partitionBatch([m])
      expect(unknownType).toHaveLength(1)
      expect(groups).toEqual([])
    })

    it('skips invalid messages', () => {
      const { groups, unknownType } = partitionBatch([{ foo: 1 }])
      expect(groups).toEqual([])
      expect(unknownType).toEqual([])
    })
  })

  describe('resolveRecipients', () => {
    it('returns reviewers for created', () => {
      vi.stubEnv('NOTIFY_REVIEWER_EMAILS', ' r1@x.com , r2@x.com ')
      const r = resolveRecipients('position_request.created', {})
      expect(r.to).toEqual(['r1@x.com', 'r2@x.com'])
    })

    it('throws if no reviewers for created', () => {
      vi.stubEnv('NOTIFY_REVIEWER_EMAILS', '')
      expect(() => resolveRecipients('position_request.created', {})).toThrow(
        /NOTIFY_REVIEWER_EMAILS/
      )
    })

    it('returns submitter for accepted', () => {
      const r = resolveRecipients('position_request.accepted', { submitterEmail: ' u@y.org ' })
      expect(r.to).toEqual(['u@y.org'])
    })

    it('throws if submitter missing', () => {
      expect(() => resolveRecipients('position_request.accepted', {})).toThrow(/submitterEmail/)
    })

    it('returns recipientEmail for account_merge.confirm', () => {
      const r = resolveRecipients('account_merge.confirm', { recipientEmail: ' owner@target.org ' })
      expect(r.to).toEqual(['owner@target.org'])
    })

    it('throws if recipientEmail missing for account_merge.confirm', () => {
      expect(() => resolveRecipients('account_merge.confirm', {})).toThrow(/recipientEmail/)
    })
  })

  describe('renderSubject', () => {
    it('renders digest subject', () => {
      const s = renderSubject('[FG] {{count}} items', { count: 3 })
      expect(s).toBe('[FG] 3 items')
    })
  })

  describe('summarizePositionRequestCreatedLines', () => {
    it('summarizes MODEL_ADD with name and description', () => {
      const lines = summarizePositionRequestCreatedLines({
        requestType: 'MODEL_ADD',
        comment: 'Please review',
        contentOverview: {
          model: { name: 'Hangar A', description: 'Low-poly hangar', filename: 'hangar.ac' },
          object: { latitude: 52.1, longitude: 13.2 },
        },
      })
      expect(lines.some((l) => l.label === 'Submitter comment' && l.value === 'Please review')).toBe(true)
      expect(lines.some((l) => l.label === 'Model name' && l.value === 'Hangar A')).toBe(true)
      expect(lines.some((l) => l.label === 'Description' && l.value.includes('Low-poly'))).toBe(true)
    })
  })

  describe('renderBody (templates on disk)', () => {
    it('renders account_merge.confirm with link', () => {
      vi.stubEnv('API_BASE_URL', 'https://catalog.example')
      const { html, text } = renderBody('account_merge.confirm', {
        recipientEmail: 't@y.org',
        link: 'https://catalog.example/merge/confirm?token=a&id=b',
        sourceName: 'Alice',
        targetName: 'Bob',
        sourceAuthorId: 10,
        targetAuthorId: 20,
        expiresAt: '2099-01-01T00:00:00.000Z',
      })
      expect(html).toContain('https://catalog.example/merge/confirm')
      expect(html).toContain('Alice')
      expect(text).toContain('merge/confirm')
    })

    it('renders created mail with reviewer link and thank you', () => {
      vi.stubEnv('API_BASE_URL', 'https://catalog.example')
      const { html, text } = renderBody('position_request.created', {
        requestId: 42,
        requestType: 'OBJECTS_ADD',
        contentOverview: [{ modelId: 3, latitude: 1, longitude: 2, description: 'x' }],
        comment: 'c',
      })
      expect(html).toContain('https://catalog.example/position-requests')
      expect(html).toContain('Thank you for contributing to the FlightGear scenery community!')
      expect(html).toContain('Objects count')
      expect(text).toContain('Open the position requests page: https://catalog.example/position-requests')
      expect(text).toContain('Thank you for contributing')
    })

    it('renders accepted mail with catalogue links for MODEL_ADD', () => {
      vi.stubEnv('API_BASE_URL', 'https://catalog.example')
      const { html, text } = renderBody('position_request.accepted', {
        requestType: 'MODEL_ADD',
        submitterEmail: 'u@x.com',
        comment: 'Thanks',
        contentOverview: {
          model: { name: 'Hangar A', description: 'Low-poly hangar.' },
        },
        executeResult: { modelId: 5, objectId: 6 },
      })
      expect(html).toContain('https://catalog.example/models/5')
      expect(html).toContain('https://catalog.example/objects/6')
      expect(html).toContain('View in the catalogue')
      expect(html).toContain('Model name')
      expect(html).toContain('Hangar A')
      expect(html).toContain('Submitter comment')
      expect(html).not.toContain('<code>')
      expect(text).toContain('https://catalog.example/models/5')
      expect(text).toContain('Hangar A')
    })
  })

  describe('renderDigestBody', () => {
    it('renders rejected digest for two items', () => {
      const items = [
        buildItemRow(
          msg({
            eqId: 1,
            payload: {
              requestType: 'OBJECT_UPDATE',
              submitterEmail: 'u@x.com',
              reason: 'no',
              comment: 'Please fix',
              contentOverview: { objectId: 9, description: 'Tower' },
            },
          }),
          1
        ),
        buildItemRow(
          msg({
            eqId: 2,
            payload: {
              requestType: 'OBJECT_UPDATE',
              submitterEmail: 'u@x.com',
              reason: 'nope',
              contentOverview: { objectId: 10, description: 'Sign' },
            },
          }),
          2
        ),
      ]
      const { html, text } = renderDigestBody('position_request.rejected', items)
      expect(html).toContain('Position requests rejected (2)')
      expect(html).toContain('#1')
      expect(html).toContain('Object ID')
      expect(html).not.toContain('<code>')
      expect(text).toContain('Thank you for contributing')
    })

    it('enriches each accepted row with detail links', () => {
      vi.stubEnv('API_BASE_URL', 'https://catalog.example')
      const items = [
        buildItemRow(
          msg({
            payload: {
              requestType: 'OBJECTS_ADD',
              submitterEmail: 'u@x.com',
              executeResult: { objectIds: [1, 2] },
            },
          }),
          1
        ),
      ]
      const { html } = renderDigestBody('position_request.accepted', items)
      expect(html).toContain('/objects/1')
      expect(html).toContain('/objects/2')
    })
  })

  describe('handler() integration', () => {
    it('throws without API_BASE_URL or token', async () => {
      vi.stubEnv('API_BASE_URL', '')
      await expect(handler({})).rejects.toThrow(/API_BASE_URL/)
      vi.stubEnv('API_BASE_URL', 'https://x.com')
      vi.stubEnv('EMAIL_QUEUE_BEARER_TOKEN', '')
      await expect(handler({})).rejects.toThrow(/EMAIL_QUEUE_BEARER_TOKEN/)
    })

    it('returns zeros for empty batch', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ messages: [] }),
      })
      const out = await handler({})
      expect(out).toEqual({ received: 0, sent: 0, failed: 0, errors: [] })
      expect(fetch).toHaveBeenCalledWith(
        'https://site.example/api/email-queue/receive',
        expect.objectContaining({ method: 'POST' })
      )
    })

    it('processes two created messages in one SES send and two deletes', async () => {
      const m1 = msg({ eqId: 10, receiptHandle: 'h10' })
      const m2 = msg({ eqId: 11, receiptHandle: 'h11' })
      global.fetch = vi.fn(async (url, init) => {
        const u = String(url)
        if (u.endsWith('/receive')) {
          return { ok: true, json: async () => ({ messages: [m1, m2] }) }
        }
        if (u.endsWith('/delete')) {
          const body = JSON.parse(init.body)
          expect(body).toHaveProperty('eqId')
          expect(body).toHaveProperty('receiptHandle')
          return { ok: true, text: async () => '' }
        }
        throw new Error(`unexpected fetch ${u}`)
      })
      const out = await handler({})
      expect(out.received).toBe(2)
      expect(out.sent).toBe(2)
      expect(out.failed).toBe(0)
      expect(sesSend).toHaveBeenCalledTimes(1)
      const delCalls = fetch.mock.calls.filter((c) => String(c[0]).endsWith('/delete'))
      expect(delCalls).toHaveLength(2)
    })

    it('counts orphan accepted without submitter as failed', async () => {
      const bad = msg({
        eqId: 99,
        eventType: 'position_request.accepted',
        payload: {},
      })
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ messages: [bad] }),
      })
      const out = await handler({})
      expect(out.received).toBe(1)
      expect(out.sent).toBe(0)
      expect(out.failed).toBe(1)
      expect(out.errors[0].message).toMatch(/submitterEmail/)
      expect(sesSend).not.toHaveBeenCalled()
    })

    it('fails unknown event type in legacy path', async () => {
      const weird = msg({ eqId: 3, eventType: 'totally.unknown' })
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ messages: [weird] }),
      })
      const out = await handler({})
      expect(out.failed).toBe(1)
      expect(out.sent).toBe(0)
      expect(sesSend).not.toHaveBeenCalled()
    })

    it('propagates receive HTTP error', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 503,
        text: async () => 'nope',
      })
      await expect(handler({})).rejects.toThrow(/receive failed 503/)
    })
  })
})
