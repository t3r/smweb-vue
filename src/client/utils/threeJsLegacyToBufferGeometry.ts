/**
 * Convert our backend Three.js legacy JSON to Three.js BufferGeometry.
 * Supports two formats:
 * - Non-indexed (per-triangle): vertices, normals, uvs in triangle order (3 verts per triangle), faces empty.
 * - Indexed: vertices, normals, faces as [ 0, va, vb, vc, na, nb, nc, ... ], optional uvs.
 */

import * as THREE from 'three'

export interface LegacyGeometryJson {
  vertices: number[]
  normals: number[]
  faces?: number[]
  uvs?: number[] | number[][]
}

export function legacyJsonToBufferGeometry(legacyJson: LegacyGeometryJson | null | undefined): THREE.BufferGeometry | null {
  if (!legacyJson || !Array.isArray(legacyJson.vertices) || !Array.isArray(legacyJson.normals)) {
    return null
  }
  const geometry = new THREE.BufferGeometry()
  const vertexCount = legacyJson.vertices.length / 3
  geometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(legacyJson.vertices), 3))
  geometry.setAttribute('normal', new THREE.BufferAttribute(new Float32Array(legacyJson.normals), 3))

  const uvRaw = legacyJson.uvs
  if (uvRaw && vertexCount > 0) {
    const uvFlat = Array.isArray(uvRaw[0]) ? (uvRaw as number[][])[0] : (uvRaw as number[])
    if (uvFlat.length >= vertexCount * 2) {
      geometry.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(uvFlat), 2))
    }
  }

  const faces = legacyJson.faces || []
  if (faces.length > 0) {
    const indices: number[] = []
    let i = 0
    while (i < faces.length) {
      const type = faces[i]
      i += 1
      if (type === 0) {
        if (i + 5 < faces.length) {
          const [va, vb, vc] = [faces[i], faces[i + 1], faces[i + 2]]
          indices.push(va, vc, vb)
          i += 6
        }
      } else if (type === 35) {
        if (i + 8 < faces.length) {
          const [va, vb, vc, vd] = [faces[i], faces[i + 1], faces[i + 2], faces[i + 3]]
          indices.push(va, vc, vb, va, vd, vc)
          i += 9
        }
      }
    }
    if (indices.length > 0) {
      geometry.setIndex(indices)
      geometry.computeVertexNormals()
    }
  }
  geometry.computeBoundingSphere()
  return geometry
}
