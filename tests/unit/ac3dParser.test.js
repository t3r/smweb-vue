import { describe, it, expect } from 'vitest'
import { parseAC3D, parseAC3DToThreeJS, toThreeJSJSON } from '../../src/server/utils/ac3dParser.ts'

const MINIMAL_AC = `AC3Db
MATERIAL "" rgb 1 1 1  amb 0.2 0.2 0.2  emis 0 0 0  spec 0.5 0.5 0.5  shi 10  trans 0
OBJECT world
kids 1
OBJECT poly
name "rect"
loc 1 0.5 0
numvert 4
-1 0.5 0
1 0.5 0
1 -0.5 0
-1 -0.5 0
numsurf 1
SURF 0x20
mat 0
refs 4
3 0 0
2 1 0
1 1 1
0 0 1
kids 0
`

describe('ac3dParser', () => {
  it('parseAC3D returns null for empty or invalid input', () => {
    expect(parseAC3D('')).toBeNull()
    expect(parseAC3D(null)).toBeNull()
    expect(parseAC3D('not ac3d')).toBeNull()
    expect(parseAC3D('AC3D9')).toBeNull()
  })

  it('parseAC3D parses minimal AC3D and returns materials and root object', () => {
    const parsed = parseAC3D(MINIMAL_AC)
    expect(parsed).not.toBeNull()
    expect(parsed.materials).toHaveLength(1)
    expect(parsed.root).toBeDefined()
    expect(parsed.root.type).toBe('world')
    expect(parsed.root.kids).toHaveLength(1)
    const poly = parsed.root.kids[0]
    expect(poly.type).toBe('poly')
    expect(poly.name).toBe('rect')
    expect(poly.numvert).toHaveLength(4)
    expect(poly.numsurf).toHaveLength(1)
    expect(poly.numsurf[0].refs).toHaveLength(4)
  })

  it('parseAC3DToThreeJS returns Three.js JSON with metadata, vertices, normals, per-triangle', () => {
    const json = parseAC3DToThreeJS(MINIMAL_AC)
    expect(json).not.toBeNull()
    expect(json.metadata).toBeDefined()
    expect(json.metadata.formatVersion).toBe(3.1)
    expect(json.vertices).toBeDefined()
    expect(Array.isArray(json.vertices)).toBe(true)
    expect(json.normals).toBeDefined()
    expect(json.faces).toBeDefined()
    expect(Array.isArray(json.faces)).toBe(true)
    expect(json.vertices.length).toBe(18)
  })

  it('toThreeJSJSON returns null for null parsed', () => {
    expect(toThreeJSJSON(null)).toBeNull()
    expect(toThreeJSJSON({ root: null })).toBeNull()
  })
})
