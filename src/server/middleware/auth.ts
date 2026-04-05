import type { Request, Response, NextFunction } from 'express'
import { hasMinimumRole } from '../config/authConstants.js'
import { getPositionRequestSubmitRequiredRole } from '../config/positionRequestSubmitAuth.js'

export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  if (req.isAuthenticated && req.isAuthenticated()) {
    next()
    return
  }
  res.status(401).json({ error: 'Authentication required' })
}

export function requireRole(role: string) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' })
      return
    }
    if (hasMinimumRole(req.user.role, role)) {
      next()
      return
    }
    res.status(403).json({ error: 'Insufficient permissions' })
  }
}

/** Auth gate for POST `/api/submissions/*` routes that enqueue position requests (see `POSITION_REQUEST_SUBMIT_ROLE`). */
export function requirePositionRequestSubmitAuth(req: Request, res: Response, next: NextFunction): void {
  const required = getPositionRequestSubmitRequiredRole()
  if (required === 'none') {
    next()
    return
  }
  requireAuth(req, res, () => {
    requireRole(required)(req, res, next)
  })
}
