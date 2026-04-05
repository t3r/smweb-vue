import express from 'express'
import type { NextFunction, Request, Response } from 'express'
import multer, { MulterError } from 'multer'
import * as submissionsController from '../controllers/submissionsController.js'
import * as validatorController from '../controllers/validatorController.js'
import { requireAuth, requirePositionRequestSubmitAuth, requireRole } from '../middleware/auth.js'
import { MODEL_UPLOAD_MAX_FILE_BYTES } from '../utils/modelUploadValidation.js'

const router = express.Router()
const uploadModelFiles = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MODEL_UPLOAD_MAX_FILE_BYTES },
})

function runModelUploadMulter(req: Request, res: Response, next: NextFunction): void {
  uploadModelFiles.fields([
    { name: 'thumbnail', maxCount: 1 },
    { name: 'ac3d', maxCount: 1 },
    { name: 'xml', maxCount: 1 },
    { name: 'png', maxCount: 12 },
  ])(req, res, (err: unknown) => {
    if (err instanceof MulterError && err.code === 'LIMIT_FILE_SIZE') {
      res.status(400).json({ error: 'Each uploaded file must be at most 2 MB.' })
      return
    }
    if (err) {
      next(err as Error)
      return
    }
    next()
  })
}

router.post('/objects/stg-preview', submissionsController.previewStgObjects)
router.post('/objects', requirePositionRequestSubmitAuth, submissionsController.submitObjects)
router.post('/object/delete', requirePositionRequestSubmitAuth, submissionsController.submitObjectDelete)
router.post('/object/update', requirePositionRequestSubmitAuth, submissionsController.submitObjectUpdate)
router.post('/model/delete', requirePositionRequestSubmitAuth, submissionsController.submitModelDelete)
router.post('/models', requirePositionRequestSubmitAuth, submissionsController.submitModel)
router.post(
  '/models/upload',
  requirePositionRequestSubmitAuth,
  runModelUploadMulter,
  submissionsController.submitModelUpload
)
router.post(
  '/models/update-upload',
  requirePositionRequestSubmitAuth,
  runModelUploadMulter,
  submissionsController.submitModelUpdateUpload
)
router.get('/pending', requireAuth, requireRole('reviewer'), validatorController.getPending)
router.get('/pending/:sig', requireAuth, requireRole('reviewer'), validatorController.getBySig)
router.post('/pending/:sig/accept', requireAuth, requireRole('reviewer'), validatorController.accept)
router.post('/pending/:sig/reject', requireAuth, requireRole('reviewer'), validatorController.reject)

export default router
