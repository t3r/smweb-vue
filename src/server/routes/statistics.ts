import express from 'express'
import * as statisticsController from '../controllers/statistics.js'

const router = express.Router()

router.get('/history', statisticsController.getStatisticsHistory)
router.get('/author-contributions', statisticsController.getAuthorContributionsLeaderboard)
router.get('/', statisticsController.getStatistics)

export default router
