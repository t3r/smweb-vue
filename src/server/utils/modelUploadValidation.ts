/**
 * Legacy PHP parity checks for MODEL_ADD (FormChecker, ModelFilesValidator, FilenamesValidator).
 * See classes/FormChecker.php, classes/submission/*.php
 */
import path from 'node:path'
import { XMLParser } from 'fast-xml-parser'
import sharp from 'sharp'
import * as modelRepo from '../repositories/modelRepository.js'
import * as modelgroupRepo from '../repositories/modelgroupRepository.js'
import { extractTarToMap } from './tarList.js'

/** Same list as PHP ModelFilesValidator::$validDimension */
const VALID_POW2 = new Set([
  1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192,
])

export const MODEL_UPLOAD_MAX_FILE_BYTES = 2_000_000

const RE_AC3D_FILENAME = /^[a-zA-Z0-9_.-]+\.(ac|AC)$/u
const RE_XML_FILENAME = /^[a-zA-Z0-9_.-]+\.(xml|XML)$/u
const RE_PNG_FILENAME = /^[a-zA-Z0-9_.-]+\.(png|PNG)$/u
const RE_LONG_LAT = /^[-+]?([0-9]*\.[0-9]+|[0-9]+)$/u
const RE_EMAIL = /^[0-9a-zA-Z_.-]+@[0-9a-z_-]+\.[0-9a-zA-Z_.-]+$/u
const RE_MODEL_GROUP_ID = /^[0-9]+$/
const RE_AUTHOR_ID = /^[0-9]{1,3}$/

const XML_DECL_RE = /^<\?xml\s+version="1\.0"\s+encoding="UTF-8"\s*\?>/i
/** Disallow DTD: mitigates DoS from huge internal subsets; external SYSTEM is unsupported by the parser but we reject explicitly. */
const DOCTYPE_RE = /<!DOCTYPE[\s\[]/i

/**
 * Safe defaults for untrusted model XML (uploads). Entity expansion off; no network/file resolution.
 * @see https://github.com/NaturalIntelligence/fast-xml-parser — external SYSTEM entities are rejected; internal entities stay inert when disabled.
 */
const MODEL_XML_PARSER_OPTIONS = {
  ignoreAttributes: false,
  trimValues: true,
  parseTagValue: false,
  processEntities: false,
  /** Library option name is `removeNSPrefix` (not `resolveNameSpace`). `false` = keep `prefix:local` names; matches parser default. */
  removeNSPrefix: false,
} as const

function stripUtf8Bom(buf: Buffer): Buffer {
  if (buf.length >= 3 && buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf) {
    return buf.subarray(3)
  }
  return buf
}

/** CRLF / CR → LF (legacy dos2unix on AC/XML). */
export function normalizeTextFileBuffer(buf: Buffer): Buffer {
  let s = stripUtf8Bom(buf).toString('utf8')
  s = s.replace(/\r\n/g, '\n').replace(/\r/g, '\n')
  return Buffer.from(s, 'utf8')
}

/** Reject path separators and traversal in upload names; name must be a single flat segment. */
export function assertFlatUploadFilename(originalName: string): string | null {
  const base = path.basename(originalName)
  if (!base || base !== originalName.trim()) return null
  if (base.includes('..') || /[/\\]/.test(base)) return null
  return base
}

export function validateAc3dXmlPngNames(acName: string, xmlName: string | null, pngNames: string[]): string | null {
  if (!RE_AC3D_FILENAME.test(acName)) {
    return "AC3D filename must be *.ac using only letters, digits, '_', '.', or '-'."
  }
  if (xmlName && !RE_XML_FILENAME.test(xmlName)) {
    return "XML filename must be *.xml using only letters, digits, '_', '.', or '-'."
  }
  for (const p of pngNames) {
    if (p && !RE_PNG_FILENAME.test(p)) {
      return "Each texture must be *.png with only letters, digits, '_', '.', or '-'."
    }
  }
  if (xmlName) {
    const acStem = path.parse(acName).name
    const xmlStem = path.parse(xmlName).name
    if (acStem !== xmlStem) {
      return `XML and AC files must share the same base name (e.g. tower.ac and tower.xml); got "${acName}" and "${xmlName}".`
    }
  }
  return null
}

function extractTextureRefsFromAc(acText: string): string[] {
  const refs: string[] = []
  for (const line of acText.split(/\n/)) {
    const m = line.match(/^\s*texture\s+"([^"]+)"/i)
    if (m?.[1]) refs.push(m[1])
  }
  return refs
}

