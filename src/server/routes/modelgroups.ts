import express from 'express'
import * as modelgroupsController from '../controllers/modelgroups.js'

const router = express.Router()

router.get('/', modelgroupsController.getModelGroups)

export default router
