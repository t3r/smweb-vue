import * as requestRepo from '../repositories/requestRepository.js'
import * as modelRepo from '../repositories/modelRepository.js'
import * as objectRepo from '../repositories/objectRepository.js'
import * as authorRepo from '../repositories/authorRepository.js'

export interface ExecuteRequestInput {
  type: string
  content: unknown
  email?: string
  comment?: string
}

export async function executeRequest(request: ExecuteRequestInput): Promise<unknown> {
  const { type, content } = request
  switch (type) {
    case 'MODEL_ADD':
      return executeModelAdd(content as Record<string, unknown>)
    case 'MODEL_UPDATE':
      return executeModelUpdate(content as Record<string, unknown>)
    case 'OBJECTS_ADD':
      return executeObjectsAdd(content as Record<string, unknown>[])
    case 'OBJECT_UPDATE':
      return executeObjectUpdate(content as Record<string, unknown>)
    case 'OBJECT_DELETE':
      return executeObjectDelete(content as Record<string, unknown>)
    case 'MODEL_DELETE':
      return executeModelDelete(content as Record<string, unknown>)
    default:
      throw new Error(`Unknown request type: ${type}`)
  }
}

async function executeModelAdd(content: Record<string, unknown>): Promise<{ modelId: number; authorId: number; objectId: number }> {
  const mo = content.model as Record<string, unknown>
  const ob = content.object as Record<string, unknown>
  const authorNew = content.author as Record<string, unknown> | undefined
  let authorId = mo.author as number

  if (authorNew && (authorNew.name || authorNew.email)) {
    const created = await authorRepo.insertOne((authorNew.name as string) || '', (authorNew.email as string) || '')
    authorId = created.id
  }

  const modelRow = await modelRepo.insertOne({
    path: mo.filename as string,
    authorId,
    name: (mo.name as string) || '',
    notes: (mo.description as string) || '',
    thumbfileBase64: mo.thumbnail as string | undefined,
    modelfileBase64: mo.modelfiles as string,
    shared: Number(mo.modelgroup),
    modifiedBy: authorId,
  })
  const modelId = modelRow.id

  const rawC = ob.country
  const countryNorm =
    rawC == null || rawC === ''
      ? null
      : String(rawC).trim().toLowerCase().slice(0, 2) || null
  const objPayload = {
    description: (ob.description as string) || '',
    longitude: Number(ob.longitude),
    latitude: Number(ob.latitude),
    country: countryNorm,
    modelId,
    offset: (ob.offset === 'NULL' || ob.offset == null ? null : ob.offset) as number | null,
    orientation: (ob.orientation as number) ?? 0,
  }
  const objectRow = await objectRepo.insertOne(objPayload)

  return { modelId, authorId, objectId: objectRow.id }
}

async function executeModelUpdate(content: Record<string, unknown>): Promise<{ modelId: number }> {
  const modelid = Number(content.modelid)
  const authorId: number = Number(content.author)
  const shared: number = Number(content.modelgroup)
  await modelRepo.updateOne(modelid, {
    path: content.filename as string,
    authorId,
    name: content.name as string,
    notes: (content.description as string) || '',
    thumbfileBase64: content.thumbnail as string | undefined,
    modelfileBase64: content.modelfiles as string,
    shared,
    modifiedBy: authorId,
  })
  return { modelId: modelid }
}

async function executeObjectsAdd(content: Record<string, unknown>[]): Promise<{ objectIds: number[] }> {
  const ids: number[] = []
  for (const ob of content) {
    const rawOffset = ob.offset === 'NULL' || ob.offset == null ? null : ob.offset
    const offset: number | null = rawOffset === null ? null : Number(rawOffset)
    const rawC = ob.country
    const countryNorm =
      rawC == null || rawC === ''
        ? null
        : String(rawC).trim().toLowerCase().slice(0, 2) || null
    const row = await objectRepo.insertOne({
      description: (ob.description as string) || '',
      longitude: Number(ob.longitude),
      latitude: Number(ob.latitude),
      country: countryNorm,
      modelId: Number(ob.modelId),
      offset,
      orientation: (ob.orientation as number) ?? 0,
    })
    ids.push(row.id)
  }
  return { objectIds: ids }
}

async function executeObjectUpdate(content: Record<string, unknown>): Promise<{ objectId: number }> {
  const rawC = content.country
  const countryNorm =
    rawC == null || rawC === ''
      ? null
      : String(rawC).trim().toLowerCase().slice(0, 2) || null
  await objectRepo.updateOne(Number(content.objectId), {
    description: (content.description as string) || '',
    longitude: Number(content.longitude),
    latitude: Number(content.latitude),
    country: countryNorm,
    modelId: Number(content.modelId),
    offset: (content.offset === 'NULL' || content.offset == null ? null : Number(content.offset)) as number | null,
    orientation: (content.orientation as number) ?? 0,
  })
  return { objectId: Number(content.objectId) }
}

async function executeObjectDelete(content: Record<string, unknown>): Promise<{ objectId: number }> {
  await objectRepo.softDeleteOne(Number(content.objId))
  return { objectId: Number(content.objId) }
}

async function executeModelDelete(content: Record<string, unknown>): Promise<{ modelId: number }> {
  const modelId = Number(content.modelId ?? content.modelid)
  const modifiedBy = content.modifiedByAuthorId != null ? Number(content.modifiedByAuthorId) : undefined
  await modelRepo.deleteOne(modelId, modifiedBy)
  return { modelId }
}
