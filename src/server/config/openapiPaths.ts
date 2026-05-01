/**
 * Static OpenAPI path items (swagger-jsdoc has no @openapi blocks on routes yet).
 * Server `url` is `/api`, so paths here are relative to that base (no `/api` prefix).
 */
export const openapiPaths = {
  '/health': {
    get: {
      tags: ['Health'],
      summary: 'Health check',
      description: 'Verifies database connectivity.',
      responses: {
        '200': { description: 'OK — database reachable' },
        '503': { description: 'Database unreachable' },
      },
    },
  },
  '/client-build': {
    get: {
      tags: ['Client'],
      summary: 'Client build id',
      description: 'Git/version identifier for SPA stale-client detection.',
      responses: { '200': { description: 'JSON with buildId' } },
    },
  },
  '/statistics': {
    get: {
      tags: ['Statistics'],
      summary: 'Latest statistics snapshot',
      responses: { '200': { description: 'Latest counts + pendingRequests' } },
    },
  },
  '/statistics/history': {
    get: {
      tags: ['Statistics'],
      summary: 'Statistics history',
      responses: { '200': { description: 'Time series of counts' } },
    },
  },
  '/statistics/author-contributions': {
    get: {
      tags: ['Statistics'],
      summary: 'Author contributions leaderboard',
      responses: { '200': { description: 'Leaderboard payload' } },
    },
  },
  '/models': {
    get: {
      tags: ['Models'],
      summary: 'List models',
      parameters: [
        { name: 'offset', in: 'query', schema: { type: 'integer' } },
        { name: 'limit', in: 'query', schema: { type: 'integer' } },
        { name: 'group', in: 'query', schema: { type: 'integer' }, description: 'Model group id' },
      ],
      responses: { '200': { description: 'Paginated models list' } },
    },
    post: {
      tags: ['Models'],
      summary: 'Create model (authenticated author)',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Created' }, '401': { description: 'Unauthorized' } },
    },
  },
  '/models/recent': {
    get: {
      tags: ['Models'],
      summary: 'Recent models',
      responses: { '200': { description: 'Recent models list' } },
    },
  },
  '/models/{id}': {
    get: {
      tags: ['Models'],
      summary: 'Get model by id',
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Model' }, '404': { description: 'Not found' } },
    },
    put: {
      tags: ['Models'],
      summary: 'Update model',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Updated' }, '401': { description: 'Unauthorized' } },
    },
  },
  '/models/{id}/thumbnail': {
    get: {
      tags: ['Models'],
      summary: 'Model thumbnail image',
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Image binary' }, '404': { description: 'Not found' } },
    },
  },
  '/models/{id}/preview': {
    get: {
      tags: ['Models'],
      summary: 'Model preview',
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Preview payload or binary' } },
    },
  },
  '/models/{id}/file': {
    get: {
      tags: ['Models'],
      summary: 'Single model file',
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'File binary' } },
    },
  },
  '/models/{id}/files': {
    get: {
      tags: ['Models'],
      summary: 'List model file names',
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'File list JSON' } },
    },
  },
  '/models/{id}/package': {
    get: {
      tags: ['Models'],
      summary: 'Download model package',
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Archive binary' } },
    },
  },
  '/objects': {
    get: {
      tags: ['Objects'],
      summary: 'List objects',
      parameters: [
        { name: 'offset', in: 'query', schema: { type: 'integer' } },
        { name: 'limit', in: 'query', schema: { type: 'integer' } },
      ],
      responses: { '200': { description: 'Paginated objects' } },
    },
    post: {
      tags: ['Objects'],
      summary: 'Create object',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Created' }, '401': { description: 'Unauthorized' } },
    },
  },
  '/objects/search': {
    get: {
      tags: ['Objects'],
      summary: 'Search objects',
      parameters: [
        { name: 'model', in: 'query', schema: { type: 'integer' } },
        { name: 'lat', in: 'query', schema: { type: 'number' } },
        { name: 'lon', in: 'query', schema: { type: 'number' } },
        { name: 'country', in: 'query', schema: { type: 'string' } },
        { name: 'description', in: 'query', schema: { type: 'string' } },
      ],
      responses: { '200': { description: 'Search results' } },
    },
  },
  '/objects/map': {
    get: {
      tags: ['Objects'],
      summary: 'Objects for map view',
      responses: { '200': { description: 'Geo-oriented object list' } },
    },
  },
  '/objects/{id}': {
    get: {
      tags: ['Objects'],
      summary: 'Get object by id',
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Object' }, '404': { description: 'Not found' } },
    },
    put: {
      tags: ['Objects'],
      summary: 'Update object',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Updated' } },
    },
    delete: {
      tags: ['Objects'],
      summary: 'Delete object',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Deleted' } },
    },
  },
  '/authors': {
    get: {
      tags: ['Authors'],
      summary: 'List authors',
      responses: { '200': { description: 'Authors list' } },
    },
  },
  '/authors/{id}': {
    get: {
      tags: ['Authors'],
      summary: 'Get author by id',
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Author' }, '404': { description: 'Not found' } },
    },
    patch: {
      tags: ['Authors'],
      summary: 'Update author description (self or admin)',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Updated' } },
    },
  },
  '/authors/{id}/role': {
    put: {
      tags: ['Authors'],
      summary: 'Update author role (admin only)',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
      responses: { '200': { description: 'Updated' }, '403': { description: 'Forbidden' } },
    },
  },
  '/news': {
    get: {
      tags: ['News'],
      summary: 'News items',
      responses: { '200': { description: 'News list' } },
    },
  },
  '/countries': {
    get: {
      tags: ['Countries'],
      summary: 'List countries',
      responses: { '200': { description: 'Countries' } },
    },
  },
  '/countries/at': {
    get: {
      tags: ['Countries'],
      summary: 'Country at lat/lon',
      parameters: [
        { name: 'lat', in: 'query', required: true, schema: { type: 'number' } },
        { name: 'lon', in: 'query', required: true, schema: { type: 'number' } },
      ],
      responses: { '200': { description: 'Country code or null' } },
    },
  },
  '/modelgroups': {
    get: {
      tags: ['Model groups'],
      summary: 'List model groups',
      responses: { '200': { description: 'Groups' } },
    },
  },
  '/airports/by-icao/{icao}': {
    get: {
      tags: ['Airports'],
      summary: 'Airport by ICAO',
      parameters: [{ name: 'icao', in: 'path', required: true, schema: { type: 'string' } }],
      responses: { '200': { description: 'Airport' }, '404': { description: 'Not found' } },
    },
  },
  '/auth/me': {
    get: {
      tags: ['Auth'],
      summary: 'Current session user',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'User or empty' }, '401': { description: 'Not logged in' } },
    },
  },
  '/auth/github': {
    get: {
      tags: ['Auth'],
      summary: 'Start GitHub OAuth',
      responses: { '302': { description: 'Redirect to GitHub' } },
    },
  },
  '/auth/google': {
    get: {
      tags: ['Auth'],
      summary: 'Start Google OAuth',
      responses: { '302': { description: 'Redirect to Google' } },
    },
  },
  '/auth/gitlab': {
    get: {
      tags: ['Auth'],
      summary: 'Start GitLab OAuth',
      responses: { '302': { description: 'Redirect to GitLab' } },
    },
  },
  '/auth/logout': {
    post: {
      tags: ['Auth'],
      summary: 'Logout',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Logged out' } },
    },
  },
  '/auth/merge/initiate': {
    post: {
      tags: ['Auth'],
      summary: 'Initiate account merge',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Merge request created' } },
    },
  },
  '/auth/merge/preview': {
    get: {
      tags: ['Auth'],
      summary: 'Preview account merge',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Preview payload' } },
    },
  },
  '/auth/merge/confirm': {
    post: {
      tags: ['Auth'],
      summary: 'Confirm account merge',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Merged' } },
    },
  },
  '/auth/merge/cancel': {
    post: {
      tags: ['Auth'],
      summary: 'Cancel account merge',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Cancelled' } },
    },
  },
  '/submissions/objects/stg-preview': {
    post: {
      tags: ['Submissions'],
      summary: 'Preview .stg objects payload',
      responses: { '200': { description: 'Preview' } },
    },
  },
  '/submissions/objects': {
    post: {
      tags: ['Submissions'],
      summary: 'Submit new objects (position request)',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Submitted' }, '401': { description: 'Unauthorized' } },
    },
  },
  '/submissions/object/delete': {
    post: {
      tags: ['Submissions'],
      summary: 'Submit object delete request',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Queued' } },
    },
  },
  '/submissions/object/update': {
    post: {
      tags: ['Submissions'],
      summary: 'Submit object update request',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Queued' } },
    },
  },
  '/submissions/model/delete': {
    post: {
      tags: ['Submissions'],
      summary: 'Submit model delete request',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Queued' } },
    },
  },
  '/submissions/models': {
    post: {
      tags: ['Submissions'],
      summary: 'Submit new model (position request)',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Queued' } },
    },
  },
  '/submissions/models/upload': {
    post: {
      tags: ['Submissions'],
      summary: 'Submit model with multipart uploads',
      security: [{ sessionCookie: [] }],
      requestBody: {
        content: { 'multipart/form-data': { schema: { type: 'object' } } },
      },
      responses: { '200': { description: 'Queued' } },
    },
  },
  '/submissions/models/update-upload': {
    post: {
      tags: ['Submissions'],
      summary: 'Submit model update with multipart uploads',
      security: [{ sessionCookie: [] }],
      requestBody: {
        content: { 'multipart/form-data': { schema: { type: 'object' } } },
      },
      responses: { '200': { description: 'Queued' } },
    },
  },
  '/submissions/pending': {
    get: {
      tags: ['Submissions', 'Review'],
      summary: 'Legacy pending list (validator)',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Pending items' }, '403': { description: 'Not a reviewer' } },
    },
  },
  '/submissions/pending/{sig}': {
    get: {
      tags: ['Submissions', 'Review'],
      summary: 'Legacy pending item by signature',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'sig', in: 'path', required: true, schema: { type: 'string' } }],
      responses: { '200': { description: 'Item' }, '404': { description: 'Not found' } },
    },
  },
  '/submissions/pending/{sig}/accept': {
    post: {
      tags: ['Submissions', 'Review'],
      summary: 'Accept pending submission',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'sig', in: 'path', required: true, schema: { type: 'string' } }],
      responses: { '200': { description: 'Applied' } },
    },
  },
  '/submissions/pending/{sig}/reject': {
    post: {
      tags: ['Submissions', 'Review'],
      summary: 'Reject pending submission',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'sig', in: 'path', required: true, schema: { type: 'string' } }],
      requestBody: {
        content: {
          'application/json': {
            schema: {
              type: 'object',
              properties: { reason: { type: 'string' } },
            },
          },
        },
      },
      responses: { '200': { description: 'Rejected' } },
    },
  },
  '/position-requests': {
    get: {
      tags: ['Position requests', 'Review'],
      summary: 'List position requests (reviewer)',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: 'Pending + failed decode' }, '403': { description: 'Forbidden' } },
    },
  },
  '/position-requests/pending-count': {
    get: {
      tags: ['Position requests', 'Review'],
      summary: 'Count of pending requests',
      security: [{ sessionCookie: [] }],
      responses: { '200': { description: '{ count: number }' } },
    },
  },
  '/position-requests/{sig}': {
    get: {
      tags: ['Position requests', 'Review'],
      summary: 'Position request by signature',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'sig', in: 'path', required: true, schema: { type: 'string' } }],
      responses: { '200': { description: 'Request' } },
    },
  },
  '/position-requests/{sig}/thumbnail': {
    get: {
      tags: ['Position requests', 'Review'],
      summary: 'Thumbnail for request package',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'sig', in: 'path', required: true, schema: { type: 'string' } }],
      responses: { '200': { description: 'Image' } },
    },
  },
  '/position-requests/{sig}/model-preview': {
    get: {
      tags: ['Position requests', 'Review'],
      summary: 'Model preview for request',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'sig', in: 'path', required: true, schema: { type: 'string' } }],
      responses: { '200': { description: 'Preview' } },
    },
  },
  '/position-requests/{sig}/model-files': {
    get: {
      tags: ['Position requests', 'Review'],
      summary: 'Model file list for request',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'sig', in: 'path', required: true, schema: { type: 'string' } }],
      responses: { '200': { description: 'File list' } },
    },
  },
  '/position-requests/{sig}/file': {
    get: {
      tags: ['Position requests', 'Review'],
      summary: 'Single file from request package',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'sig', in: 'path', required: true, schema: { type: 'string' } }],
      responses: { '200': { description: 'File binary' } },
    },
  },
  '/position-requests/{sig}/package': {
    get: {
      tags: ['Position requests', 'Review'],
      summary: 'Download request model package',
      security: [{ sessionCookie: [] }],
      parameters: [{ name: 'sig', in: 'path', required: true, schema: { type: 'string' } }],
      responses: { '200': { description: 'Archive' } },
    },
  },
  '/email-queue/receive': {
    post: {
      tags: ['Email queue'],
      summary: 'Inbound queue worker webhook',
      description: 'Requires configured bearer token (not session cookie).',
      security: [{ emailQueueBearer: [] }],
      responses: { '200': { description: 'OK' }, '401': { description: 'Invalid token' } },
    },
  },
  '/email-queue/delete': {
    post: {
      tags: ['Email queue'],
      summary: 'Delete processed queue message',
      security: [{ emailQueueBearer: [] }],
      responses: { '200': { description: 'OK' } },
    },
  },
}
