/**
 * Database layer mocks for API tests. Import this before the app so controllers
 * use mock data and no real DB is required.
 * `tests/api/model-upload.test.js` imports modelUploadValidation before `app.js` runs; it must
 * `import '../helpers/mocks.js'` first or repos load real and CI hits SequelizeConnectionRefused.
 */
import { vi } from 'vitest'

const stubModel = {
  id: 1,
  name: 'Test Model',
  filename: 'test.ac',
  description: '',
  author: { id: 1, name: 'Test' },
  group: 'Test',
  lastUpdated: null,
}

const stubObject = {
  id: 1,
  modelId: 1,
  description: 'Test',
  type: 'Static',
  position: { lat: 0, lon: 0, elevation: 0, offset: 0, heading: 0 },
  country: 'XX',
  lastUpdated: null,
}

const stubAuthor = {
  id: 1,
  name: 'Test Author',
  email: 'test@example.com',
  description: '',
  modelsCount: 0,
}

const stubNews = {
  id: 1,
  title: 'Test',
  content: 'Test content',
  author: { id: 1, name: 'Test' },
  publishedAt: new Date().toISOString(),
}

vi.mock('../../src/server/services/modelService.ts', () => ({
  getModels: vi.fn().mockImplementation((offset = 0, limit = 20) =>
    Promise.resolve({ models: [], total: 0, offset: Number(offset), limit: Number(limit) })
  ),
  getRecentModels: vi.fn().mockResolvedValue({ models: [] }),
  getModelById: vi.fn().mockImplementation((id) => (id === 1 ? Promise.resolve(stubModel) : Promise.resolve(null))),
  getModelFiles: vi.fn().mockResolvedValue({ files: [{ name: 'model.ac', size: 1024 }] }),
  getModelFileContent: vi.fn().mockResolvedValue(null),
  getModelPackageBuffer: vi.fn().mockResolvedValue(null),
  getModelPreviewData: vi.fn().mockImplementation((id) =>
    id === 1
      ? Promise.resolve({
          geometry: { metadata: { formatVersion: 3.1 }, vertices: [], normals: [], faces: [] },
          acFileName: 'model.ac',
          textures: [{ name: 'tex.png', url: '/api/models/1/file?name=tex.png' }],
        })
      : Promise.resolve(null)
  ),
}))

vi.mock('../../src/server/services/modelgroupService.ts', () => ({
  getModelGroups: vi.fn().mockResolvedValue({ groups: [{ id: 1, name: 'Static', path: 'Static' }] }),
}))

vi.mock('../../src/server/services/countryService.ts', () => ({
  getCountries: vi.fn().mockResolvedValue({
    countries: [
      { code: 'DE', name: 'Germany' },
      { code: 'US', name: 'United States' },
    ],
  }),
  getCountryAt: vi.fn().mockResolvedValue({ country: { code: 'de', name: 'Germany' } }),
  resolveCountryCodeAt: vi.fn().mockResolvedValue('de'),
}))

vi.mock('../../src/server/services/objectService.ts', () => ({
  getObjects: vi.fn().mockImplementation((offset = 0, limit = 20) =>
    Promise.resolve({ objects: [], total: 0, offset: Number(offset), limit: Number(limit) })
  ),
  searchObjects: vi.fn().mockResolvedValue({ objects: [], total: 0 }),
  getObjectById: vi.fn().mockImplementation((id) => (id === 1 ? Promise.resolve(stubObject) : Promise.resolve(null))),
  getObjectsForMap: vi.fn().mockResolvedValue({ objects: [] }),
}))

vi.mock('../../src/server/services/authorService.ts', () => ({
  getAuthors: vi.fn().mockImplementation((offset = 0, limit = 20) =>
    Promise.resolve({ authors: [], total: 0, offset: Number(offset), limit: Number(limit) })
  ),
  getAuthorById: vi.fn().mockImplementation((id) => (id === 1 ? Promise.resolve(stubAuthor) : Promise.resolve(null))),
  updateAuthorRole: vi.fn().mockResolvedValue(undefined),
  updateOwnDescription: vi.fn().mockImplementation((_id, description) =>
    Promise.resolve({
      ok: true,
      description: description == null || String(description).trim() === '' ? null : String(description).trim(),
    })
  ),
}))

vi.mock('../../src/server/services/newsService.ts', () => ({
  getNews: vi.fn().mockResolvedValue({ news: [] }),
  getNewsPostById: vi.fn().mockImplementation((id) => (id === 1 ? Promise.resolve(stubNews) : Promise.resolve(null))),
}))

