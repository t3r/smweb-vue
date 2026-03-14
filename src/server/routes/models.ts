import express from 'express'
import * as modelsController from '../controllers/models.js'

const router = express.Router()

router.get('/', modelsController.getModels)
router.post('/', modelsController.createModel)
router.get('/recent', modelsController.getRecentModels)
router.get('/:id/thumbnail', modelsController.getModelThumbnail)
router.get('/:id/preview', modelsController.getModelPreview)
router.get('/:id/file', modelsController.getModelFile)
router.get('/:id/files', modelsController.getModelFiles)
router.get('/:id/package', modelsController.getModelPackage)
router.get('/:id', modelsController.getModel)
router.put('/:id', modelsController.updateModel)

export default router
