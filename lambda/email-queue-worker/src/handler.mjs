/**
 * EventBridge-scheduled Lambda: pull from FlightGear scenemodels email queue API,
 * render HTML + plain-text bodies with Handlebars, send both parts via Amazon SES,
 * DELETE queue rows only after SES accepts the send.
 *
 * Batching: one SES message per logical group from each receive() batch:
 * — all position_request.created → one digest to reviewers;
 * — position_request.accepted / .rejected → one digest per submitter email (same type).
 * Unknown event types are still sent one mail per queue row (legacy templates).
 *
 * Env vars:
 *   API_BASE_URL              Public site/API base (no trailing slash); used for reviewer links
 *                             to {API_BASE_URL}/position-requests and for queue API calls
 *   EMAIL_QUEUE_BEARER_TOKEN  same as server EMAIL_QUEUE_BEARER_TOKEN
 *   SES_FROM                  verified From address in SES
 *   NOTIFY_REVIEWER_EMAILS    comma-separated BCC/To for position_request.created (reviewers)
 *   AWS_REGION                set automatically by Lambda
 *
 * Optional:
 *   QUEUE_BATCH_SIZE           default 10
 *   VISIBILITY_TIMEOUT_SEC    default 900 (15 min; allow time for SES + retries)
 */

import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses'
import Handlebars from 'handlebars'

Handlebars.registerHelper('json', (value) => {
  try {
    return JSON.stringify(value ?? null, null, 2)
  } catch {
    return String(value)
  }
})

const __dirname = dirname(fileURLToPath(import.meta.url))
const TEMPLATE_DIR = join(__dirname, '..', 'templates')

/** Normalized API / public site base (no trailing slash). */
function getApiBaseUrl() {
  return (process.env.API_BASE_URL || '').replace(/\/$/, '')
}

/** Context fields shared by all HTML templates (reviewer templates use positionRequestsUrl). */
function withTemplateUrls(data) {
  const base = getApiBaseUrl()
  return {
    ...data,
    apiBaseUrl: base,
    positionRequestsUrl: base ? `${base}/position-requests` : '',
  }
}

/**
 * Catalogue links for accepted "add" requests (MODEL_ADD, OBJECTS_ADD).
 * @param {Record<string, unknown>} data
 * @returns {Record<string, unknown> & { detailLinks: { label: string; href: string }[]; hasDetailLinks: boolean }}
 */
function enrichAcceptedPayload(data) {
  const base = getApiBaseUrl()
  /** @type {{ label: string; href: string }[]} */
  const detailLinks = []
  if (base) {
    const rt = typeof data.requestType === 'string' ? data.requestType : ''
    const erRaw = data.executeResult
    const er =
      erRaw != null && typeof erRaw === 'object' && !Array.isArray(erRaw)
        ? /** @type {Record<string, unknown>} */ (erRaw)
        : {}
    if (rt === 'MODEL_ADD') {
      const mid = Number(er.modelId)
      const oid = Number(er.objectId)
      if (Number.isInteger(mid) && mid > 0) {
        detailLinks.push({ label: `Model #${mid}`, href: `${base}/models/${mid}` })
      }
      if (Number.isInteger(oid) && oid > 0) {
        detailLinks.push({ label: `Object #${oid}`, href: `${base}/objects/${oid}` })
      }
    } else if (rt === 'OBJECTS_ADD' && Array.isArray(er.objectIds)) {
      for (const raw of er.objectIds) {
        const id = Number(raw)
        if (Number.isInteger(id) && id > 0) {
          detailLinks.push({ label: `Object #${id}`, href: `${base}/objects/${id}` })
        }
      }
    }
  }
  return {
    ...data,
    detailLinks,
    hasDetailLinks: detailLinks.length > 0,
  }
}

/**
 * Human-readable lines for reviewer "created" emails (HTML-escaped by Handlebars {{}}).
 * @param {Record<string, unknown>} item
 * @returns {{ label: string; value: string }[]}
 */
