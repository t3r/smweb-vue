import express from 'express'
import * as countriesController from '../controllers/countries.js'

const router = express.Router()

router.get('/', countriesController.getCountries)
router.get('/at', countriesController.getCountryAt)

export default router
