/**
 * AC3D parser → Three.js legacy JSON geometry.
 * Based on ac3d2threejs.pl by Geoff McLane (geoffair.net), Niek Albers.
 * AC3D format: https://paulbourke.net/dataformats/ac3d/
 */

const AC3D_MIN_VERSION = 11

function tokenizeLine(line: string): string[] {
  const tokens: string[] = []
  let i = 0
  while (i < line.length) {
    if (/\s/.test(line[i])) {
      i++
      continue
    }
    if (line[i] === '"') {
      const end = line.indexOf('"', i + 1)
      tokens.push(end >= 0 ? line.slice(i + 1, end) : line.slice(i + 1))
      i = end >= 0 ? end + 1 : line.length
      continue
    }
    let j = i
    while (j < line.length && !/\s/.test(line[j])) j++
    tokens.push(line.slice(i, j))
    i = j
  }
  return tokens
}

export interface ParsedAC3D {
  materials: object[]
  root: AC3DObject
}

export interface AC3DObject {
  type: string
  name: string
  kids: AC3DObject[]
  texture?: string
  loc?: number[]
  rot?: number[]
  texrep?: number[]
  texoff?: number[]
  numvert?: number[][]
  numsurf?: AC3DSurface[]
  normals?: number[][]
}

export interface AC3DSurface {
  SURF?: { type: string; shading: string; twoSided: boolean }
  mat?: number
  refs?: { index: number; u: number; v: number }[]
}

export function parseAC3D(text: string): ParsedAC3D | null {
  if (!text || typeof text !== 'string') return null
  const lines = text.split(/\r?\n/)
  let lineIndex = 0

  function getLine(): string[] | null {
    if (lineIndex >= lines.length) return null
    return tokenizeLine(lines[lineIndex++])
  }

  function parseHeader(): boolean {
    const tokens = getLine()
    if (!tokens || tokens.length < 1) return false
    const m = (tokens[0] || '').match(/^AC3D([0-9a-fA-F])/)
    if (!m) return false
    const ver = parseInt(m[1], 16)
    return ver >= AC3D_MIN_VERSION
  }

  const materials: object[] = []
  let lastName = ''

  function parseMaterial(tokens: string[]): void {
    materials.push({
      name: tokens[1] || '',
      rgb: [parseFloat(tokens[3]) || 0, parseFloat(tokens[4]) || 0, parseFloat(tokens[5]) || 0],
      amb: [parseFloat(tokens[7]) || 0, parseFloat(tokens[8]) || 0, parseFloat(tokens[9]) || 0],
      emis: [parseFloat(tokens[11]) || 0, parseFloat(tokens[12]) || 0, parseFloat(tokens[13]) || 0],
      spec: [parseFloat(tokens[15]) || 0, parseFloat(tokens[16]) || 0, parseFloat(tokens[17]) || 0],
      shi: parseInt(tokens[19], 10) || 0,
      trans: parseFloat(tokens[21]) || 0,
    })
  }

  function parseNumvert(tokens: string[], obj: AC3DObject): void {
    const n = parseInt(tokens[1], 10) || 0
    const verts: number[][] = []
    for (let i = 0; i < n; i++) {
      const t = getLine()
      if (!t || t.length < 3) continue
      verts.push([parseFloat(t[0]) || 0, parseFloat(t[1]) || 0, parseFloat(t[2]) || 0])
    }
    obj.numvert = verts
  }

  function parseRefs(tokens: string[]): { index: number; u: number; v: number }[] {
    const n = parseInt(tokens[1], 10) || 0
    const refs: { index: number; u: number; v: number }[] = []
    for (let i = 0; i < n; i++) {
      const t = getLine()
      if (!t || t.length < 1) continue
      refs.push({
        index: parseInt(t[0], 10) || 0,
        u: t.length >= 3 ? parseFloat(t[1]) || 0 : 0,
        v: t.length >= 3 ? parseFloat(t[2]) || 0 : 0,
      })
    }
    return refs
  }

  function parseSurface(): AC3DSurface {
    const surface: AC3DSurface = {}
    for (;;) {
      const tokens = getLine()
      if (!tokens || tokens.length < 1) break
      const op = tokens[0]
      if (op === 'SURF') {
        const param = parseInt(tokens[1], 16) || 0
        const type = param & 0xf
        const flags = param >> 4
        surface.SURF = {
          type: type === 0 ? 'polygon' : type === 1 ? 'closedline' : 'line',
          shading: flags & 0x1 ? 'smooth' : 'flat',
          twoSided: !!(flags & 0x2),
        }
      } else if (op === 'mat') {
        surface.mat = parseInt(tokens[1], 10) || 0
      } else if (op === 'refs') {
        surface.refs = parseRefs(tokens)
        break
      }
    }
    return surface
  }

  function parseNumsurf(tokens: string[], obj: AC3DObject): void {
    const n = parseInt(tokens[1], 10) || 0
    const surfs: AC3DSurface[] = []
    for (let i = 0; i < n; i++) {
      surfs.push(parseSurface())
    }
    obj.numsurf = surfs
  }

  function parseObject(tokens: string[]): AC3DObject {
    const type = (tokens[1] || '').toLowerCase()
    const obj: AC3DObject = { type, name: lastName, kids: [] }
    for (;;) {
      const t = getLine()
      if (!t || t.length < 1) break
      const op = t[0]
      if (op === 'kids') {
        const amount = parseInt(t[1], 10) || 0
        for (let k = 0; k < amount; k++) {
          const childTokens = getLine()
          if (childTokens && childTokens[0] === 'OBJECT') {
            obj.kids.push(parseObject(childTokens))
          }
        }
        break
      }
      if (op === 'name') {
        obj.name = t[1] || ''
        lastName = obj.name
      } else if (op === 'texture') obj.texture = t[1] || ''
      else if (op === 'loc') obj.loc = [parseFloat(t[1]) || 0, parseFloat(t[2]) || 0, parseFloat(t[3]) || 0]
      else if (op === 'rot') obj.rot = t.slice(1, 10).map((x) => parseFloat(x) || 0)
      else if (op === 'texrep') obj.texrep = [parseFloat(t[1]) || 1, parseFloat(t[2]) || 1]
      else if (op === 'texoff') obj.texoff = [parseFloat(t[1]) || 0, parseFloat(t[2]) || 0]
      else if (op === 'numvert') parseNumvert(t, obj)
      else if (op === 'numsurf') parseNumsurf(t, obj)
      else if (op === 'data') {
        const len = parseInt(t[1], 10) || 0
        if (len > 0) getLine()
      }
    }
    return obj
  }

  if (!parseHeader()) return null
  lastName = ''
  let rootObject: AC3DObject | null = null
  while (lineIndex < lines.length) {
    const tokens = getLine()
    if (!tokens || tokens.length < 1) continue
    const cmd = tokens[0]
    if (cmd === 'MATERIAL') parseMaterial(tokens)
    else if (cmd === 'OBJECT') {
      rootObject = parseObject(tokens)
      break
    }
  }
  if (!rootObject) return null
  return { materials, root: rootObject }
}

