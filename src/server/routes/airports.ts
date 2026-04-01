import express from 'express'
import * as airportsController from '../controllers/airports.js'

const router = express.Router()

router.get('/by-icao/:icao', airportsController.getAirportByIcao)

export default router
