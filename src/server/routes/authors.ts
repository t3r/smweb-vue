import express from 'express'
import * as authorsController from '../controllers/authors.js'
import { requireAuth, requireRole } from '../middleware/auth.js'

const router = express.Router()

router.get('/', authorsController.getAuthors)
router.put('/:id/role', requireAuth, requireRole('admin'), authorsController.updateAuthorRole)
router.get('/:id', authorsController.getAuthor)

export default router
