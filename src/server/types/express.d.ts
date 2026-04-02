import type { Session, SessionData as ExpressSessionData } from 'express-session'

declare global {
  namespace Express {
    interface User {
      id: number
      name: string
      email: string
      role: string
    }

    interface Request {
      session: Session & Partial<ExpressSessionData>
    }
  }
}

export {}
