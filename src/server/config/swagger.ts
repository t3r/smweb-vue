import swaggerJsdoc from 'swagger-jsdoc'

const apis =
  process.env.NODE_ENV === 'production'
    ? ['./dist/server/routes/*.js']
    : ['./src/server/routes/*.ts', './src/server/routes/*.js']

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'FlightGear Scenemodels API',
      version: '1.0.0',
      description:
        'API for FlightGear scenery models and objects. Includes read (GET) and write operations: add/update/delete objects, add/update models (model submission workflow may return 501 until implemented).',
    },
    servers: [
      {
        url: 'http://localhost:3000/api',
        description: 'Development server',
      },
    ],
  },
  apis,
}

export default swaggerJsdoc(options)
