import type { Request, Response, NextFunction } from 'express'
import { hasMinimumRole } from '../config/authConstants.js'

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