function readXmlPathElement(xmlStr: string): { ok: true; path: string } | { ok: false; error: string } {
  const trimmed = xmlStr.trimStart()
  if (!XML_DECL_RE.test(trimmed)) {
    return { ok: false, error: 'XML must start with <?xml version="1.0" encoding="UTF-8" ?>.' }
  }
  if (DOCTYPE_RE.test(xmlStr)) {
    return { ok: false, error: 'DOCTYPE is not allowed in model XML (security).' }
  }
  try {
    const parser = new XMLParser(MODEL_XML_PARSER_OPTIONS)
    const doc = parser.parse(xmlStr) as Record<string, unknown>
    const pl = doc.PropertyList as Record<string, unknown> | undefined
    const raw = pl?.path ?? doc.path
    const p = raw == null ? '' : String(raw).trim()
    if (!p) {
      return { ok: false, error: 'XML must contain a <path> element matching the AC filename.' }
    }
    return { ok: true, path: p }
  } catch {
    return { ok: false, error: 'XML is not well-formed or could not be parsed.' }
  }
}

export async function validateModelFileBuffers(params: {
  acBuffer: Buffer
  acFilename: string
  xmlBuffer: Buffer | null
  xmlFilename: string | null
  pngFiles: { name: string; buffer: Buffer }[]
}): Promise<string | null> {
  const { acBuffer, acFilename, xmlBuffer, xmlFilename, pngFiles } = params

  const acText = stripUtf8Bom(acBuffer).toString('utf8')
  const firstLine = acText.split(/\n/, 1)[0] ?? ''
  if (!firstLine.startsWith('AC3D')) {
    return 'The AC file does not appear to be valid AC3D (first line must start with "AC3D").'
  }

  const pngNameSet = new Set(pngFiles.map((f) => f.name))
  const textureRefs = extractTextureRefsFromAc(acText)
  for (const ref of textureRefs) {
    if (!pngNameSet.has(ref)) {
      return `AC3D references texture "${ref}" but no uploaded PNG with that exact name was provided.`
    }
  }

  if (xmlBuffer && xmlFilename) {
    const xmlStr = stripUtf8Bom(xmlBuffer).toString('utf8')
    const pathResult = readXmlPathElement(xmlStr)
    if (pathResult.ok === false) return pathResult.error
    if (pathResult.path !== acFilename) {
      return `The <path> in the XML file must be "${acFilename}" (the AC filename); found "${pathResult.path}".`
    }
  }

  return validatePngBuffers(pngFiles)
}

async function validatePngBuffers(pngFiles: { name: string; buffer: Buffer }[]): Promise<string | null> {
  for (const { name, buffer } of pngFiles) {
    try {
      const meta = await sharp(buffer).metadata()
      if (meta.format !== 'png') {
        return `Texture "${name}" is not a valid PNG file.`
      }
      const w = meta.width ?? 0
      const h = meta.height ?? 0
      if (!VALID_POW2.has(w) || !VALID_POW2.has(h)) {
        return `Texture "${name}" must have width and height that are powers of 2 (e.g. 256, 512).`
      }
    } catch {
      return `Texture "${name}" could not be read as a PNG image.`
    }
  }
  return null
}

export function assertFileSizeUnderLimit(size: number, label: string): string | null {
  if (size > MODEL_UPLOAD_MAX_FILE_BYTES) {
    return `${label} exceeds ${MODEL_UPLOAD_MAX_FILE_BYTES / 1_000_000} MB.`
  }
  return null
}

function isCommentField(value: string, maxLen: number, allowEmpty: boolean): boolean {
  if (value === '') return allowEmpty
  return value.length <= maxLen && !value.includes('|')
}

function isLatitude(n: number, raw: string): boolean {
  return (
    raw.length <= 20 &&
    Number.isFinite(n) &&
    n <= 90 &&
    n >= -90 &&
    RE_LONG_LAT.test(raw.trim())
  )
}

function isLongitude(n: number, raw: string): boolean {
  return (
    raw.length <= 20 &&
    Number.isFinite(n) &&
    n <= 180 &&
    n >= -180 &&
    RE_LONG_LAT.test(raw.trim())
  )
}

