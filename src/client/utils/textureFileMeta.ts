/** Tar entry names we treat as raster textures for dimension probing (browser-decodable). */
const TEXTURE_EXT = /\.(png|jpg|jpeg|gif|webp|bmp)$/i

export function isRasterTextureFilename(name: string): boolean {
  return TEXTURE_EXT.test(name || '')
}

export async function probeRasterImageDimensions(fileUrl: string): Promise<{ width: number; height: number } | null> {
  if (!fileUrl || fileUrl === '#') return null
  try {
    const res = await fetch(fileUrl, { credentials: 'include' })
    if (!res.ok) return null
    const blob = await res.blob()
    const objectUrl = URL.createObjectURL(blob)
    try {
      const dims = await new Promise<{ width: number; height: number } | null>((resolve) => {
        const img = new Image()
        img.onload = () => {
          const w = img.naturalWidth
          const h = img.naturalHeight
          if (w > 0 && h > 0) resolve({ width: w, height: h })
          else resolve(null)
        }
        img.onerror = () => resolve(null)
        img.src = objectUrl
      })
      return dims
    } finally {
      URL.revokeObjectURL(objectUrl)
    }
  } catch {
    return null
  }
}

export function formatTextureDimensions(d: { width: number; height: number } | null | undefined): string {
  if (d == null || d.width <= 0 || d.height <= 0) return '—'
  return `${d.width}×${d.height}`
}