function summarizePositionRequestCreatedLines(item) {
  /** @type {{ label: string; value: string }[]} */
  const lines = []
  const str = (v) => (v == null ? '' : String(v).trim())
  const comment = str(item.comment)
  if (comment) lines.push({ label: 'Submitter comment', value: comment.slice(0, 500) })

  const rt = typeof item.requestType === 'string' ? item.requestType : ''
  const raw = item.contentOverview
  const o =
    raw != null && typeof raw === 'object' && !Array.isArray(raw) ? /** @type {Record<string, unknown>} */ (raw) : null
  const arr = Array.isArray(raw) ? raw : null

  switch (rt) {
    case 'MODEL_ADD': {
      const m =
        o?.model != null && typeof o.model === 'object' && !Array.isArray(o.model)
          ? /** @type {Record<string, unknown>} */ (o.model)
          : null
      const ob =
        o?.object != null && typeof o.object === 'object' && !Array.isArray(o.object)
          ? /** @type {Record<string, unknown>} */ (o.object)
          : null
      const au =
        o?.author != null && typeof o.author === 'object' && !Array.isArray(o.author)
          ? /** @type {Record<string, unknown>} */ (o.author)
          : null
      if (m) {
        if (str(m.name)) lines.push({ label: 'Model name', value: str(m.name) })
        if (str(m.description)) lines.push({ label: 'Description', value: str(m.description).slice(0, 400) })
        if (str(m.filename)) lines.push({ label: 'Filename', value: str(m.filename) })
      }
      if (ob && (ob.latitude != null || ob.longitude != null)) {
        lines.push({ label: 'Placement (lat, lon)', value: `${str(ob.latitude)}, ${str(ob.longitude)}` })
      }
      if (au) {
        const nm = str(au.name)
        const em = str(au.email)
        if (nm || em) lines.push({ label: 'New author', value: [nm, em].filter(Boolean).join(' — ').slice(0, 200) })
      }
      break
    }
    case 'MODEL_UPDATE': {
      if (o) {
        const mid = o.modelid ?? o.modelId
        if (mid != null && str(mid)) lines.push({ label: 'Model ID', value: str(mid) })
        if (str(o.name)) lines.push({ label: 'Model name', value: str(o.name) })
        if (str(o.description)) lines.push({ label: 'Description', value: str(o.description).slice(0, 400) })
        if (str(o.filename)) lines.push({ label: 'Filename', value: str(o.filename) })
      }
      break
    }
    case 'MODEL_DELETE': {
      if (o?.modelId != null && str(o.modelId)) lines.push({ label: 'Model ID', value: str(o.modelId) })
      break
    }
    case 'OBJECT_DELETE': {
      if (o?.objId != null && str(o.objId)) lines.push({ label: 'Object ID', value: str(o.objId) })
      break
    }
    case 'OBJECT_UPDATE': {
      if (o?.objectId != null && str(o.objectId)) lines.push({ label: 'Object ID', value: str(o.objectId) })
      if (o?.modelId != null && str(o.modelId)) lines.push({ label: 'Model ID', value: str(o.modelId) })
      if (str(o.description)) lines.push({ label: 'Description', value: str(o.description).slice(0, 200) })
      if (o?.longitude != null && o?.latitude != null) {
        lines.push({ label: 'Position (lat, lon)', value: `${str(o.latitude)}, ${str(o.longitude)}` })
      }
      break
    }
    case 'OBJECTS_ADD': {
      if (arr?.length) {
        lines.push({ label: 'Objects count', value: String(arr.length) })
        const first = arr[0]
        if (first && typeof first === 'object') {
          const f = /** @type {Record<string, unknown>} */ (first)
          if (str(f.description)) lines.push({ label: 'First object description', value: str(f.description).slice(0, 120) })
          if (f.modelId != null && str(f.modelId)) lines.push({ label: 'First object model ID', value: str(f.modelId) })
          if (f.latitude != null && f.longitude != null) {
            lines.push({ label: 'First object position (lat, lon)', value: `${str(f.latitude)}, ${str(f.longitude)}` })
          }
        }
        if (arr.length > 1) {
          lines.push({ label: 'Note', value: `${arr.length - 1} further object(s) in this request` })
        }
      }
      break
    }
    default:
      break
  }

  if (lines.length === 0) {
    lines.push({ label: 'Details', value: 'No structured summary recorded for this request.' })
  }
  return lines
}

