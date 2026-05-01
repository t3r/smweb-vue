<template>
  <div class="object-update-details">
    <p v-if="loading" class="m-0 text-color-secondary">Loading current object…</p>
    <template v-else-if="currentObject">
      <p class="object-detail-link mb-2">
        <a :href="objectDetailUrl" target="_blank" rel="noopener noreferrer">View object in detail <i class="pi pi-external-link"></i></a>
      </p>
      <div class="comparison-grid">
        <div class="comparison-column">
          <h4 class="comparison-heading">Requested</h4>
          <dl class="comparison-fields">
            <dt>Description</dt>
            <dd :class="{ 'value-modified': fieldDiffs.description }">{{ formatVal(details.description) }}</dd>
            <dt>Model</dt>
            <dd :class="{ 'value-modified': fieldDiffs.model }">
              <router-link v-if="details.modelId != null" :to="'/models/' + details.modelId">Model #{{ details.modelId }}</router-link>
              <span v-else>—</span>
            </dd>
            <dt>Country</dt>
            <dd :class="{ 'value-modified': fieldDiffs.country }">{{ formatVal(details.country) }}</dd>
            <dt>Longitude</dt>
            <dd :class="{ 'value-modified': fieldDiffs.longitude }">{{ formatCoord(details.longitude) }}</dd>
            <dt>Latitude</dt>
            <dd :class="{ 'value-modified': fieldDiffs.latitude }">{{ formatCoord(details.latitude) }}</dd>
            <dt>Elevation offset</dt>
            <dd :class="{ 'value-modified': fieldDiffs.offset }">{{ formatElevation(details.offset) }}</dd>
            <dt>Heading</dt>
            <dd :class="{ 'value-modified': fieldDiffs.heading }">{{ formatHeading(details.orientation) }}</dd>
          </dl>
        </div>
        <div class="comparison-column">
          <h4 class="comparison-heading">Current (in database)</h4>
          <dl class="comparison-fields">
            <dt>Description</dt>
            <dd :class="{ 'value-modified': fieldDiffs.description }">{{ formatVal(currentObject.description) }}</dd>
            <dt>Model</dt>
            <dd :class="{ 'value-modified': fieldDiffs.model }">
              <router-link v-if="currentObject.modelId != null" :to="'/models/' + currentObject.modelId">Model #{{ currentObject.modelId }}</router-link>
              <span v-else>—</span>
            </dd>
            <dt>Country</dt>
            <dd :class="{ 'value-modified': fieldDiffs.country }">{{ formatVal(currentObject.country) }}</dd>
            <dt>Longitude</dt>
            <dd :class="{ 'value-modified': fieldDiffs.longitude }">{{ formatCoord(currentObject.position?.lon) }}</dd>
            <dt>Latitude</dt>
            <dd :class="{ 'value-modified': fieldDiffs.latitude }">{{ formatCoord(currentObject.position?.lat) }}</dd>
            <dt>Elevation offset</dt>
            <dd :class="{ 'value-modified': fieldDiffs.offset }">{{ formatElevation(currentObject.position?.offset) }}</dd>
            <dt>Heading</dt>
            <dd :class="{ 'value-modified': fieldDiffs.heading }">{{ formatHeading(currentObject.position?.heading) }}</dd>
          </dl>
        </div>
      </div>
      <div v-if="positionsDiffer" class="comparison-map-wrap">
        <h4 class="comparison-heading">Position comparison</h4>
        <p class="map-legend text-color-secondary">
          <span class="legend-item"><span class="legend-dot current-dot"></span> Current</span>
          <span class="legend-item"><span class="legend-dot requested-dot"></span> Requested</span>
        </p>
        <ObjectMap
          :objects="mapObjects"
          :fit-to-selection="true"
          :initial-center="mapCenter"
          :initial-zoom="14"
          compact
        />
      </div>
    </template>
    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
import ObjectMap from '@/components/ObjectMap.vue'

export interface ObjectUpdateDetails {
  objectId?: number | null
  modelId?: number | null
  description?: string | null
  country?: string | null
  longitude?: number | null
  latitude?: number | null
  offset?: number | null
  orientation?: number | null
}

