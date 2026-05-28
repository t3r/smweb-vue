import express from 'express'
import * as stgController from '../controllers/stg.js'

const router = express.Router()

router.get('/:tile/stg', stgController.getTileStg)

export default router