/** @type {Map<string, Handlebars.TemplateDelegate>} */
const compiled = new Map()

function compileTemplate(name) {
  if (compiled.has(name)) return compiled.get(name)
  const path = join(TEMPLATE_DIR, `${name}.hbs`)
  const src = readFileSync(path, 'utf8')
  const tpl = Handlebars.compile(src)
  compiled.set(name, tpl)
  return tpl
}

function renderBody(eventType, data) {
  let ctx = withTemplateUrls(data)
  if (eventType === 'account_merge.confirm') {
    ctx = { ...ctx }
  }
  if (eventType === 'position_request.created') {
    ctx = {
      ...ctx,
      summaryLines: summarizePositionRequestCreatedLines(ctx),
    }
  }
  if (eventType === 'position_request.accepted') {
    ctx = enrichAcceptedPayload({
      ...ctx,
      summaryLines: summarizePositionRequestCreatedLines(ctx),
    })
  }
  if (eventType === 'position_request.rejected') {
    ctx = {
      ...ctx,
      summaryLines: summarizePositionRequestCreatedLines(ctx),
    }
  }
  const htmlTpl = compileTemplate(`${eventType}.html`)
  const textTpl = compileTemplate(`${eventType}.txt`)
  return {
    html: htmlTpl(ctx),
    text: textTpl(ctx),
  }
}

/** One email listing multiple queue items (same event type + recipient group). */
function renderDigestBody(eventType, items) {
  let rows = items
  if (eventType === 'position_request.accepted') {
    rows = items.map((row) =>
      enrichAcceptedPayload({
        ...row,
        summaryLines: summarizePositionRequestCreatedLines(row),
      })
    )
  } else if (eventType === 'position_request.rejected') {
    rows = items.map((row) => ({
      ...row,
      summaryLines: summarizePositionRequestCreatedLines(row),
    }))
  } else if (eventType === 'position_request.created') {
    rows = items.map((row) => ({
      ...row,
      summaryLines: summarizePositionRequestCreatedLines(row),
    }))
  }
  const ctx = withTemplateUrls({ items: rows, count: rows.length })
  const htmlTpl = compileTemplate(`${eventType}.digest.html`)
  const textTpl = compileTemplate(`${eventType}.digest.txt`)
  return {
    html: htmlTpl(ctx),
    text: textTpl(ctx),
  }
}

function renderSubject(template, data) {
  return Handlebars.compile(template)(data)
}

const SUBJECT_DIGEST_TEMPLATES = {
  'position_request.created': '[FG Scenemodels] {{count}} new position request(s)',
  'position_request.accepted': '[FG Scenemodels] {{count}} position request(s) accepted',
  'position_request.rejected': '[FG Scenemodels] {{count}} position request(s) rejected',
}

/** Legacy single-row subject (unknown event types only). */
const SUBJECT_TEMPLATES = {
  'position_request.created': '[FG Scenemodels] New position request #{{requestId}} ({{requestType}})',
  'position_request.accepted': '[FG Scenemodels] Your request was accepted ({{requestType}})',
  'position_request.rejected': '[FG Scenemodels] Your request was rejected ({{requestType}})',
  'account_merge.confirm': '[FG Scenemodels] Verify account merge ({{sourceName}} → {{targetName}})',
}

const DIGEST_EVENT_TYPES = new Set(Object.keys(SUBJECT_DIGEST_TEMPLATES))

/**
 * @param {unknown} msg
 * @returns {msg is { eqId: number, receiptHandle: string, eventType: string, payload?: unknown, attempts?: number, createdAt?: string }}
 */
function isQueueMessage(msg) {
  return (
    msg != null &&
    typeof msg === 'object' &&
    typeof msg.eqId === 'number' &&
    typeof msg.receiptHandle === 'string' &&
    typeof msg.eventType === 'string'
  )
}

function buildItemRow(msg, row) {
  const payload = msg.payload && typeof msg.payload === 'object' ? msg.payload : {}
  return {
    ...payload,
    row,
    eqId: msg.eqId,
    attempts: msg.attempts,
    createdAt: msg.createdAt,
  }
}

/**
 * Split a receive() batch into digest groups + leftovers.
 * @returns {{ groups: { eventType: string, messages: unknown[] }[], unknownType: unknown[], orphanSubmitter: unknown[] }}
 */