interface FetchedObject {
  id: number
  modelId: number
  description?: string | null
  country?: string | null
  position?: { lat?: number; lon?: number; offset?: number; heading?: number }
}

const props = withDefaults(
  defineProps<{
    details: ObjectUpdateDetails
  }>(),
  {}
)

const auth = useAuthStore()
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()
const currentObject = ref<FetchedObject | null>(null)
const loading = ref(true)
const loadError = ref<string | null>(null)

const objectDetailUrl = computed(() => {
  const id = currentObject.value?.id ?? props.details.objectId
  return id != null ? `/objects/${id}` : '#'
})

const requestedLat = computed(() =>
  props.details.latitude != null && Number.isFinite(Number(props.details.latitude)) ? Number(props.details.latitude) : null
)
const requestedLon = computed(() =>
  props.details.longitude != null && Number.isFinite(Number(props.details.longitude)) ? Number(props.details.longitude) : null
)

const positionsDiffer = computed(() => {
  const cur = currentObject.value
  if (!cur?.position || requestedLat.value == null || requestedLon.value == null) return false
  const curLat = cur.position.lat != null ? Number(cur.position.lat) : null
  const curLon = cur.position.lon != null ? Number(cur.position.lon) : null
  if (curLat == null || curLon == null) return true
  const tol = 1e-6
  return Math.abs(curLat - requestedLat.value) > tol || Math.abs(curLon - requestedLon.value) > tol
})

const NUM_TOL = 1e-6
function numEq(a: unknown, b: unknown): boolean {
  const na = Number(a)
  const nb = Number(b)
  if (!Number.isFinite(na) && !Number.isFinite(nb)) return true
  if (!Number.isFinite(na) || !Number.isFinite(nb)) return false
  return Math.abs(na - nb) <= NUM_TOL
}

/** Which fields differ between requested and current (for highlighting). */
const fieldDiffs = computed(() => {
  const cur = currentObject.value
  const d = props.details
  if (!cur) {
    return { description: false, model: false, country: false, longitude: false, latitude: false, offset: false, heading: false }
  }
  const reqDesc = (d.description != null && String(d.description).trim() !== '') ? String(d.description).trim() : ''
  const curDesc = (cur.description != null && String(cur.description).trim() !== '') ? String(cur.description).trim() : ''
  const reqCountry = (d.country != null && String(d.country).trim() !== '') ? String(d.country).trim().toLowerCase() : ''
  const curCountry = (cur.country != null && String(cur.country).trim() !== '') ? String(cur.country).trim().toLowerCase() : ''
  const reqOffset = d.offset != null && d.offset !== '' ? Number(d.offset) : null
  const curOffset = cur.position?.offset != null ? Number(cur.position.offset) : null
  const reqOffsetNum = reqOffset != null && Number.isFinite(reqOffset) ? reqOffset : null
  const curOffsetNum = curOffset != null && Number.isFinite(curOffset) ? curOffset : null
  const offsetDiff =
    reqOffsetNum === null && curOffsetNum === null
      ? false
      : (reqOffsetNum === null ? curOffsetNum !== null : curOffsetNum === null || Math.abs(reqOffsetNum - curOffsetNum) > NUM_TOL)
  const reqHeading = d.orientation != null && Number.isFinite(Number(d.orientation)) ? Number(d.orientation) : 0
  const curHeading = cur.position?.heading != null && Number.isFinite(Number(cur.position.heading)) ? Number(cur.position.heading) : 0
  return {
    description: reqDesc !== curDesc,
    model: (d.modelId != null ? Number(d.modelId) : null) !== (cur.modelId != null ? Number(cur.modelId) : null),
    country: reqCountry !== curCountry,
    longitude: !numEq(d.longitude, cur.position?.lon),
    latitude: !numEq(d.latitude, cur.position?.lat),
    offset: offsetDiff,
    heading: Math.abs(reqHeading - curHeading) > NUM_TOL,
  }
})

