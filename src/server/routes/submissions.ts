import express from 'express'
import multer from 'multer'
import * as submissionsController from '../controllers/submissionsController.js'
import * as validatorController from '../controllers/validatorController.js'
import { requireAuth, requireRole } from '../middleware/auth.js'

const router = express.Router()
const upload = multer({ storage: multer.memoryStorage() })

router.post('/objects/stg-preview', submissionsController.previewStgObjects)
router.post('/objects', requireAuth, requireRole('tester'), submissionsController.submitObjects)
router.post('/object/delete', requireAuth, requireRole('tester'), submissionsController.submitObjectDelete)
router.post('/object/update', requireAuth, requireRole('tester'), submissionsController.submitObjectUpdate)
router.post('/model/delete', requireAuth, requireRole('tester'), submissionsController.submitModelDelete)
router.post('/models', requireAuth, requireRole('tester'), submissionsController.submitModel)
router.post(
  '/models/upload',
  requireAuth,
  requireRole('tester'),
  upload.fields([
    { name: 'thumbnail', maxCount: 1 },
    { name: 'ac3d', maxCount: 1 },
    { name: 'xml', maxCount: 1 },
    { name: 'png', maxCount: 12 },
  ]),
  submissionsController.submitModelUpload
)
router.get('/pending', requireAuth, requireRole('reviewer'), validatorController.getPending)
router.get('/pending/:sig', requireAuth, requireRole('reviewer'), validatorController.getBySig)
router.post('/pending/:sig/accept', requireAuth, requireRole('reviewer'), validatorController.accept)
router.post('/pending/:sig/reject', requireAuth, requireRole('reviewer'), validatorController.reject)

export default router
