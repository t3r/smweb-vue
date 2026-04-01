import express from 'express'
import modelsRouter from './models.js'
import modelgroupsRouter from './modelgroups.js'
import objectsRouter from './objects.js'
import countriesRouter from './countries.js'
import authorsRouter from './authors.js'
import submissionsRouter from './submissions.js'
import statisticsRouter from './statistics.js'
import positionRequestsRouter from './positionRequests.js'
import newsRouter from './news.js'
import emailQueueRouter from './emailQueue.js'
import airportsRouter from './airports.js'

const router = express.Router()

router.use('/news', newsRouter)
router.use('/models', modelsRouter)
router.use('/modelgroups', modelgroupsRouter)
router.use('/objects', objectsRouter)
router.use('/countries', countriesRouter)
router.use('/authors', authorsRouter)
router.use('/submissions', submissionsRouter)
router.use('/statistics', statisticsRouter)
router.use('/position-requests', positionRequestsRouter)
router.use('/email-queue', emailQueueRouter)
router.use('/airports', airportsRouter)

export default router