vi.mock('../../src/server/repositories/newsRepository.ts', () => ({
  findRecent: vi.fn().mockResolvedValue([]),
  getTotalCount: vi.fn().mockResolvedValue(0),
  insertOne: vi.fn().mockResolvedValue(undefined),
}))

vi.mock('../../src/server/services/statisticsService.ts', () => ({
  getLatest: vi.fn().mockResolvedValue({ date: null, models: 0, objects: 0, authors: 0, pendingRequests: 0 }),
  getHistory: vi.fn().mockResolvedValue({
    series: [
      { date: '2020-01-01', models: 100, objects: 500, authors: 20 },
      { date: '2021-06-01', models: 120, objects: 600, authors: 25 },
    ],
  }),
  getAuthorContributionsLeaderboard: vi.fn().mockResolvedValue({
    recentDays: 180,
    recent: [
      { id: 1, name: 'Ada', count: 5 },
      { id: 2, name: 'Bob', count: 3 },
      { id: 3, name: 'Cy', count: 1 },
    ],
    allTime: [
      { id: 2, name: 'Bob', count: 42 },
      { id: 1, name: 'Ada', count: 30 },
      { id: 4, name: 'Dana', count: 12 },
    ],
  }),
}))

vi.mock('../../src/server/repositories/modelgroupRepository.ts', () => ({
  findAll: vi.fn().mockResolvedValue([{ id: 1, name: 'Static', path: 'Static' }]),
  existsById: vi.fn().mockImplementation((id) => Promise.resolve([0, 1].includes(Number(id)))),
}))

vi.mock('../../src/server/repositories/countryRepository.ts', () => ({
  findAll: vi.fn().mockResolvedValue([
    { code: 'DE', name: 'Germany' },
    { code: 'US', name: 'United States' },
  ]),
}))

vi.mock('../../src/server/repositories/modelRepository.ts', () => ({
  findById: vi.fn().mockImplementation((id) => (id === 1 ? Promise.resolve({ id: 1 }) : Promise.resolve(null))),
  findThumbnailById: vi.fn().mockResolvedValue(null),
  findAll: vi.fn().mockResolvedValue({ models: [], total: 0 }),
  findRecent: vi.fn().mockResolvedValue([]),
  insertOne: vi.fn().mockResolvedValue({ id: 1 }),
  updateOne: vi.fn().mockResolvedValue(undefined),
  findIdByPathBasename: vi.fn().mockResolvedValue(null),
}))

vi.mock('../../src/server/repositories/emailQueueRepository.ts', () => ({
  enqueue: vi.fn().mockResolvedValue(1),
}))

vi.mock('../../src/server/repositories/requestRepository.ts', () => ({
  REQUEST_TYPES: {
    OBJECTS_ADD: 'OBJECTS_ADD',
    MODEL_ADD: 'MODEL_ADD',
    MODEL_UPDATE: 'MODEL_UPDATE',
    MODEL_DELETE: 'MODEL_DELETE',
    OBJECT_UPDATE: 'OBJECT_UPDATE',
    OBJECT_DELETE: 'OBJECT_DELETE',
  },
  saveRequest: vi.fn().mockResolvedValue({ id: 1, sig: 'mock-sig' }),
  getRequestBySig: vi.fn().mockResolvedValue(null),
  getPendingRequests: vi.fn().mockResolvedValue({ ok: [], failed: [] }),
  getPendingEntityIds: vi.fn().mockResolvedValue({ objectIds: [], modelIds: [] }),
  deleteRequest: vi.fn().mockResolvedValue(undefined),
  /** Used by enqueuePositionRequestCreated for reviewer email payload (tests ignore result). */
  getRequestContentOverview: vi.fn().mockReturnValue(null),
}))

vi.mock('../../src/server/services/requestExecutor.ts', () => ({
  executeRequest: vi.fn().mockResolvedValue(undefined),
}))

vi.mock('../../src/server/services/airportLookupService.ts', () => ({
  parseIcaoParam: vi.fn((raw) => {
    const t = String(raw ?? '')
      .trim()
      .toUpperCase()
    return /^[A-Z0-9]{3,4}$/.test(t) ? t : null
  }),
  getPositionByIcao: vi.fn().mockImplementation((icao) =>
    icao === 'EDDF'
      ? Promise.resolve({
          icao: 'EDDF',
          name: 'Frankfurt Main Airport',
          latitude: 50.026706,
          longitude: 8.55835,
          airportType: 'large_airport',
          ourAirportsId: 2212,
        })
      : Promise.resolve(null)
  ),
}))
