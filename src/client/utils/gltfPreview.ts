/**
 * Pick the primary glTF entry from a flat package file list (exactly one expected).
 * Prefers .glb over .gltf when both exist (unusual; first match wins per type).
 */
export function pickPrimaryGltfFilename(files: { name: string }[]): string | null {
  if (!files?.length) return null
  const lower = (n: string) => n.toLowerCase()
  const glb = files.find((f) => lower(f.name).endsWith('.glb'))
  if (glb) return glb.name
  const gltf = files.find((f) => lower(f.name).endsWith('.gltf'))
  return gltf?.name ?? null
}

/**
 * Map a URL GLTFLoader / FileLoader requests to our flat `?name=` file URLs.
 * Handles `/file?name=asset.gltf` and resolved absolute paths whose last segment is the flat filename.
 */
export function mapGltfLoaderUrlToResolve(
  url: string,
  resolveFileUrl: (fileName: string) => string
): string {
  try {
    const u = new URL(url, typeof window !== 'undefined' ? window.location.origin : 'http://localhost')
    const q = u.searchParams.get('name')
    if (q) return resolveFileUrl(q)
    const path = u.pathname
    const seg = path.slice(path.lastIndexOf('/') + 1)
    if (seg && seg !== 'file') return resolveFileUrl(decodeURIComponent(seg))
  } catch {
    /* relative or opaque */
  }
  const noQ = url.split('?')[0] ?? url
  const slash = noQ.lastIndexOf('/')
  const base = slash >= 0 ? noQ.slice(slash + 1) : noQ
  if (base) return resolveFileUrl(decodeURIComponent(base))
  return url
}
