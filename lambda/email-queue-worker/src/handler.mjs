/**
 * EventBridge-scheduled Lambda: pull from FlightGear scenemodels email queue API,
 * render bodies with Handlebars (simple, logic-light templates), send via Amazon SES,
 * DELETE queue rows only after SES accepts the send.
 *
 * Env vars:
 *   API_BASE_URL              e.g. https://your-api.example.com (no trailing slash)
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
  const htmlTpl = compileTemplate(`${eventType}.html`)
  const textTpl = compileTemplate(`${eventType}.txt`)
  return {
    html: htmlTpl(data),
    text: textTpl(data),
  }
}

function renderSubject(template, data) {
  return Handlebars.compile(template)(data)
}

const SUBJECT_TEMPLATES = {
  'position_request.created': '[FG Scenemodels] New position request #{{requestId}} ({{requestType}})',
  'position_request.accepted': '[FG Scenemodels] Your request was accepted ({{requestType}})',
  'position_request.rejected': '[FG Scenemodels] Your request was rejected ({{requestType}})',
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

  await client.send(
    new SendEmailCommand({
      Source: from,
      Destination: { ToAddresses: recipients.to },
      Message: {
        Subject: { Data: subject, Charset: 'UTF-8' },
        Body: {
          Html: { Data: html, Charset: 'UTF-8' },
          Text: { Data: text, Charset: 'UTF-8' },
        },
      },
    })
  )
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

  for (const msg of messages) {
    const eventType = msg.eventType
    const payload = msg.payload && typeof msg.payload === 'object' ? msg.payload : {}
    const data = {
      ...payload,
      eqId: msg.eqId,
      attempts: msg.attempts,
      createdAt: msg.createdAt,
    }

    try {
      const subjectTpl = SUBJECT_TEMPLATES[eventType]
      if (!subjectTpl) {
        throw new Error(`Unknown eventType: ${eventType}`)
      }

      const recipients = resolveRecipients(eventType, payload)
      const subject = renderSubject(subjectTpl, data)
      const { html, text } = renderBody(eventType, data)

      await sendSes(recipients, subject, html, text)
      await apiDelete(msg.eqId, msg.receiptHandle)
      results.sent += 1
    } catch (err) {
      results.failed += 1
      const message = err instanceof Error ? err.message : String(err)
      results.errors.push({ eqId: msg.eqId, eventType, message })
      console.error('[email-worker] message failed', { eqId: msg.eqId, eventType, message })
    }
  }

  console.log(JSON.stringify(results))
  return results
}
