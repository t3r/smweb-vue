import express from 'express'
import * as positionRequestsController from '../controllers/positionRequestsController.js'
import { requireAuth, requireRole } from '../middleware/auth.js'

const router = express.Router()

router.get('/', requireAuth, requireRole('reviewer'), positionRequestsController.getList)
router.get('/:sig/model-preview', requireAuth, requireRole('reviewer'), positionRequestsController.getModelPreview)
router.get('/:sig/thumbnail', requireAuth, requireRole('reviewer'), positionRequestsController.getRequestModelThumbnail)
router.get('/:sig', requireAuth, requireRole('reviewer'), positionRequestsController.getBySig)

export default router
