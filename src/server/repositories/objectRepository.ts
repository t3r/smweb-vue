import { sequelize } from '../config/database.js'
import { QueryTypes } from 'sequelize'

const geoSelect = `
  ob_id, ob_text, ob_gndelev, ob_elevoffset, ob_heading, ob_country, ob_model,
  ob_modified, ob_valid,
  ST_Y(wkb_geometry) AS ob_lat,
  ST_X(wkb_geometry) AS ob_lon
`
const geoSelectWithJoin = `
  o.ob_id, o.ob_text, o.ob_gndelev, o.ob_elevoffset, o.ob_heading, o.ob_country, o.ob_model,
  o.ob_modified, o.ob_valid,
  ST_Y(o.wkb_geometry) AS ob_lat,
  ST_X(o.wkb_geometry) AS ob_lon,
  g.mg_name AS ob_group_name,
  m.mo_shared AS ob_shared
`

export interface MapObjectPosition {
  lat: number
  lon: number
  elevation?: number
  offset?: number
  heading?: number
}

export interface MapObject {
  id: number
  modelId: number
  description: string | null
  type: string | null
  shared: number | null
  position: MapObjectPosition
  country: string | null
  lastUpdated: unknown
}

interface DbRow {
  ob_id: number
  ob_model: number
  ob_text: string | null
  ob_lat: number
  ob_lon: number
  ob_gndelev?: number
  ob_elevoffset?: number
  ob_heading?: number
  ob_country: string | null
  ob_modified: unknown
  ob_group_name?: string | null
  ob_shared?: number | null
}

function rowToObject(row: DbRow): MapObject {
  return {
    id: row.ob_id,
    modelId: row.ob_model,
    description: row.ob_text,
    type: row.ob_group_name != null ? String(row.ob_group_name).trim() : null,
    shared: row.ob_shared != null ? Number(row.ob_shared) : null,
    position: {
      lat: Number(row.ob_lat),
      lon: Number(row.ob_lon),
      elevation: row.ob_gndelev != null ? Number(row.ob_gndelev) : undefined,
      offset: row.ob_elevoffset != null ? Number(row.ob_elevoffset) : undefined,
      heading: row.ob_heading != null ? Number(row.ob_heading) : undefined,
    },
    country: row.ob_country,
    lastUpdated: row.ob_modified,
  }
}

export async function findById(id: number): Promise<MapObject | null> {
  const safeId = Number(id)
  if (!Number.isInteger(safeId) || safeId < 1) return null
  const rows = await sequelize.query(
    `SELECT ${geoSelect} FROM fgs_objects WHERE ob_id = :id AND (ob_deleted IS NULL OR ob_deleted = '1970-01-01 00:00:01'::timestamp)`,
    { replacements: { id: safeId }, type: QueryTypes.SELECT }
  ) as DbRow[]
  return rows[0] ? rowToObject(rows[0]) : null
}

const ACTIVE_OBJECT_SQL = `(ob_deleted IS NULL OR ob_deleted = '1970-01-01 00:00:01'::timestamp)`

/** Count non-deleted objects using this model (for delete-model guards). */
export async function countActiveByModelId(modelId: number): Promise<number> {
  const safeId = Number(modelId)
  if (!Number.isInteger(safeId) || safeId < 1) return 0
  const rows = (await sequelize.query(
    `SELECT count(*)::int AS c FROM fgs_objects WHERE ob_model = :modelId AND ${ACTIVE_OBJECT_SQL}`,
    { replacements: { modelId: safeId }, type: QueryTypes.SELECT }
  )) as { c: number }[]
  return rows[0]?.c ?? 0
}

export interface FindAllObjectsOptions {
  offset?: number
  limit?: number
  model?: number
  country?: string
  description?: string
  group?: number
  sortField?: string
  sortOrder?: number
}

