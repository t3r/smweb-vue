import * as modelRepo from '../repositories/modelRepository.js'
import { listTarEntries, getTarFileContent } from '../utils/tarList.js'
import { parseAC3D, toThreeJSJSON, getTextureNames } from '../utils/ac3dParser.js'

interface ModelRow {
  id: number
  name: string | null
  path: string
  notes: string | null
  modified: unknown
  shared: number
  Author?: { id: number; name: string } | null
  ModelGroup?: { id: number; name: string } | null
}

function toApiModel(row: ModelRow | null): Record<string, unknown> | null {
  if (!row) return null
  const author = row.Author ? { id: row.Author.id, name: row.Author.name } : null
  const group = row.ModelGroup ? { id: row.ModelGroup.id, name: row.ModelGroup.name } : null
  return {
    id: row.id,
    name: row.name,
    filename: row.path,
    description: row.notes,
    author,
    group: group?.name ?? group?.id ?? row.shared,
    /** `fgs_models.mo_shared` / model group id; `0` means static-only (OBJECT_STATIC), not multi-placement shared. */
    groupId: row.shared,
    isStatic: row.shared === 0,
    lastUpdated: row.modified,
  }
}

export async function getModels(
  offset = 0,
  limit = 20,
  group: number | null = null,
  author: number | null = null,
  sortField: string | null = null,
  sortOrder: number | null = null,
  search: string | null = null,
  authorSearch: string | null = null
): Promise<{ models: (Record<string, unknown> | null)[]; total: number; offset: number; limit: number }> {
  const opts: Record<string, unknown> = { offset, limit, group, author }
  if (sortField != null) opts.sortField = sortField
  if (sortOrder != null) opts.sortOrder = sortOrder === 1 ? 1 : -1
  if (search != null && String(search).trim() !== '') opts.search = String(search).trim()
  if (authorSearch != null && String(authorSearch).trim() !== '') opts.authorSearch = String(authorSearch).trim()
  const { models, total } = await modelRepo.findAll(opts as import('../repositories/modelRepository.js').FindAllModelsOptions)
  return {
    models: (models as ModelRow[]).map(toApiModel),
    total,
    offset: Number(offset),
    limit: Number(limit),
  }
}

export async function getRecentModels(limit = 10): Promise<{ models: (Record<string, unknown> | null)[] }> {
  const models = await modelRepo.findRecent(limit) as ModelRow[]
  return { models: models.map(toApiModel) }
}

export async function getModelById(id: number): Promise<Record<string, unknown> | null> {
  const row = await modelRepo.findById(id) as ModelRow | null
  if (!row) return null
  return toApiModel(row)
}

export async function getModelFiles(id: number): Promise<{ files: { name: string; size: number }[] }> {
  const base64 = await modelRepo.findModelfileBase64ById(id)
  if (!base64) return { files: [] }
  try {
    const buffer = Buffer.from(base64, 'base64')
    const entries = listTarEntries(buffer)
    return { files: entries }
  } catch {
    return { files: [] }
  }
}

export async function getModelFileContent(
  id: number,
  filename: string
): Promise<{ buffer: Buffer; filename: string } | null> {
  const base64 = await modelRepo.findModelfileBase64ById(id)
  if (!base64) return null
  try {
    const buffer = Buffer.from(base64, 'base64')
    const content = getTarFileContent(buffer, filename)
    return content !== null ? { buffer: content, filename: filename.trim() } : null
  } catch {
    return null
  }
}

export async function getModelPackageBuffer(id: number): Promise<Buffer | null> {
  const base64 = await modelRepo.findModelfileBase64ById(id)
  if (!base64) return null
  try {
    return Buffer.from(base64, 'base64')
  } catch {
    return null
  }
}

const AC_EXT = '.ac'
const TEXTURE_EXTENSIONS = new Set(['.png', '.jpg', '.jpeg', '.tga', '.bmp', '.gif'])

function hasExtension(name: string, ext: string): boolean {
  const lower = (name || '').toLowerCase()
  return lower === ext || lower.endsWith(ext)
}

export async function getModelPreviewData(
  id: number,
  baseUrl = ''
): Promise<{
  geometry: object
  acFileName: string
  textures: { name: string; url: string }[]
  primaryTexture: string | null
} | null> {
  const base64 = await modelRepo.findModelfileBase64ById(id)
  if (!base64) return null
  let buffer: Buffer
  try {
    buffer = Buffer.from(base64, 'base64')
  } catch {
    return null
  }
  const entries = listTarEntries(buffer)
  const acFile = entries.find((e) => hasExtension(e.name, AC_EXT))
  if (!acFile) return null
  const acContent = getTarFileContent(buffer, acFile.name)
  if (!acContent) return null
  const acText = acContent.toString('utf8')
  const parsed = parseAC3D(acText)
  if (!parsed) return null
  const geometry = toThreeJSJSON(parsed)
  if (!geometry) return null
  const textureNames = getTextureNames(parsed)
  const primaryTexture = textureNames[0] || null
  const textures = entries
    .filter((e) => {
      const lower = e.name.toLowerCase()
      return Array.from(TEXTURE_EXTENSIONS).some((ext) => lower.endsWith(ext))
    })
    .map((e) => ({
      name: e.name,
      url: `${baseUrl}/api/models/${id}/file?name=${encodeURIComponent(e.name)}`,
    }))
  return {
    geometry,
    acFileName: acFile.name,
    textures,
    primaryTexture,
  }
}

/** Mime type by extension for data URLs */
function mimeForFilename(name: string): string {
  const lower = (name || '').toLowerCase()
  if (lower.endsWith('.png')) return 'image/png'
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg'
  if (lower.endsWith('.gif')) return 'image/gif'
  if (lower.endsWith('.bmp')) return 'image/bmp'
  return 'application/octet-stream'
}

/**
 * Build preview data from a model package buffer (gzipped tar).
 * Texture URLs are returned as data URLs so they work without a model id.
 */
export function getPreviewDataFromPackageBuffer(buffer: Buffer): {
  geometry: object
  acFileName: string
  textures: { name: string; url: string }[]
  primaryTexture: string | null
} | null {
  const entries = listTarEntries(buffer)
  const acFile = entries.find((e) => hasExtension(e.name, AC_EXT))
  if (!acFile) return null
  const acContent = getTarFileContent(buffer, acFile.name)
  if (!acContent) return null
  const acText = acContent.toString('utf8')
  const parsed = parseAC3D(acText)
  if (!parsed) return null
  const geometry = toThreeJSJSON(parsed)
  if (!geometry) return null
  const textureNames = getTextureNames(parsed)
  const primaryTexture = textureNames[0] || null
  const textureEntries = entries.filter((e) => {
    const lower = e.name.toLowerCase()
    return Array.from(TEXTURE_EXTENSIONS).some((ext) => lower.endsWith(ext))
  })
  const textures = textureEntries.map((e) => {
    const content = getTarFileContent(buffer, e.name)
    const b64 = content ? content.toString('base64') : ''
    const mime = mimeForFilename(e.name)
    return { name: e.name, url: `data:${mime};base64,${b64}` }
  })
  return {
    geometry,
    acFileName: acFile.name,
    textures,
    primaryTexture,
  }
}
