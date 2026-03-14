<template>
  <Panel>
    <template #header>
      <span class="font-semibold">Object #{{ object.id }}</span>
    </template>
    <div class="object-details-row">
      <div class="object-details-thumb">
        <img
          :src="thumbnailUrl"
          :alt="object.description || 'Object'"
          class="thumb-img"
          @error="onThumbError"
        />
      </div>
      <div class="object-details-text">
        <dl class="detail-fields">
          <dt>Unique ID</dt>
          <dd>{{ object.id }}</dd>
          <dt>Longitude</dt>
          <dd>{{ formatCoord(object.position?.lon) }}</dd>
          <dt>Latitude</dt>
          <dd>{{ formatCoord(object.position?.lat) }}</dd>
          <dt>Country</dt>
          <dd>
            <router-link v-if="object.country && countryLink" :to="countryLink">{{ countryLabel }}</router-link>
            <span v-else-if="object.country">{{ object.country }}</span>
            <span v-else>—</span>
          </dd>
          <dt>Ground elevation</dt>
          <dd>{{ formatElevation(object.position?.elevation) }}</dd>
          <dt>Elevation offset</dt>
          <dd>{{ formatElevation(object.position?.offset) }}</dd>
          <dt>Heading</dt>
          <dd>{{ formatHeading(object.position?.heading) }}</dd>
          <dt>Model</dt>
          <dd>
            <router-link v-if="object.modelId" :to="modelLink">Model #{{ object.modelId }}</router-link>
            <span v-else>—</span>
          </dd>
          <template v-if="object.lastUpdated">
            <dt>Last updated</dt>
            <dd>{{ formatDate(object.lastUpdated) }}</dd>
          </template>
        </dl>
      </div>
      <div v-if="mapObjects.length" class="object-details-map">
        <ObjectMap
          :objects="mapObjects"
          :initial-center="mapCenter"
          :initial-zoom="15"
          compact
        />
      </div>
    </div>
  </Panel>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import Panel from 'primevue/panel'
import ObjectMap from '@/components/ObjectMap.vue'

export interface ObjectPosition {
  lat?: number | null
  lon?: number | null
  elevation?: number | null
  offset?: number | null
  heading?: number | null
}

export interface ObjectDetailsObject {
  id: number
  description?: string | null
  modelId?: number | null
  country?: string | null
  position?: ObjectPosition | null
  lastUpdated?: string | null
}

export interface CountryOption {
  code: string
  name?: string | null
}

const props = withDefaults(
  defineProps<{
    object: ObjectDetailsObject
    /** Optional list of countries for country label lookup and link */
    countries?: CountryOption[]
  }>(),
  { countries: () => [] }
)

const thumbnailUrl = computed(() =>
  props.object.modelId != null ? `/api/models/${props.object.modelId}/thumbnail` : ''
)

/** Single object for the map with position and heading for the directional marker */
const mapObjects = computed(() => {
  const pos = props.object.position
  if (!pos) return []
  const lat = Number(pos.lat)
  const lon = Number(pos.lon)
  if (!Number.isFinite(lat) || !Number.isFinite(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180) return []
  const heading = pos.heading != null && Number.isFinite(Number(pos.heading)) ? Number(pos.heading) : 0
  return [{ id: props.object.id, position: { lat, lon, heading }, shared: 0 }]
})

const mapCenter = computed((): [number, number] => {
  const objs = mapObjects.value
  if (!objs.length) return [10, 53.5]
  const p = objs[0].position
  return [Number(p.lon), Number(p.lat)]
})

const countryLink = computed(() => {
  if (!props.object.country) return null
  const code = String(props.object.country).trim().toUpperCase()
  return code ? { path: '/objects', query: { country: code } } : null
})

const countryLabel = computed(() => {
  if (!props.object.country) return ''
  const code = String(props.object.country).trim().toUpperCase()
  const c = (props.countries || []).find((x) => String(x.code).trim().toUpperCase() === code)
  return (c && (c.name || c.code)) || code
})

const modelLink = computed(() =>
  props.object.modelId != null ? { path: `/models/${props.object.modelId}` } : '/models'
)

function onThumbError(e: Event) {
  (e.target as HTMLImageElement).style.display = 'none'
}

function formatCoord(v: unknown) {
  if (v == null || v === '') return '—'
  const n = Number(v)
  return Number.isFinite(n) ? n.toFixed(6) : '—'
}

function formatElevation(v: unknown) {
  if (v == null || v === '') return '—'
  const n = Number(v)
  return Number.isFinite(n) ? `${n} m` : '—'
}

function formatHeading(v: unknown) {
  if (v == null || v === '') return '—'
  const n = Number(v)
  return Number.isFinite(n) ? `${n}° (true)` : '—'
}

function formatDate(iso: string | null | undefined) {
  if (!iso) return ''
  try {
    const d = new Date(iso)
    return d.toLocaleString(undefined, { dateStyle: 'short', timeStyle: 'short' })
  } catch {
    return iso
  }
}
</script>

<style scoped>
.object-details-row {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  flex-wrap: wrap;
}
.object-details-thumb {
  flex-shrink: 0;
}
.object-details-text {
  flex: 1 1 280px;
  min-width: 0;
}
.object-details-map {
  flex: 0 0 auto;
  width: 320px;
  max-width: 100%;
}
.object-details-map :deep(.object-map-container) {
  width: 320px;
  height: 240px;
  max-width: 100%;
  border-radius: 8px;
  overflow: hidden;
}
.thumb-img {
  width: 320px;
  max-width: 100%;
  height: auto;
  aspect-ratio: 4/3;
  object-fit: cover;
  border-radius: 8px;
}
.detail-fields {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 0.35rem 1.5rem;
  margin: 0;
}
.detail-fields dt {
  color: var(--p-text-muted-color, #64748b);
  font-weight: 500;
}
.detail-fields dd {
  margin: 0;
}
.detail-fields a {
  color: var(--p-primary-color);
  text-decoration: none;
}
.detail-fields a:hover {
  text-decoration: underline;
}
</style>
