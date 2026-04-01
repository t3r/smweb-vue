<template>
  <div class="map-view-root">
    <Card class="map-view-card">
      <template #content>
        <div class="map-view-card-content">
          <ObjectMap
            :map-objects-api-url="auth.apiUrl('/api/objects/map')"
            :initial-center="initialCenter"
            :initial-zoom="initialZoom"
            sync-view-to-history
            @object-click="onObjectClick"
            @view-change="onMapViewChange"
          />
        </div>
      </template>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import ObjectMap from '@/components/ObjectMap.vue'

const MAP_VIEW_STORAGE_KEY = 'fg-map-view'

const DEFAULT_LNG = 10
const DEFAULT_LAT = 53.5
const DEFAULT_ZOOM = 7

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const objectsForDemo = ref([])

let mapUrlReplaceTimer: ReturnType<typeof setTimeout> | null = null

function firstQueryParam(v: string | string[] | undefined): string {
  if (Array.isArray(v)) return v[0] ?? ''
  return typeof v === 'string' ? v : ''
}

function parseMapFromRoute(): { lng: number; lat: number; zoom: number } | null {
  const lng = parseFloat(firstQueryParam(route.query.lng))
  const lat = parseFloat(firstQueryParam(route.query.lat))
  const z = parseFloat(firstQueryParam(route.query.z))
  if (
    !Number.isFinite(lng) ||
    !Number.isFinite(lat) ||
    !Number.isFinite(z) ||
    lat < -90 ||
    lat > 90 ||
    lng < -180 ||
    lng > 180 ||
    z < 0 ||
    z > 19
  ) {
    return null
  }
  return { lng, lat, zoom: z }
}

function readStoredMapView(): { lng: number; lat: number; zoom: number } | null {
  try {
    const raw = sessionStorage.getItem(MAP_VIEW_STORAGE_KEY)
    if (!raw) return null
    const o = JSON.parse(raw) as { lng?: unknown; lat?: unknown; zoom?: unknown }
    if (typeof o.lng !== 'number' || typeof o.lat !== 'number' || typeof o.zoom !== 'number') return null
    if (
      o.lat < -90 ||
      o.lat > 90 ||
      o.lng < -180 ||
      o.lng > 180 ||
      o.zoom < 0 ||
      o.zoom > 19
    ) {
      return null
    }
    return { lng: o.lng, lat: o.lat, zoom: o.zoom }
  } catch {
    return null
  }
}

const mapViewState = computed(() => {
  const fromQuery = parseMapFromRoute()
  if (fromQuery) return fromQuery
  return readStoredMapView() ?? { lng: DEFAULT_LNG, lat: DEFAULT_LAT, zoom: DEFAULT_ZOOM }
})

const initialCenter = computed(() => [mapViewState.value.lng, mapViewState.value.lat])
const initialZoom = computed(() => mapViewState.value.zoom)

function onMapViewChange(payload: { lng: number; lat: number; zoom: number }) {
  const lng = Number(payload.lng.toFixed(5))
  const lat = Number(payload.lat.toFixed(5))
  const z = Math.min(19, Math.max(0, Number(payload.zoom.toFixed(2))))
  try {
    sessionStorage.setItem(MAP_VIEW_STORAGE_KEY, JSON.stringify({ lng, lat, zoom: z }))
  } catch {
    /* ignore quota / private mode */
  }
  const slng = lng.toFixed(5)
  const slat = lat.toFixed(5)
  const sz = z.toFixed(2)
  const ql = firstQueryParam(route.query.lng)
  const qa = firstQueryParam(route.query.lat)
  const qz = firstQueryParam(route.query.z)
  if (ql === slng && qa === slat && qz === sz) {
    return
  }
  if (mapUrlReplaceTimer) clearTimeout(mapUrlReplaceTimer)
  mapUrlReplaceTimer = setTimeout(() => {
    mapUrlReplaceTimer = null
    void router.replace({
      name: 'Map',
      query: { lng: slng, lat: slat, z: sz },
    })
  }, 400)
}

onBeforeUnmount(() => {
  if (mapUrlReplaceTimer) {
    clearTimeout(mapUrlReplaceTimer)
    mapUrlReplaceTimer = null
  }
})

function onObjectClick(id) {
  router.push(`/objects/${id}`)
}

async function fetchObjectsForDemo() {
  const bbox = '9,52.5,11,54.5'
  try {
    const res = await fetch(`${auth.apiUrl('/api/objects/map')}?bbox=${bbox}&limit=20`, { credentials: 'include' })
    if (!res.ok) return
    const data = await res.json()
    objectsForDemo.value = data.objects ?? []
  } catch {
    objectsForDemo.value = []
  }
}

onMounted(() => {
  fetchObjectsForDemo()
})
</script>

<style scoped>
/* Tall map; chrome ≈ menubar + main padding + footer below main. */
.map-view-root {
  display: flex;
  flex-direction: column;
  min-height: calc(100vh - 9.5rem);
  min-height: calc(100dvh - 9.5rem);
}
.map-view-card {
  flex: 1 1 0;
  display: flex;
  flex-direction: column;
  min-height: 0;
}
.map-view-card :deep(.p-card-body) {
  flex: 1 1 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
}
.map-view-card :deep(.p-card-content) {
  flex: 1 1 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: 0;
}
.map-view-card-content {
  flex: 1 1 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
}
.map-view-card-content :deep(.object-map-container) {
  flex: 1 1 0;
  min-height: 200px;
  height: auto;
}
.mt-0 { margin-top: 0; }
.mb-2 { margin-bottom: 0.5rem; }
.mb-3 { margin-bottom: 0.75rem; }
.mb-4 { margin-bottom: 1rem; }
.mt-2 { margin-top: 0.5rem; }
.m-0 { margin: 0; }
.p-4 { padding: 1rem; }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
.flex { display: flex; }
.align-items-center { align-items: center; }
.justify-content-center { justify-content: center; }
.map-hint { font-size: 0.875rem; }
.mr-2 { margin-right: 0.5rem; }
.ml-2 { margin-left: 0.5rem; }
</style>
