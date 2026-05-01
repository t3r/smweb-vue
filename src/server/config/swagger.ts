import swaggerJsdoc from 'swagger-jsdoc'
import { openapiPaths } from './openapiPaths.js'

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
        'API for FlightGear scenery models and objects. Includes read (GET) and write operations: add/update/delete objects, add/update models (model submission workflow may return 501 until implemented). ' +
        'Session-authenticated routes use the `flightgear.sid` cookie after OAuth login. ' +
        'Route-level details can be extended with `@openapi` JSDoc in `src/server/routes/*`.',
    },
    servers: [
      {
        url: '/api',
        description: 'Same origin as this server (recommended for Try it out)',
      },
      {
        url: 'http://localhost:3000/api',
        description: 'Local development',
      },
    ],
    components: {
      securitySchemes: {
        sessionCookie: {
          type: 'apiKey',
          in: 'cookie',
          name: 'flightgear.sid',
          description: 'Session cookie set after OAuth login.',
        },
        emailQueueBearer: {
          type: 'http',
          scheme: 'bearer',
          description: 'Bearer token from server env (email queue worker only).',
        },
      },
    },
    paths: { ...openapiPaths },
  },
  apis,
}

export default swaggerJsdoc(options)