export async function findAndCountAll(options: FindAllObjectsOptions = {}): Promise<{ objects: MapObject[]; total: number }> {
  const { offset = 0, limit = 20, model, country, description, group } = options
  const replacements: Record<string, unknown> = { offset: Number(offset), limit: Number(limit) }
  const conditions = ['(o.ob_deleted IS NULL OR o.ob_deleted = \'1970-01-01 00:00:01\'::timestamp)']
  if (group != null) {
    conditions.push('m.mo_shared = :group')
    replacements.group = Number(group)
  }
  if (model != null) {
    conditions.push('o.ob_model = :model')
    replacements.model = model
  }
  if (country != null) {
    conditions.push('LOWER(TRIM(o.ob_country)) = LOWER(TRIM(:country))')
    replacements.country = String(country).trim().toLowerCase().slice(0, 2)
  }
  if (description != null && description !== '') {
    conditions.push('o.ob_text ILIKE :desc')
    replacements.desc = `%${description}%`
  }
  const where = conditions.join(' AND ')
  const fromClause = `FROM fgs_objects o
    LEFT JOIN fgs_models m ON o.ob_model = m.mo_id
    LEFT JOIN fgs_modelgroups g ON m.mo_shared = g.mg_id
    WHERE ${where}`

  const countResult = await sequelize.query(
    `SELECT count(*)::int AS c ${fromClause}`,
    { replacements, type: QueryTypes.SELECT }
  ) as { c: number }[]
  const total = countResult[0]?.c ?? 0

  const sortColumns: Record<string, string> = {
    id: 'o.ob_id',
    description: 'o.ob_text',
    type: 'g.mg_name',
    country: 'o.ob_country',
    lastUpdated: 'o.ob_modified',
    lat: 'ST_Y(o.wkb_geometry)',
    lon: 'ST_X(o.wkb_geometry)',
  }
  const sortKey = options.sortField && sortColumns[options.sortField] ? options.sortField : null
  const sortDir = options.sortOrder === 1 ? 'ASC' : 'DESC'
  const orderCol = sortKey ? sortColumns[sortKey] : 'o.ob_modified'
  const orderClause = `ORDER BY ${orderCol} ${sortDir} NULLS LAST`

  const rows = await sequelize.query(
    `SELECT ${geoSelectWithJoin} ${fromClause} ${orderClause} LIMIT :limit OFFSET :offset`,
    { replacements, type: QueryTypes.SELECT }
  ) as DbRow[]
  return { objects: rows.map(rowToObject), total }
}

export interface Bbox {
  minLng: number
  minLat: number
  maxLng: number
  maxLat: number
}

export async function findForMap(bbox: Bbox, limit = 2000): Promise<{ objects: MapObject[] }> {
  const { minLng, minLat, maxLng, maxLat } = bbox
  const replacements = {
    minLng: Number(minLng),
    minLat: Number(minLat),
    maxLng: Number(maxLng),
    maxLat: Number(maxLat),
    limit: Math.min(Math.max(1, Number(limit) || 2000), 5000),
  }
  const rows = await sequelize.query(
    `SELECT ${geoSelectWithJoin}
     FROM fgs_objects o
     LEFT JOIN fgs_models m ON o.ob_model = m.mo_id
     LEFT JOIN fgs_modelgroups g ON m.mo_shared = g.mg_id
     WHERE (o.ob_deleted IS NULL OR o.ob_deleted = '1970-01-01 00:00:01'::timestamp)
       AND ST_X(o.wkb_geometry) BETWEEN :minLng AND :maxLng
       AND ST_Y(o.wkb_geometry) BETWEEN :minLat AND :maxLat
     ORDER BY o.ob_id ASC
     LIMIT :limit`,
    { replacements, type: QueryTypes.SELECT }
  ) as DbRow[]
  return { objects: rows.map(rowToObject) }
}

const bboxCondition = `(o.ob_deleted IS NULL OR o.ob_deleted = '1970-01-01 00:00:01'::timestamp)
  AND ST_X(o.wkb_geometry) BETWEEN :minLng AND :maxLng
  AND ST_Y(o.wkb_geometry) BETWEEN :minLat AND :maxLat`

export async function findCountInBbox(bbox: Bbox): Promise<number> {
  const { minLng, minLat, maxLng, maxLat } = bbox
  const replacements = { minLng: Number(minLng), minLat: Number(minLat), maxLng: Number(maxLng), maxLat: Number(maxLat) }
  const rows = await sequelize.query(
    `SELECT count(*)::int AS c FROM fgs_objects o WHERE ${bboxCondition}`,
    { replacements, type: QueryTypes.SELECT }
  ) as { c: number }[]
  return rows[0]?.c ?? 0
}

const GRID_COLS_DEFAULT = 16
const GRID_ROWS_DEFAULT = 16

