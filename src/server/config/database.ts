import Sequelize from 'sequelize'
import dotenv from 'dotenv'

dotenv.config()

const {
  DB_HOST = 'localhost',
  DB_PORT = 5432,
  DB_NAME = 'scenemodels',
  DB_USER = 'postgres',
  DB_PASSWORD = 'postgres',
  DATABASE_URL,
} = process.env

/** Enable SQL query logging when LOG_SQL=1 or LOG_LEVEL=debug (disabled in test unless LOG_SQL=1). */
function getSequelizeLogging(): false | ((sql: string) => void) {
  if (process.env.NODE_ENV === 'test' && !process.env.LOG_SQL) return false
  if (process.env.LOG_SQL === '1' || process.env.LOG_SQL === 'true') return sqlLogger
  if (process.env.LOG_LEVEL === 'debug') return sqlLogger
  return false
}

function sqlLogger(sql: string): void {
  console.log('[SQL]', typeof sql === 'string' ? sql : (sql as { query?: string })?.query ?? String(sql))
}

const logging = getSequelizeLogging()

const SequelizeClass = Sequelize as unknown as new (...args: unknown[]) => import('sequelize').Sequelize
const sequelize = DATABASE_URL
  ? new SequelizeClass(DATABASE_URL, { logging })
  : new SequelizeClass(DB_NAME, DB_USER, DB_PASSWORD, {
      host: DB_HOST,
      port: Number(DB_PORT),
      dialect: 'postgres',
      logging,
    })

export { sequelize }
export default sequelize