/** Offset in open interval (-1000, 1000) per PHP FormChecker::isOffset */
function isOffsetValid(n: number, raw: string): boolean {
  return (
    raw.length <= 20 &&
    RE_LONG_LAT.test(raw.trim()) &&
    n > -1000 &&
    n < 1000
  )
}

function isHeadingValid(n: number, raw: string): boolean {
  return (
    raw.length <= 20 &&
    RE_LONG_LAT.test(raw.trim()) &&
    n >= 0 &&
    n < 360
  )
}

export async function validateModelAddFormFields(input: {
  name: string
  description: string
  comment: string
  email: string
  groupId: number
  authorId: number
  authorNew?: { name: string; email: string } | null
  latitudeRaw: string
  longitudeRaw: string
  offsetRaw: string | null | undefined
  headingRaw: string | null | undefined
}): Promise<string | null> {
  const {
    name,
    description,
    comment,
    email,
    groupId,
    authorId,
    authorNew,
    latitudeRaw,
    longitudeRaw,
    offsetRaw,
    headingRaw,
  } = input

  if (!name.trim()) return 'Model name is required.'
  if (!isCommentField(name, 100, false)) {
    return 'Model name must be at most 100 characters and must not contain |.'
  }

  if (!isCommentField(description, 100, true)) {
    return 'Description must be at most 100 characters and must not contain |.'
  }

  if (!isCommentField(comment, 100, true)) {
    return 'Comment must be at most 100 characters and must not contain |.'
  }

  if (email.length > 50 || !RE_EMAIL.test(email)) {
    return 'Please enter a valid email address (max 50 characters).'
  }

  if (!Number.isInteger(groupId) || groupId < 0 || !RE_MODEL_GROUP_ID.test(String(groupId))) {
    return 'Please select a valid model family.'
  }
  if (!(await modelgroupRepo.existsById(groupId))) {
    return 'The selected model family does not exist.'
  }

  const aidStr = String(authorId)
  if (!RE_AUTHOR_ID.test(aidStr) || authorId < 1) {
    return 'Please select a valid author.'
  }

  if (authorId === 1) {
    if (!authorNew?.name?.trim() || !authorNew?.email?.trim()) {
      return 'When author is "Other", name and email are required.'
    }
    if (!isCommentField(authorNew.name.trim(), 100, false)) {
      return 'Author name must be at most 100 characters and must not contain |.'
    }
    if (authorNew.email.length > 50 || !RE_EMAIL.test(authorNew.email.trim())) {
      return 'Please check the new author email address.'
    }
  }

  const lat = Number(latitudeRaw)
  const lon = Number(longitudeRaw)
  if (!isLatitude(lat, latitudeRaw)) return 'Latitude is invalid (must be between -90 and 90).'
  if (!isLongitude(lon, longitudeRaw)) return 'Longitude is invalid (must be between -180 and 180).'

  const offStr = offsetRaw != null && offsetRaw !== '' ? String(offsetRaw).trim() : ''
  if (offStr !== '') {
    const off = Number(offStr)
    if (!isOffsetValid(off, offStr)) {
      return 'Elevation offset must be strictly between -1000 and 1000.'
    }
  }

  const headStr = headingRaw != null && headingRaw !== '' ? String(headingRaw).trim() : '0'
  const head = Number(headStr)
  if (!isHeadingValid(head, headStr)) {
    return 'Heading must be from 0 (inclusive) to 360 (exclusive).'
  }

  return null
}

export async function assertModelPathAvailable(moPath: string): Promise<string | null> {
  const p = String(moPath || '').trim()
  if (!p) return 'Model path (filename) is empty.'
  const existing = await modelRepo.findIdByPathBasename(p)
  if (existing != null) {
    return `Filename "${p}" is already used by another model.`
  }
  return null
}

/** Allow keeping the same path for `modelId`, or taking a path not used by another model. */
export async function assertModelPathForUpdate(modelId: number, moPath: string): Promise<string | null> {
  const p = String(moPath || '').trim()
  if (!p) return 'Model path (filename) is empty.'
  const existing = await modelRepo.findIdByPathBasename(p)
  if (existing != null && existing !== modelId) {
    return `Filename "${p}" is already used by another model.`
  }
  return null
}