function partitionBatch(messages) {
  /** @type {Map<string, unknown[]>} */
  const submitterGroups = new Map()
  /** @type {unknown[]} */
  const created = []
  /** @type {unknown[]} */
  const unknownType = []
  /** @type {unknown[]} */
  const orphanSubmitter = []

  for (const msg of messages) {
    if (!isQueueMessage(msg)) continue
    const t = msg.eventType
    if (!DIGEST_EVENT_TYPES.has(t)) {
      unknownType.push(msg)
      continue
    }
    if (t === 'position_request.created') {
      created.push(msg)
      continue
    }
    const payload = msg.payload && typeof msg.payload === 'object' ? msg.payload : {}
    const email = typeof payload.submitterEmail === 'string' ? payload.submitterEmail.trim() : ''
    if (!email) {
      orphanSubmitter.push(msg)
      continue
    }
    const key = `${t}\t${email.toLowerCase()}`
    if (!submitterGroups.has(key)) submitterGroups.set(key, [])
    submitterGroups.get(key).push(msg)
  }

  /** @type {{ eventType: string, messages: unknown[] }[]} */
  const groups = []
  if (created.length) groups.push({ eventType: 'position_request.created', messages: created })
  for (const [, msgs] of submitterGroups) {
    if (msgs.length) groups.push({ eventType: msgs[0].eventType, messages: msgs })
  }
  return { groups, unknownType, orphanSubmitter }
}

/**
 * @param {string} eventType
 * @param {Record<string, unknown>} payload
 * @returns {{ to: string[], cc?: string[] }}
 */
function resolveRecipients(eventType, payload) {
  const reviewers = (process.env.NOTIFY_REVIEWER_EMAILS || '')
    .split(',')
    .map((e) => e.trim())
    .filter(Boolean)

  if (eventType === 'position_request.created') {
    if (reviewers.length === 0) {
      throw new Error('NOTIFY_REVIEWER_EMAILS must be set for position_request.created')
    }
    return { to: reviewers }
  }

  if (eventType === 'account_merge.confirm') {
    const to = typeof payload.recipientEmail === 'string' ? payload.recipientEmail.trim() : ''
    if (!to) {
      throw new Error('recipientEmail missing in payload')
    }
    return { to: [to] }
  }

  const submitter = typeof payload.submitterEmail === 'string' ? payload.submitterEmail.trim() : ''
  if (!submitter) {
    throw new Error('submitterEmail missing in payload')
  }
  return { to: [submitter] }
}

async function apiReceive() {
  const base = (process.env.API_BASE_URL || '').replace(/\/$/, '')
  const token = process.env.EMAIL_QUEUE_BEARER_TOKEN || ''
  const batchSize = Math.min(50, Math.max(1, Number(process.env.QUEUE_BATCH_SIZE) || 10))
  const visibilityTimeoutSeconds = Math.min(
    86400,
    Math.max(30, Number(process.env.VISIBILITY_TIMEOUT_SEC) || 900)
  )

  const res = await fetch(`${base}/api/email-queue/receive`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ batchSize, visibilityTimeoutSeconds }),
  })

  if (!res.ok) {
    const body = await res.text()
    throw new Error(`receive failed ${res.status}: ${body}`)
  }

  const json = await res.json()
  return json.messages || []
}

/**
 * @param {number} eqId
 * @param {string} receiptHandle
 */
async function apiDelete(eqId, receiptHandle) {
  const base = (process.env.API_BASE_URL || '').replace(/\/$/, '')
  const token = process.env.EMAIL_QUEUE_BEARER_TOKEN || ''

  const res = await fetch(`${base}/api/email-queue/delete`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ eqId, receiptHandle }),
  })

  if (!res.ok) {
    const body = await res.text()
    throw new Error(`delete failed ${res.status}: ${body}`)
  }
}

/**
 * @param {{ to: string[] }} recipients
 * @param {string} subject
 * @param {string} html
 * @param {string} text
 */
