import Author from './Author.js'
import ModelGroup from './ModelGroup.js'
import Model from './Model.js'
import { sequelize } from '../config/database.js'

const models = { Author, ModelGroup, Model }

export { sequelize, Author, ModelGroup, Model }
export default models