/** Two objects for the map: current (blue, shared 0) and requested (orange, shared 1) */
const mapObjects = computed(() => {
  const cur = currentObject.value
  if (!cur?.position || requestedLat.value == null || requestedLon.value == null) return []
  const list: { id: number; position: { lat: number; lon: number; heading?: number }; shared: number }[] = []
  const curLat = Number(cur.position.lat)
  const curLon = Number(cur.position.lon)
  if (Number.isFinite(curLat) && Number.isFinite(curLon)) {
    list.push({
      id: cur.id,
      position: {
        lat: curLat,
        lon: curLon,
        heading: cur.position.heading != null ? Number(cur.position.heading) : 0,
      },
      shared: 0,
    })
  }
  list.push({
    id: 0,
    position: {
      lat: requestedLat.value!,
      lon: requestedLon.value!,
      heading: props.details.orientation != null && Number.isFinite(Number(props.details.orientation)) ? Number(props.details.orientation) : 0,
    },
    shared: 1,
  })
  return list
})

const mapCenter = computed((): [number, number] => {
  if (requestedLat.value != null && requestedLon.value != null) return [requestedLon.value, requestedLat.value]
  const cur = currentObject.value
  if (cur?.position?.lat != null && cur?.position?.lon != null) return [Number(cur.position.lon), Number(cur.position.lat)]
  return [10, 53.5]
})

function formatVal(v: unknown) {
  if (v == null || v === '') return '—'
  return String(v).trim() || '—'
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

async function fetchObject() {
  const id = props.details.objectId != null ? Number(props.details.objectId) : null
  if (id == null || !Number.isInteger(id) || id < 1) {
    loading.value = false
    showError('Invalid object id in request')
    return
  }
  loading.value = true
  currentObject.value = null
  clearError()
  try {
    const url = auth.apiUrl(`/api/objects/${id}`)
    const res = await fetch(url, { credentials: 'include' })
    if (!res.ok) {
      if (res.status === 404) showError('Object not found')
      else throw new Error(res.statusText)
      return
    }
    const data = await res.json()
    currentObject.value = data as FetchedObject
  } catch (err) {
    showError((err as Error).message || 'Failed to load object')
  } finally {
    loading.value = false
  }
}

onMounted(fetchObject)
watch(() => props.details.objectId, fetchObject)
</script>

<style scoped>
.object-update-details { margin: 0; }
.object-detail-link { margin: 0; }
.object-detail-link a { color: var(--p-primary-color); text-decoration: none; }
.object-detail-link a:hover { text-decoration: underline; }
.object-detail-link .pi { font-size: 0.75rem; margin-left: 0.25rem; vertical-align: middle; }
.mb-2 { margin-bottom: 0.5rem; }
.comparison-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  margin-bottom: 1rem;
}
@media (max-width: 600px) {
  .comparison-grid { grid-template-columns: 1fr; }
}
.comparison-column { min-width: 0; }
.comparison-heading {
  margin: 0 0 0.5rem 0;
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--p-text-color);
}
.comparison-fields {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 0.35rem 1rem;
  margin: 0;
}
.comparison-fields dt { color: var(--p-text-muted-color); font-weight: 500; }
.comparison-fields dd { margin: 0; }
.comparison-fields dd.value-modified {
  background: var(--p-highlight-background, rgba(59, 130, 246, 0.15));
  border-radius: 4px;
  padding: 0.2rem 0.4rem;
  margin: 0 -0.4rem;
}
.comparison-fields a { color: var(--p-primary-color); text-decoration: none; }
.comparison-fields a:hover { text-decoration: underline; }
.comparison-map-wrap {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--p-content-border-color, rgba(0,0,0,0.08));
}
.comparison-map-wrap :deep(.object-map-container) {
  height: 280px;
  border-radius: 8px;
  overflow: hidden;
}
.map-legend { font-size: 0.8rem; margin: 0 0 0.35rem 0; }
.legend-item { margin-right: 1rem; }
.legend-dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  margin-right: 0.25rem;
  vertical-align: middle;
}
.current-dot { background: #2563eb; }
.requested-dot { background: #ea580c; }
.m-0 { margin: 0; }
.text-color-secondary { color: var(--p-text-muted-color); }
</style>