function vec3Sub(a: number[], b: number[]): number[] {
  return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]
}
function vec3Cross(a: number[], b: number[]): number[] {
  return [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ]
}
function vec3Normalize(v: number[]): number[] {
  const len = Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
  if (len < 1e-10) return [0, 0, 1]
  return [v[0] / len, v[1] / len, v[2] / len]
}
function vec3AddInPlace(a: number[], b: number[]): void {
  a[0] += b[0]
  a[1] += b[1]
  a[2] += b[2]
}

function vertexKey(v: number[]): string {
  return `${v[0].toFixed(6)},${v[1].toFixed(6)},${v[2].toFixed(6)}`
}

function makeIndicesMap(obj: AC3DObject): Map<string, number[]> {
  const map = new Map<string, number[]>()
  if (!obj.numsurf) return map
  for (const surf of obj.numsurf) {
    if ((surf.SURF && surf.SURF.shading === 'smooth') || !surf.SURF) {
      for (const ref of surf.refs || []) {
        const v = obj.numvert?.[ref.index]
        if (v) {
          const k = vertexKey(v)
          if (!map.has(k)) map.set(k, [])
          const arr = map.get(k)!
          if (!arr.includes(ref.index)) arr.push(ref.index)
        }
      }
    }
  }
  return map
}

function calcVertexNormals(obj: AC3DObject): void {
  if (!obj.numvert || !obj.numsurf) return
  const verts = obj.numvert
  const normals = verts.map(() => [0, 0, 0])
  const indicesMap = makeIndicesMap(obj)

  for (const surf of obj.numsurf) {
    const refs = surf.refs || []
    if (refs.length < 3) continue
    const i0 = refs[0].index
    const i1 = refs[1].index
    const i2 = refs[2].index
    const v0 = verts[i0]
    const v1 = verts[i1]
    const v2 = verts[i2]
    if (!v0 || !v1 || !v2) continue
    const d0 = vec3Sub(v1, v0)
    const d1 = vec3Sub(v2, v0)
    let n = vec3Cross(d0, d1)
    n = vec3Normalize(n)

    const indices = new Set<number>()
    if (surf.SURF && surf.SURF.shading === 'smooth') {
      for (const idx of [i0, i1, i2]) {
        const k = vertexKey(verts[idx])
        for (const j of indicesMap.get(k) || [idx]) indices.add(j)
      }
    } else {
      indices.add(i0).add(i1).add(i2)
    }
    for (const idx of indices) {
      vec3AddInPlace(normals[idx], n)
    }
  }

  for (let j = 0; j < normals.length; j++) {
    const n = normals[j]
    if (n[0] !== 0 || n[1] !== 0 || n[2] !== 0) {
      const nn = vec3Normalize(n)
      normals[j][0] = nn[0]
      normals[j][1] = nn[1]
      normals[j][2] = nn[2]
    } else {
      normals[j] = [0, 1, 0]
    }
  }
  obj.normals = normals
}

