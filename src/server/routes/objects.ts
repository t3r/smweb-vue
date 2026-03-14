import express from 'express'
import * as objectsController from '../controllers/objects.js'

const router = express.Router()

router.get('/', objectsController.getObjects)
router.post('/', objectsController.createObject)
router.get('/search', objectsController.searchObjects)
router.get('/map', objectsController.getObjectsForMap)
router.get('/:id', objectsController.getObject)
router.put('/:id', objectsController.updateObject)
router.delete('/:id', objectsController.deleteObject)

export default router
