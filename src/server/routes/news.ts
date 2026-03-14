import express from 'express'
import * as newsController from '../controllers/newsController.js'

const router = express.Router()

router.get('/', newsController.getNews)

export default router
