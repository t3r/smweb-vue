import rateLimit from 'express-rate-limit'

const WINDOW_MS = 60 * 1000 // 1 minute
const MAX_PER_IP = 200
const MAX_PER_SESSION = 100

// Accurate IP requires app.set('trust proxy', 1) when TRUST_PROXY is set (see app.ts).
function getClientIp(req: { ip?: string; socket?: { remoteAddress?: string } }): string {
  return req.ip ?? req.socket?.remoteAddress ?? 'unknown'
}

/** Per-IP (all sessions). */
export const perIpLimiter = rateLimit({
  windowMs: WINDOW_MS,
  max: MAX_PER_IP,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => getClientIp(req),
})

/** Per session id, else per IP. */
export const perSessionLimiter = rateLimit({
  windowMs: WINDOW_MS,
  max: MAX_PER_SESSION,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    const session = (req as { sessionID?: string }).sessionID
    if (session) return `s:${session}`
    return `ip:${getClientIp(req)}`
  },
})