export async function findGridCountsInBbox(
  bbox: Bbox,
  cols = GRID_COLS_DEFAULT,
  rows = GRID_ROWS_DEFAULT
): Promise<{ cells: { x: number; y: number; count: number }[]; cols: number; rows: number }> {
  const { minLng, minLat, maxLng, maxLat } = bbox
  const c = Math.max(1, Math.min(50, Number(cols) || GRID_COLS_DEFAULT))
  const r = Math.max(1, Math.min(50, Number(rows) || GRID_ROWS_DEFAULT))
  const replacements = {
    minLng: Number(minLng),
    minLat: Number(minLat),
    maxLng: Number(maxLng),
    maxLat: Number(maxLat),
    cols: c,
    rows: r,
  }
  const raw = await sequelize.query(
    `SELECT
       LEAST(:cols - 1, GREATEST(0, FLOOR((ST_X(o.wkb_geometry) - :minLng) / NULLIF(:maxLng - :minLng, 0) * :cols)::int)) AS gx,
       LEAST(:rows - 1, GREATEST(0, FLOOR((ST_Y(o.wkb_geometry) - :minLat) / NULLIF(:maxLat - :minLat, 0) * :rows)::int)) AS gy,
       count(*)::int AS cnt
     FROM fgs_objects o
     WHERE ${bboxCondition}
     GROUP BY 1, 2
     ORDER BY 2, 1`,
    { replacements, type: QueryTypes.SELECT }
  ) as { gx: number; gy: number; cnt: number }[]
  const cells = (raw || []).map((row) => ({ x: row.gx, y: row.gy, count: row.cnt }))
  return { cols: c, rows: r, cells }
}

export interface InsertObjectData {
  description?: string
  longitude: number
  latitude: number
  country: string
  modelId: number
  offset?: number | null
  orientation?: number
}

export async function insertOne(data: InsertObjectData): Promise<{ id: number }> {
  const {
    description = '',
    longitude,
    latitude,
    country,
    modelId,
    offset = null,
    orientation = 0,
  } = data
  const elevoffset = (offset == null || offset === ('' as unknown)) ? null : Number(offset)
  const rows = await sequelize.query(
    `INSERT INTO fgs_objects (ob_id, ob_text, wkb_geometry, ob_gndelev, ob_elevoffset, ob_heading, ob_country, ob_model, ob_group)
     VALUES (DEFAULT, :desc, ST_SetSRID(ST_MakePoint(:lon::float, :lat::float), 4326), -9999, :elevoffset, :orientation, :country, :modelId, 1)
     RETURNING ob_id`,
    {
      replacements: {
        desc: description,
        lon: Number(longitude),
        lat: Number(latitude),
        elevoffset,
        orientation: Number(orientation),
        country: String(country).trim().toLowerCase().slice(0, 2),
        modelId: Number(modelId),
      },
      type: QueryTypes.SELECT,
    }
  ) as { ob_id: number }[]
  return { id: rows[0]?.ob_id }
}

export interface UpdateObjectData {
  description?: string
  longitude: number
  latitude: number
  country: string
  modelId: number
  offset?: number | null
  orientation?: number
}

export async function updateOne(id: number, data: UpdateObjectData): Promise<void> {
  const {
    description,
    longitude,
    latitude,
    country,
    modelId,
    offset = null,
    orientation = 0,
  } = data
  const elevoffset = (offset == null || offset === ('' as unknown)) ? null : Number(offset)
  await sequelize.query(
    `UPDATE fgs_objects SET
       ob_text = :desc,
       wkb_geometry = ST_SetSRID(ST_MakePoint(:lon::float, :lat::float), 4326),
       ob_country = :country,
       ob_elevoffset = :elevoffset,
       ob_heading = :orientation,
       ob_model = :modelId,
       ob_group = 1
     WHERE ob_id = :id`,
    {
      replacements: {
        id: Number(id),
        desc: description ?? '',
        lon: Number(longitude),
        lat: Number(latitude),
        country: String(country).trim().toLowerCase().slice(0, 2),
        elevoffset,
        orientation: Number(orientation),
        modelId: Number(modelId),
      },
    }
  )
}

export async function deleteOne(id: number): Promise<void> {
  await sequelize.query(`DELETE FROM fgs_objects WHERE ob_id = :id`, {
    replacements: { id: Number(id) },
  })
}

/**
 * Soft-delete an object: set ob_valid = false and ob_deleted = current timestamp.
 * Used when accepting OBJECT_DELETE position requests.
 */
export async function softDeleteOne(id: number): Promise<void> {
  await sequelize.query(
    `UPDATE fgs_objects SET ob_valid = false, ob_deleted = CURRENT_TIMESTAMP WHERE ob_id = :id`,
    { replacements: { id: Number(id) } }
  )
}
