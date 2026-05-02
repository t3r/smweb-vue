import express from 'express'
import * as positionRequestsController from '../controllers/positionRequestsController.js'
import { requireAuth, requireRole } from '../middleware/auth.js'

const router = express.Router()

router.get('/', requireAuth, positionRequestsController.getList)
router.get(
  '/pending-count',
  requireAuth,
  requireRole('reviewer'),
  positionRequestsController.getPendingCount
)
router.get('/:sig/model-preview', requireAuth, positionRequestsController.getModelPreview)
router.get('/:sig/model-files', requireAuth, positionRequestsController.getRequestModelFiles)
router.get('/:sig/file', requireAuth, positionRequestsController.getRequestModelFile)
router.get('/:sig/package', requireAuth, positionRequestsController.getRequestModelPackage)
router.get('/:sig/thumbnail', requireAuth, positionRequestsController.getRequestModelThumbnail)
router.get('/:sig', requireAuth, positionRequestsController.getBySig)

export default router
