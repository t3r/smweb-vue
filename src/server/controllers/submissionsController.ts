import type { Request, Response } from 'express'
import * as requestRepo from '../repositories/requestRepository.js'
import * as modelRepo from '../repositories/modelRepository.js'
import * as objectRepo from '../repositories/objectRepository.js'
import { logDbError, CLIENT_ERROR_MESSAGE } from '../utils/dbFallback.js'
import { buildTarGz } from '../utils/buildTarGz.js'
import { convertToThumbnailJpeg } from '../utils/thumbnailImage.js'
import { isStgParseFailure, parseStgObjectLines, STG_MASS_IMPORT_MAX_LINES } from '../utils/stgObjectLines.js'
import { enqueuePositionRequestCreated } from '../services/emailQueueEnqueue.js'
import * as countryService from '../services/countryService.js'
import {
  assertFileSizeUnderLimit,
  assertFlatUploadFilename,
  assertModelPathAvailable,
  normalizeTextFileBuffer,
  validateAc3dXmlPngNames,
  validateModelAddFormFields,
  validateModelFileBuffers,
  validateModelfileBase64Package,
  validateThumbnailBase64Input,
} from '../utils/modelUploadValidation.js'

export async function submitObjectDelete(req: Request, res: Response): Promise<void> {
  try {
    const body = (req.body || {}) as { objId?: unknown; comment?: string; email?: string }
    const email = typeof body.email === 'string' ? body.email.trim() : ''
    if (!email) {
      res.status(400).json({ error: 'email is required' })
      return
    }
    const objId = body.objId != null ? Number(body.objId) : null
    if (objId == null || !Number.isInteger(objId) || objId < 1) {
      res.status(400).json({ error: 'objId is required and must be a positive integer' })
      return
    }
    const { objectIds: pendingObjectIds } = await requestRepo.getPendingEntityIds()
    if (pendingObjectIds.includes(objId)) {
      res.status(409).json({ error: 'A pending request already exists for this object' })
      return
    }
    const comment = typeof body.comment === 'string' ? body.comment.trim() : ''
    const content = { objId }
    const { id, sig } = await requestRepo.saveRequest(
      requestRepo.REQUEST_TYPES.OBJECT_DELETE,
      content,
      email,
      comment
    )
    await enqueuePositionRequestCreated({
      requestId: id,
      sig,
      requestType: requestRepo.REQUEST_TYPES.OBJECT_DELETE,
    })
    res.status(201).json({ id, sig, message: 'Delete request queued for review' })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/object/delete')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function submitObjectUpdate(req: Request, res: Response): Promise<void> {
  try {
    const body = (req.body || {}) as {
      objectId?: unknown
      modelId?: unknown
      description?: string
      country?: string
      longitude?: unknown
      latitude?: unknown
      offset?: unknown
      orientation?: unknown
      comment?: string
      email?: string
    }
    const objectId = body.objectId != null ? Number(body.objectId) : null
    if (objectId == null || !Number.isInteger(objectId) || objectId < 1) {
      res.status(400).json({ error: 'objectId is required and must be a positive integer' })
      return
    }
    const longitude = Number(body.longitude)
    const latitude = Number(body.latitude)
    if (!Number.isFinite(longitude) || !Number.isFinite(latitude)) {
      res.status(400).json({ error: 'longitude and latitude are required and must be numbers' })
      return
    }
    const modelId = body.modelId != null ? Number(body.modelId) : null
    const country = typeof body.country === 'string' ? body.country.trim().toLowerCase().slice(0, 2) : ''
    const description = typeof body.description === 'string' ? body.description.trim() : ''
    const offset = body.offset != null && body.offset !== '' ? Number(body.offset) : null
    const orientation = body.orientation != null && Number.isFinite(Number(body.orientation)) ? Number(body.orientation) : 0
    const email = typeof body.email === 'string' ? body.email.trim() : ''
    if (!email) {
      res.status(400).json({ error: 'email is required' })
      return
    }
    const { objectIds: pendingObjectIds } = await requestRepo.getPendingEntityIds()
    if (pendingObjectIds.includes(objectId)) {
      res.status(409).json({ error: 'A pending request already exists for this object' })
      return
    }
    const content = {
      objectId,
      modelId: modelId ?? 0,
      description,
      country: country || null,
      longitude,
      latitude,
      offset: offset === null || (offset as unknown) === '' ? null : offset,
      orientation,
    }
    const comment = typeof body.comment === 'string' ? body.comment.trim() : ''
    const { id, sig } = await requestRepo.saveRequest(
      requestRepo.REQUEST_TYPES.OBJECT_UPDATE,
      content,
      email,
      comment
    )
    await enqueuePositionRequestCreated({
      requestId: id,
      sig,
      requestType: requestRepo.REQUEST_TYPES.OBJECT_UPDATE,
    })
    res.status(201).json({ id, sig, message: 'Update request queued for review' })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/object/update')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function submitModelDelete(req: Request, res: Response): Promise<void> {
  try {
    const body = (req.body || {}) as { modelId?: unknown; comment?: string; email?: string }
    const email = typeof body.email === 'string' ? body.email.trim() : ''
    if (!email) {
      res.status(400).json({ error: 'email is required' })
      return
    }
    const modelId = body.modelId != null ? Number(body.modelId) : null
    if (modelId == null || !Number.isInteger(modelId) || modelId < 1) {
      res.status(400).json({ error: 'modelId is required and must be a positive integer' })
      return
    }
    const { modelIds: pendingModelIds } = await requestRepo.getPendingEntityIds()
    if (pendingModelIds.includes(modelId)) {
      res.status(409).json({ error: 'A pending request already exists for this model' })
      return
    }
    const objectCount = await objectRepo.countActiveByModelId(modelId)
    if (objectCount > 0) {
      res.status(409).json({
        error: `Cannot delete this model while ${objectCount} object placement(s) still use it. Remove those objects first.`,
      })
      return
    }
    const comment = typeof body.comment === 'string' ? body.comment.trim() : ''
    const user = req.user as { id?: number } | undefined
    const content: { modelId: number; modifiedByAuthorId?: number } = { modelId }
    if (user?.id != null && Number.isInteger(user.id)) content.modifiedByAuthorId = user.id
    const { id, sig } = await requestRepo.saveRequest(
      requestRepo.REQUEST_TYPES.MODEL_DELETE,
      content,
      email,
      comment
    )
    await enqueuePositionRequestCreated({
      requestId: id,
      sig,
      requestType: requestRepo.REQUEST_TYPES.MODEL_DELETE,
    })
    res.status(201).json({ id, sig, message: 'Delete request queued for review' })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/model/delete')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function previewStgObjects(req: Request, res: Response): Promise<void> {
  try {
    const stg = typeof (req.body as { stg?: unknown })?.stg === 'string' ? (req.body as { stg: string }).stg : ''
    const result = await parseStgObjectLines(stg)
    if (isStgParseFailure(result)) {
      res.json({ ok: false, maxLines: STG_MASS_IMPORT_MAX_LINES, lineErrors: result.lineErrors })
      return
    }
    res.json({
      ok: true,
      maxLines: STG_MASS_IMPORT_MAX_LINES,
      count: result.objects.length,
      objects: result.objects.map((o) => ({
        modelId: o.modelId,
        lat: o.lat,
        lon: o.lon,
        country: o.country,
        elevationOffset: o.elevationOffset,
        heading: o.heading,
      })),
    })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/objects/stg-preview')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function submitObjects(req: Request, res: Response): Promise<void> {
  try {
    const body = (req.body || {}) as {
      objects?: unknown[]
      stg?: string
      comment?: string
      email?: string
    }
    const fromBody = typeof body.email === 'string' ? body.email.trim() : ''
    const fromSession = (req.user as { email?: string } | undefined)?.email?.trim() || ''
    const emailTrimmed = fromBody || fromSession
    if (!emailTrimmed) {
      res.status(400).json({ error: 'email is required (sign in or provide an email address)' })
      return
    }
    if (!body.comment || typeof body.comment !== 'string' || body.comment.trim().length === 0) {
      res.status(400).json({ error: 'comment is required' })
      return
    }

    let objects: unknown[]
    if (typeof body.stg === 'string' && body.stg.trim().length > 0) {
      const parsed = await parseStgObjectLines(body.stg)
      if (isStgParseFailure(parsed)) {
        res.status(400).json({ error: 'Invalid STG lines', lineErrors: parsed.lineErrors })
        return
      }
      objects = parsed.objects.map((o) => ({
        modelId: o.modelId,
        lat: o.lat,
        lon: o.lon,
        country: o.country,
        elevationOffset: o.elevationOffset,
        heading: o.heading,
        description: o.description,
      }))
    } else if (Array.isArray(body.objects) && body.objects.length > 0) {
      objects = body.objects
    } else {
      res.status(400).json({ error: 'Provide either a non-empty objects array or stg text' })
      return
    }

    const content: Record<string, unknown>[] = []
    for (let i = 0; i < objects.length; i++) {
      const o = objects[i] as Record<string, unknown>
      const modelId = Number(o.modelId)
      const lat = Number(o.lat)
      const lon = Number(o.lon)
      const rawCountry = o.country
      let country: string | null = null
      if (rawCountry != null && String(rawCountry).trim() !== '') {
        const c = String(rawCountry).trim().toLowerCase().slice(0, 2)
        if (c.length === 2) country = c
        else {
          res.status(400).json({ error: `object[${i}]: country must be a 2-letter code or omitted for ocean / no polygon` })
          return
        }
      }
      if (!modelId || !Number.isFinite(lat) || !Number.isFinite(lon)) {
        res.status(400).json({ error: `object[${i}]: modelId, lat, and lon are required` })
        return
      }
      const existing = await modelRepo.findById(modelId)
      if (!existing) {
        res.status(400).json({ error: `object[${i}]: model ${modelId} not found` })
        return
      }
      const offset = o.elevationOffset != null ? Number(o.elevationOffset) : null
      const orientation = o.heading != null ? Number(o.heading) : 0
      content.push({
        description: (String(o.description || '')).slice(0, 100),
        longitude: lon,
        latitude: lat,
        offset: (offset === null || offset === ('' as unknown)) ? 'NULL' : offset,
        orientation,
        country,
        modelId,
      })
    }

    const { id, sig } = await requestRepo.saveRequest(
      requestRepo.REQUEST_TYPES.OBJECTS_ADD,
      content,
      emailTrimmed,
      body.comment.trim()
    )
    await enqueuePositionRequestCreated({
      requestId: id,
      sig,
      requestType: requestRepo.REQUEST_TYPES.OBJECTS_ADD,
    })
    res.status(201).json({ id, sig, message: 'Queued for review' })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/objects')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

export async function submitModel(req: Request, res: Response): Promise<void> {
  try {
    const body = (req.body || {}) as Record<string, unknown>
    const {
      name,
      filename,
      description,
      authorId,
      groupId,
      longitude,
      latitude,
      offset,
      heading,
      thumbnailBase64,
      modelfileBase64,
      authorNew,
      gplAccepted,
    } = body

    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      res.status(400).json({ error: 'name is required' })
      return
    }
    if (!filename || typeof filename !== 'string' || filename.trim().length === 0) {
      res.status(400).json({ error: 'filename is required' })
      return
    }
    const lat = Number(latitude)
    const lon = Number(longitude)
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
      res.status(400).json({ error: 'longitude and latitude are required and must be numbers' })
      return
    }
    if (!thumbnailBase64 || typeof thumbnailBase64 !== 'string' || !modelfileBase64 || typeof modelfileBase64 !== 'string') {
      res.status(400).json({ error: 'thumbnailBase64 and modelfileBase64 required' })
      return
    }
    if (gplAccepted !== true) {
      res.status(400).json({ error: 'GPL acceptance required (gplAccepted: true)' })
      return
    }
    const email = typeof body.email === 'string' ? body.email.trim() : ''
    if (!email) {
      res.status(400).json({ error: 'email is required' })
      return
    }

    const rawAid = authorId != null ? Number(authorId) : null
    const an = authorNew as { name?: string; email?: string } | undefined
    let authorIdFinal: number
    let authorNewForValidation: { name: string; email: string } | undefined
    if (rawAid != null && Number.isInteger(rawAid) && rawAid >= 2 && rawAid <= 999) {
      authorIdFinal = rawAid
      authorNewForValidation = undefined
    } else if (rawAid === 1 || rawAid == null) {
      authorIdFinal = 1
      authorNewForValidation = {
        name: (an?.name || '').trim(),
        email: (an?.email || '').trim(),
      }
    } else {
      res.status(400).json({ error: 'Invalid author selection.' })
      return
    }

    const filenameTrim = (filename as string).trim()
    const formErr = await validateModelAddFormFields({
      name: (name as string).trim(),
      description: (description || '').toString().trim(),
      comment: typeof body.comment === 'string' ? body.comment.trim() : '',
      email,
      groupId: groupId != null ? Number(groupId) : 1,
      authorId: authorIdFinal,
      authorNew: authorNewForValidation,
      latitudeRaw: String(latitude),
      longitudeRaw: String(longitude),
      offsetRaw: offset != null && offset !== '' ? String(offset) : '',
      headingRaw: heading != null && heading !== '' ? String(heading) : '0',
    })
    if (formErr) {
      res.status(400).json({ error: formErr })
      return
    }

    const countryCode = await countryService.resolveCountryCodeAt(lon, lat)

    const pathErr = await assertModelPathAvailable(filenameTrim)
    if (pathErr) {
      res.status(400).json({ error: pathErr })
      return
    }

    const pkgErr = await validateModelfileBase64Package(modelfileBase64, filenameTrim)
    if (pkgErr) {
      res.status(400).json({ error: pkgErr })
      return
    }

    const thumbErr = await validateThumbnailBase64Input(thumbnailBase64)
    if (thumbErr) {
      res.status(400).json({ error: thumbErr })
      return
    }

    const modelPayload = {
      filename: filenameTrim,
      author: authorIdFinal,
      name: (name as string).trim(),
      description: (description || '').toString().trim(),
      thumbnail: thumbnailBase64,
      modelfiles: modelfileBase64,
      modelgroup: groupId != null ? Number(groupId) : 1,
    }
    const objectPayload = {
      description: (name as string).trim().slice(0, 100),
      longitude: lon,
      latitude: lat,
      country: countryCode ?? '',
      offset: offset == null || offset === '' ? 'NULL' : Number(offset),
      orientation: Number(heading) || 0,
      modelId: -1,
    }
    const content: Record<string, unknown> = {
      model: modelPayload,
      object: objectPayload,
    }
    if (authorIdFinal === 1 && authorNewForValidation) {
      content.author = {
        name: authorNewForValidation.name,
        email: authorNewForValidation.email,
      }
    }

    const { id, sig } = await requestRepo.saveRequest(
      requestRepo.REQUEST_TYPES.MODEL_ADD,
      content,
      email,
      ((body.comment as string) || '').trim()
    )
    await enqueuePositionRequestCreated({
      requestId: id,
      sig,
      requestType: requestRepo.REQUEST_TYPES.MODEL_ADD,
    })
    res.status(201).json({ id, sig, message: 'Queued for review' })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/models')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}

/** Multipart form field names for model upload */
export const MODEL_UPLOAD_FIELDS = [
  { name: 'thumbnail', maxCount: 1 },
  { name: 'ac3d', maxCount: 1 },
  { name: 'xml', maxCount: 1 },
  { name: 'png', maxCount: 12 },
] as const

export async function submitModelUpload(req: Request, res: Response): Promise<void> {
  try {
    const body = (req.body || {}) as Record<string, unknown>
    const files = (req.files || {}) as Record<string, Express.Multer.File[]>
    const thumbnailFiles = files.thumbnail
    const ac3dFiles = files.ac3d
    const xmlFiles = files.xml
    const pngFiles = files.png

    if (!thumbnailFiles?.length || !thumbnailFiles[0]?.buffer) {
      res.status(400).json({ error: 'thumbnail file is required' })
      return
    }
    if (!ac3dFiles?.length || !ac3dFiles[0]?.buffer) {
      res.status(400).json({ error: 'AC3D file is required' })
      return
    }

    const name = body.name != null ? String(body.name).trim() : ''
    if (!name) {
      res.status(400).json({ error: 'name is required' })
      return
    }

    if (body.gplAccepted !== true && body.gplAccepted !== 'true') {
      res.status(400).json({ error: 'GPL acceptance required' })
      return
    }
    const emailUpload = typeof body.email === 'string' ? body.email.trim() : ''
    if (!emailUpload) {
      res.status(400).json({ error: 'email is required' })
      return
    }

    const thumb = thumbnailFiles[0]!
    let err = assertFileSizeUnderLimit(thumb.size, 'Thumbnail')
    if (err) {
      res.status(400).json({ error: err })
      return
    }
    const thumbFlat = assertFlatUploadFilename(thumb.originalname)
    if (!thumbFlat) {
      res.status(400).json({ error: 'Invalid thumbnail file name.' })
      return
    }

    const ac3d = ac3dFiles[0]!
    err = assertFileSizeUnderLimit(ac3d.size, 'AC3D file')
    if (err) {
      res.status(400).json({ error: err })
      return
    }
    const acFlat = assertFlatUploadFilename(ac3d.originalname)
    if (!acFlat) {
      res.status(400).json({ error: 'Invalid AC3D file name.' })
      return
    }

    let xmlFlat: string | null = null
    let xmlFile: Express.Multer.File | undefined
    if (xmlFiles?.[0]?.buffer) {
      xmlFile = xmlFiles[0]
      err = assertFileSizeUnderLimit(xmlFile.size, 'XML file')
      if (err) {
        res.status(400).json({ error: err })
        return
      }
      const xf = assertFlatUploadFilename(xmlFile.originalname)
      if (!xf) {
        res.status(400).json({ error: 'Invalid XML file name.' })
        return
      }
      xmlFlat = xf
    }

    const pngBuffers: { name: string; buffer: Buffer }[] = []
    const pngNames: string[] = []
    if (pngFiles?.length) {
      for (const f of pngFiles) {
        if (!f?.buffer) continue
        err = assertFileSizeUnderLimit(f.size, `Texture "${f.originalname}"`)
        if (err) {
          res.status(400).json({ error: err })
          return
        }
        const pf = assertFlatUploadFilename(f.originalname)
        if (!pf) {
          res.status(400).json({ error: `Invalid texture file name: "${f.originalname}".` })
          return
        }
        pngNames.push(pf)
        pngBuffers.push({ name: pf, buffer: f.buffer })
      }
    }

    const nameRuleErr = validateAc3dXmlPngNames(acFlat, xmlFlat, pngNames)
    if (nameRuleErr) {
      res.status(400).json({ error: nameRuleErr })
      return
    }

    const pathToUse = xmlFlat ?? acFlat
    const pathErr = await assertModelPathAvailable(pathToUse)
    if (pathErr) {
      res.status(400).json({ error: pathErr })
      return
    }

    const rawAid = body.authorId != null ? Number(body.authorId) : null
    let authorIdFinal: number
    let authorNewForValidation: { name: string; email: string } | undefined
    if (rawAid != null && Number.isInteger(rawAid) && rawAid >= 2 && rawAid <= 999) {
      authorIdFinal = rawAid
      authorNewForValidation = undefined
    } else if (rawAid === 1 || rawAid == null) {
      authorIdFinal = 1
      authorNewForValidation = {
        name: String(body.authorName ?? '').trim(),
        email: String(body.authorEmail ?? '').trim(),
      }
    } else {
      res.status(400).json({ error: 'Invalid author selection.' })
      return
    }

    const formErr = await validateModelAddFormFields({
      name,
      description: String(body.description || '').trim(),
      comment: String(body.comment || '').trim(),
      email: emailUpload,
      groupId: body.groupId != null ? Number(body.groupId) : 1,
      authorId: authorIdFinal,
      authorNew: authorNewForValidation,
      latitudeRaw: String(body.latitude ?? ''),
      longitudeRaw: String(body.longitude ?? ''),
      offsetRaw: body.offset != null && body.offset !== '' ? String(body.offset) : '',
      headingRaw: body.heading != null && body.heading !== '' ? String(body.heading) : '0',
    })
    if (formErr) {
      res.status(400).json({ error: formErr })
      return
    }

    const lat = Number(body.latitude)
    const lon = Number(body.longitude)
    const countryCode = await countryService.resolveCountryCodeAt(lon, lat)

    const acNorm = normalizeTextFileBuffer(ac3d.buffer)
    const xmlNorm = xmlFile?.buffer ? normalizeTextFileBuffer(xmlFile.buffer) : null
    const fileErr = await validateModelFileBuffers({
      acBuffer: acNorm,
      acFilename: acFlat,
      xmlBuffer: xmlNorm,
      xmlFilename: xmlFlat,
      pngFiles: pngBuffers,
    })
    if (fileErr) {
      res.status(400).json({ error: fileErr })
      return
    }

    let thumbnailBase64: string
    try {
      const thumbnailJpeg = await convertToThumbnailJpeg(thumb.buffer)
      thumbnailBase64 = thumbnailJpeg.toString('base64')
    } catch {
      res.status(400).json({
        error:
          'Invalid thumbnail image; use a valid image file (e.g. JPEG, PNG). It will be converted to 320×240 JPEG.',
      })
      return
    }

    const tarEntries: { name: string; buffer: Buffer }[] = [{ name: acFlat, buffer: acNorm }]
    if (xmlFlat && xmlNorm) tarEntries.push({ name: xmlFlat, buffer: xmlNorm })
    for (const p of pngBuffers) tarEntries.push({ name: p.name, buffer: p.buffer })

    const modelfileGzip = await buildTarGz(tarEntries)
    const modelfileBase64 = modelfileGzip.toString('base64')

    const modelPayload = {
      filename: pathToUse,
      author: authorIdFinal,
      name,
      description: String(body.description || '').trim(),
      thumbnail: thumbnailBase64,
      modelfiles: modelfileBase64,
      modelgroup: body.groupId != null ? Number(body.groupId) : 1,
    }
    const objectPayload = {
      description: name.slice(0, 100),
      longitude: lon,
      latitude: lat,
      country: countryCode ?? '',
      offset: body.offset != null && body.offset !== '' ? Number(body.offset) : 'NULL',
      orientation: Number(body.heading) || 0,
      modelId: -1,
    }
    const content: Record<string, unknown> = {
      model: modelPayload,
      object: objectPayload,
    }
    if (authorNewForValidation && (authorNewForValidation.name || authorNewForValidation.email)) {
      content.author = authorNewForValidation
    }

    const { id, sig } = await requestRepo.saveRequest(
      requestRepo.REQUEST_TYPES.MODEL_ADD,
      content,
      emailUpload,
      String(body.comment || '').trim()
    )
    await enqueuePositionRequestCreated({
      requestId: id,
      sig,
      requestType: requestRepo.REQUEST_TYPES.MODEL_ADD,
    })
    res.status(201).json({ id, sig, message: 'Queued for review' })
  } catch (err) {
    logDbError(err, 'POST /api/submissions/models/upload')
    res.status(500).json({ error: CLIENT_ERROR_MESSAGE })
  }
}
