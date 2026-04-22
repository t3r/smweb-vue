import express from 'express'
import * as positionRequestsController from '../controllers/positionRequestsController.js'
import { requireAuth, requireRole } from '../middleware/auth.js'

const router = express.Router()

router.get('/', requireAuth, requireRole('reviewer'), positionRequestsController.getList)
router.get(
  '/pending-count',
  requireAuth,
  requireRole('reviewer'),
  positionRequestsController.getPendingCount
)
router.get('/:sig/model-preview', requireAuth, requireRole('reviewer'), positionRequestsController.getModelPreview)
router.get('/:sig/model-files', requireAuth, requireRole('reviewer'), positionRequestsController.getRequestModelFiles)
router.get('/:sig/file', requireAuth, requireRole('reviewer'), positionRequestsController.getRequestModelFile)
router.get('/:sig/package', requireAuth, requireRole('reviewer'), positionRequestsController.getRequestModelPackage)
router.get('/:sig/thumbnail', requireAuth, requireRole('reviewer'), positionRequestsController.getRequestModelThumbnail)
router.get('/:sig', requireAuth, requireRole('reviewer'), positionRequestsController.getBySig)

export default router
