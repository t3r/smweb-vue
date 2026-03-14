import express from 'express'
import * as emailQueueController from '../controllers/emailQueueController.js'
import { requireEmailQueueBearer } from '../middleware/emailQueueBearer.js'

const router = express.Router()

router.post('/receive', requireEmailQueueBearer, emailQueueController.receive)
router.post('/delete', requireEmailQueueBearer, emailQueueController.deleteMessage)

export default router