interface CollectState {
  vertices: number[]
  normals: number[]
  uvs?: number[]
}

function collectGeometry(obj: AC3DObject | undefined, state: CollectState, locOffset: number[] = [0, 0, 0]): void {
  if (!obj) return
  const loc = obj.loc || [0, 0, 0]
  const nextOffset = [locOffset[0] + loc[0], locOffset[1] + loc[1], locOffset[2] + loc[2]]

  for (const kid of obj.kids || []) {
    collectGeometry(kid, state, nextOffset)
  }

  if (obj.type !== 'poly' || !obj.numvert || !obj.numsurf) return
  calcVertexNormals(obj)
  const verts = obj.numvert
  const norms = obj.normals || []

  const offsetU = (obj.texoff && obj.texoff[0]) != null ? obj.texoff[0] : 0
  const offsetV = (obj.texoff && obj.texoff[1]) != null ? obj.texoff[1] : 0
  const repeatU = (obj.texrep && obj.texrep[0]) != null ? obj.texrep[0] : 1
  const repeatV = (obj.texrep && obj.texrep[1]) != null ? obj.texrep[1] : 1

  for (const surf of obj.numsurf) {
    const refs = surf.refs || []
    if (refs.length < 3) continue
    for (let k = 1; k + 1 < refs.length; k++) {
      const r0 = refs[0]
      const r1 = refs[k]
      const r2 = refs[k + 1]
      for (const ref of [r0, r1, r2]) {
        const i = ref.index
        if (i < 0 || i >= verts.length) continue
        const v = verts[i]
        state.vertices.push(v[0] + locOffset[0], v[1] + locOffset[1], v[2] + locOffset[2])
        const n = norms[i] || [0, 1, 0]
        state.normals.push(n[0], n[1], n[2])
        if (state.uvs) {
          const u = ref.u != null ? ref.u : 0
          const v_uv = ref.v != null ? ref.v : 0
          state.uvs.push(offsetU + u * repeatU, offsetV + v_uv * repeatV)
        }
      }
    }
  }
}

export function toThreeJSJSON(parsed: ParsedAC3D | null, options: { includeUvs?: boolean } = {}): object | null {
  if (!parsed || !parsed.root) return null
  const includeUvs = options.includeUvs !== false
  const state: CollectState = {
    vertices: [],
    normals: [],
    uvs: includeUvs ? [] : undefined,
  }
  collectGeometry(parsed.root, state)

  const vCount = state.vertices.length / 3
  const triCount = Math.floor(vCount / 3)

  return {
    metadata: {
      formatVersion: 3.1,
      generatedBy: 'ac3dParser (Node)',
      vertices: vCount,
      faces: triCount,
      normals: vCount,
      colors: 0,
      uvs: state.uvs ? [state.uvs.length / 2] : [],
      materials: (parsed.materials && parsed.materials.length) || 1,
      morphTargets: 0,
      bones: 0,
    },
    scale: 1.0,
    vertices: state.vertices,
    normals: state.normals,
    colors: [],
    uvs: state.uvs && state.uvs.length > 0 ? [state.uvs] : [],
    faces: [],
    morphTargets: [],
    bones: [],
    skinIndices: [],
    skinWeights: [],
    animation: {},
  }
}

export function getTextureNames(parsed: ParsedAC3D | null): string[] {
  const names: string[] = []
  if (!parsed?.root) return names
  function walk(o: AC3DObject): void {
    if (o.texture && typeof o.texture === 'string' && o.texture.trim()) {
      const t = o.texture.trim()
      if (!names.includes(t)) names.push(t)
    }
    for (const kid of o.kids || []) walk(kid)
  }
  walk(parsed.root)
  return names
}

export function parseAC3DToThreeJS(text: string): object | null {
  const parsed = parseAC3D(text)
  return parsed ? toThreeJSJSON(parsed) : null
}