export async function validateModelUpdateFormFields(input: {
  name: string
  description: string
  comment: string
  email: string
  groupId: number
  authorId: number
  authorNew?: { name: string; email: string } | null
}): Promise<string | null> {
  const { name, description, comment, email, groupId, authorId, authorNew } = input

  if (!name.trim()) return 'Model name is required.'
  if (!isCommentField(name, 100, false)) {
    return 'Model name must be at most 100 characters and must not contain |.'
  }

  if (!isCommentField(description, 100, true)) {
    return 'Description must be at most 100 characters and must not contain |.'
  }

  if (!isCommentField(comment, 100, true)) {
    return 'Comment must be at most 100 characters and must not contain |.'
  }

  if (email.length > 50 || !RE_EMAIL.test(email)) {
    return 'Please enter a valid email address (max 50 characters).'
  }

  if (!Number.isInteger(groupId) || groupId < 0 || !RE_MODEL_GROUP_ID.test(String(groupId))) {
    return 'Please select a valid model family.'
  }
  if (!(await modelgroupRepo.existsById(groupId))) {
    return 'The selected model family does not exist.'
  }

  const aidStr = String(authorId)
  if (!RE_AUTHOR_ID.test(aidStr) || authorId < 1) {
    return 'Please select a valid author.'
  }

  if (authorId === 1) {
    if (!authorNew?.name?.trim() || !authorNew?.email?.trim()) {
      return 'When author is "Other", name and email are required.'
    }
    if (!isCommentField(authorNew.name.trim(), 100, false)) {
      return 'Author name must be at most 100 characters and must not contain |.'
    }
    if (authorNew.email.length > 50 || !RE_EMAIL.test(authorNew.email.trim())) {
      return 'Please check the new author email address.'
    }
  }

  return null
}

/** Validate a gzipped tarball (base64) from JSON MODEL_ADD submissions. */
export async function validateThumbnailBase64Input(b64: string): Promise<string | null> {
  try {
    const buf = Buffer.from(b64, 'base64')
    if (!buf.length) return 'Thumbnail data is empty.'
    await sharp(buf).metadata()
    return null
  } catch {
    return 'Thumbnail is not a valid image.'
  }
}

export async function validateModelfileBase64Package(
  modelfileBase64: string,
  expectedMoPath: string
): Promise<string | null> {
  let buffer: Buffer
  try {
    buffer = Buffer.from(modelfileBase64, 'base64')
  } catch {
    return 'Model package is not valid base64.'
  }
  const map = extractTarToMap(buffer)
  if (map.size === 0) return 'Model package is empty or not a valid gzip/tar archive.'

  const acEntries: { name: string; buffer: Buffer }[] = []
  const xmlEntries: { name: string; buffer: Buffer }[] = []
  const pngEntries: { name: string; buffer: Buffer }[] = []

  for (const [name, buf] of map) {
    const flat = assertFlatUploadFilename(name)
    if (!flat) return `Invalid file name in archive: "${name}".`
    const sizeErr = assertFileSizeUnderLimit(buf.length, `Archive file "${flat}"`)
    if (sizeErr) return sizeErr
    const lower = flat.toLowerCase()
    if (lower.endsWith('.ac')) acEntries.push({ name: flat, buffer: buf })
    else if (lower.endsWith('.xml')) xmlEntries.push({ name: flat, buffer: buf })
    else if (lower.endsWith('.png')) pngEntries.push({ name: flat, buffer: buf })
  }

  if (acEntries.length !== 1) {
    return 'Model package must contain exactly one .ac file.'
  }
  const ac = acEntries[0]!
  if (xmlEntries.length > 1) {
    return 'Model package must contain at most one .xml file.'
  }
  const xml = xmlEntries[0] ?? null

  const pathFlat = assertFlatUploadFilename(expectedMoPath)
  if (!pathFlat) return 'Model filename (path) is invalid.'
  if (xml) {
    if (pathFlat !== xml.name) return `Model path must match the XML file name in the archive ("${xml.name}").`
  } else if (pathFlat !== ac.name) {
    return `Model path must match the AC file name in the archive ("${ac.name}").`
  }

  const nameErr = validateAc3dXmlPngNames(ac.name, xml?.name ?? null, pngEntries.map((e) => e.name))
  if (nameErr) return nameErr

  return validateModelFileBuffers({
    acBuffer: normalizeTextFileBuffer(ac.buffer),
    acFilename: ac.name,
    xmlBuffer: xml ? normalizeTextFileBuffer(xml.buffer) : null,
    xmlFilename: xml?.name ?? null,
    pngFiles: pngEntries,
  })
}