async function sendSes(recipients, subject, html, text) {
  const from = process.env.SES_FROM || ''
  if (!from) throw new Error('SES_FROM is required')

  const region = process.env.AWS_REGION || 'us-east-1'
  const client = new SESClient({ region })

  const params = {
    Source: from,
    Destination: { ToAddresses: recipients.to },
    Message: {
      Subject: { Data: subject, Charset: 'UTF-8' },
      Body: {
        Html: { Data: html, Charset: 'UTF-8' },
        Text: { Data: text, Charset: 'UTF-8' },
      },
    },
  }
  console.log('[email-worker] SES send', { toCount: recipients.to.length, subject })
  await client.send(new SendEmailCommand(params))
}

/**
 * @param {{ eventType: string, messages: unknown[] }} group
 */
async function processDigestGroup(group) {
  const { eventType, messages } = group
  const firstPayload =
    messages[0].payload && typeof messages[0].payload === 'object' ? messages[0].payload : {}
  const recipients = resolveRecipients(eventType, firstPayload)
  const items = messages.map((msg, i) => buildItemRow(msg, i + 1))
  const subjectTpl = SUBJECT_DIGEST_TEMPLATES[eventType]
  if (!subjectTpl) throw new Error(`No digest subject for ${eventType}`)
  const subject = renderSubject(subjectTpl, { count: items.length })
  const { html, text } = renderDigestBody(eventType, items)
  await sendSes(recipients, subject, html, text)
  for (const msg of messages) {
    await apiDelete(msg.eqId, msg.receiptHandle)
  }
}

/**
 * @param {unknown} msg
 */
async function processSingleLegacy(msg) {
  if (!isQueueMessage(msg)) throw new Error('invalid queue message')
  const eventType = msg.eventType
  const payload = msg.payload && typeof msg.payload === 'object' ? msg.payload : {}
  const data = {
    ...payload,
    eqId: msg.eqId,
    attempts: msg.attempts,
    createdAt: msg.createdAt,
  }
  const subjectTpl = SUBJECT_TEMPLATES[eventType]
  if (!subjectTpl) throw new Error(`Unknown eventType: ${eventType}`)
  const recipients = resolveRecipients(eventType, payload)
  const subject = renderSubject(subjectTpl, data)
  const { html, text } = renderBody(eventType, data)
  await sendSes(recipients, subject, html, text)
  await apiDelete(msg.eqId, msg.receiptHandle)
}

/**
 * @param {import('aws-lambda').EventBridgeEvent<string, unknown>} _event
 */
export async function handler(_event) {
  if (!process.env.API_BASE_URL || !process.env.EMAIL_QUEUE_BEARER_TOKEN) {
    throw new Error('API_BASE_URL and EMAIL_QUEUE_BEARER_TOKEN must be set')
  }

  const messages = await apiReceive()
  const results = { received: messages.length, sent: 0, failed: 0, errors: [] }

  const { groups, unknownType, orphanSubmitter } = partitionBatch(messages)

  for (const msg of orphanSubmitter) {
    if (!isQueueMessage(msg)) continue
    results.failed += 1
    results.errors.push({
      eqId: msg.eqId,
      eventType: msg.eventType,
      message: 'submitterEmail missing in payload (cannot address digest)',
    })
    console.error('[email-worker] orphan message', { eqId: msg.eqId, eventType: msg.eventType })
  }

  for (const group of groups) {
    try {
      await processDigestGroup(group)
      results.sent += group.messages.length
    } catch (err) {
      const n = group.messages.length
      results.failed += n
      const message = err instanceof Error ? err.message : String(err)
      for (const msg of group.messages) {
        if (!isQueueMessage(msg)) continue
        results.errors.push({ eqId: msg.eqId, eventType: msg.eventType, message })
      }
      console.error('[email-worker] digest group failed', { eventType: group.eventType, count: n, message })
    }
  }

  for (const msg of unknownType) {
    if (!isQueueMessage(msg)) continue
    try {
      await processSingleLegacy(msg)
      results.sent += 1
    } catch (err) {
      results.failed += 1
      const message = err instanceof Error ? err.message : String(err)
      results.errors.push({ eqId: msg.eqId, eventType: msg.eventType, message })
      console.error('[email-worker] legacy message failed', { eqId: msg.eqId, eventType: msg.eventType, message })
    }
  }

  console.log(JSON.stringify(results))
  return results
}

export {
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
}
