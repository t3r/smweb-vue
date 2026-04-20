<template>
  <div class="objects-add-request-details">
    <template v-if="mapObjects.length">
      <div class="details-map-wrap">
        <ObjectMap
          :objects="mapObjects"
          :fit-to-selection="true"
          :initial-center="mapCenter"
          :initial-zoom="14"
          responsive-viewport-height
          marker-hover-card
          :resource-api-base="resourceApiBase"
        />
        <span class="details-map-hint">Hover a marker for model name and thumbnail. {{ mapObjects.length }} object(s) to be added (not yet in database).</span>
      </div>
    </template>
    <p v-else-if="isObjectsAddArray" class="m-0 text-color-secondary">No valid coordinates in this request.</p>
    <pre v-else class="details-json">{{ formatRaw }}</pre>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import ObjectMap from '@/components/ObjectMap.vue'

const props = defineProps<{
  details: unknown
}>()

const auth = useAuthStore()

const isObjectsAddArray = computed(() => Array.isArray(props.details))

const modelMetaById = ref<Record<number, { name?: string }>>({})

const resourceApiBase = computed(() => auth.apiUrl('/api'))

const mapObjects = computed(() => {
  if (!Array.isArray(props.details)) return []
  return (props.details as Record<string, unknown>[])
    .map((row, index) => {
      const lat = Number(row.latitude)
      const lon = Number(row.longitude)
      if (!Number.isFinite(lat) || !Number.isFinite(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        return null
      }
      const heading =
        row.orientation != null && Number.isFinite(Number(row.orientation)) ? Number(row.orientation) : 0
      const modelId = row.modelId != null ? Number(row.modelId) : NaN
      const desc = String(row.description ?? '').trim()
      const typeLabel = Number.isFinite(modelId) ? `Model #${modelId}` : ''
      const loadedName = Number.isFinite(modelId) ? modelMetaById.value[modelId]?.name : undefined
      const description = [typeLabel, desc].filter(Boolean).join(' · ') || 'New object'
      return {
        id: -(index + 1),
        description,
        type: typeLabel || undefined,
        modelId: Number.isFinite(modelId) ? modelId : undefined,
        modelName: loadedName,
        position: { lat, lon, heading },
      }
    })
    .filter(Boolean) as {
    id: number
    description: string
    type?: string
    modelId?: number
    modelName?: string
    position: { lat: number; lon: number; heading: number }
  }[]
})

const mapCenter = computed((): [number, number] => {
  const first = mapObjects.value[0]?.position
  if (first && Number.isFinite(first.lon) && Number.isFinite(first.lat)) {
    return [first.lon, first.lat]
  }
  return [10, 53.5]
})

const formatRaw = computed(() => {
  if (props.details == null) return '—'
  try {
    return JSON.stringify(props.details, null, 2)
  } catch {
    return String(props.details)
  }
})

onMounted(async () => {
  if (!Array.isArray(props.details)) return
  const ids = new Set<number>()
  for (const row of props.details as Record<string, unknown>[]) {
    const mid = row.modelId != null ? Number(row.modelId) : NaN
    if (Number.isFinite(mid) && mid > 0) ids.add(mid)
  }
  if (ids.size === 0) return
  const results = await Promise.all(
    [...ids].map(async (id) => {
      try {
        const res = await fetch(auth.apiUrl(`/api/models/${id}`), { credentials: 'include' })
        if (!res.ok) return [id, null] as const
        const data = (await res.json()) as { name?: unknown; filename?: unknown }
        const name =
          typeof data.name === 'string' && data.name.trim()
            ? data.name.trim()
            : typeof data.filename === 'string' && data.filename.trim()
              ? data.filename.trim()
              : undefined
        return [id, { name }] as const
      } catch {
        return [id, null] as const
      }
    })
  )
  const next: Record<number, { name?: string }> = {}
  for (const [id, meta] of results) {
    if (meta) next[id] = meta
  }
  modelMetaById.value = next
})
</script>

<style scoped>
.objects-add-request-details {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.details-map-wrap {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  min-width: 0;
}
.details-map-hint {
  font-size: 0.75rem;
  color: var(--p-text-color-secondary);
}
.m-0 {
  margin: 0;
}
.text-color-secondary {
  color: var(--p-text-muted-color);
}
.details-json {
  margin: 0;
  font-size: 0.8rem;
  overflow-x: auto;
  white-space: pre-wrap;
  word-break: break-word;
  color: var(--p-text-color);
}
</style>
