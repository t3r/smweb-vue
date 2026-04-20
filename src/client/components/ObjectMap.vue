<template>
  <div
    ref="shellRef"
    class="object-map-shell object-map-container"
    :class="{
      'object-map-compact': compact && !responsiveViewportHeight,
      'object-map-responsive-vh': responsiveViewportHeight,
      'object-map-selectable': selectionMode && !selectionDraggable,
      'object-map-draggable-selection': selectionMode && selectionDraggable,
      'object-map-measuring': measureActive,
    }"
  >
    <div ref="containerRef" class="object-map-maplibre-root"></div>
    <!-- Stacking layer above MapLibre canvas (canvas can paint over following siblings without this). -->
    <div class="map-html-overlays">
      <div v-if="showAirportIcaoSearch" class="map-airport-search">
        <form class="map-airport-search__form" @submit.prevent="goToAirportIcao">
          <InputText
            v-model="icaoInput"
            type="text"
            maxlength="4"
            placeholder="ICAO"
            size="small"
            class="map-airport-search__input"
            :disabled="airportSearchLoading"
            autocomplete="off"
            autocapitalize="characters"
            spellcheck="false"
            aria-label="Airport ICAO code"
            @input="onIcaoFieldInput"
          />
        </form>
        <div v-if="airportSearchError" class="map-airport-search__msg map-airport-search__msg--err" role="alert">
          {{ airportSearchError }}
        </div>
      </div>
      <div
        v-if="pointerReadout"
        class="map-pointer-readout"
        role="status"
        aria-live="polite"
      >
        <div class="map-pointer-readout__row">
          <span class="map-pointer-readout__value">{{ pointerReadout.tileIndex }}</span>
        </div>
        <div class="map-pointer-readout__row">
          <span class="map-pointer-readout__value"
            >{{ pointerReadout.decLat }}° | {{ pointerReadout.decLon }}°</span
          >
        </div>
        <div class="map-pointer-readout__row">
          <span class="map-pointer-readout__value"
            >{{ pointerReadout.dmsLat }} | {{ pointerReadout.dmsLon }}</span
          >
        </div>
      </div>
      <div
        v-if="mapContextMenuOpen"
        ref="mapContextMenuRef"
        class="map-context-menu"
        role="menu"
        :style="{ left: `${mapContextMenuOpen.x}px`, top: `${mapContextMenuOpen.y}px` }"
      >
        <button type="button" class="map-context-menu__item" role="menuitem" @click="onCopyContextMenuLatLng">
          Copy lng/lat to clipboard
        </button>
        <button type="button" class="map-context-menu__item" role="menuitem" @click="onMeasureFromContextMenu">
          Measure
        </button>
      </div>
      <div
        v-if="measureActive"
        class="map-measure-hud"
        role="status"
        aria-live="polite"
        :style="{ left: `${measureActive.hudX}px`, top: `${measureActive.hudY}px` }"
      >
        <div class="map-measure-hud__row map-measure-hud__heading">
          {{ measureActive.distanceM < 1 ? '—' : `${measureActive.headingDeg.toFixed(1)}°` }}
        </div>
        <div class="map-measure-hud__row map-measure-hud__dist">{{ formatMeasureDistance(measureActive.distanceM) }}</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, onBeforeUnmount, computed } from 'vue'
import InputText from 'primevue/inputtext'
import { useAppToast } from '@/composables/useAppToast'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import Supercluster from 'supercluster'
import { fgTileGridFeatureCollection, fgTileIndex } from '@/utils/fgSceneryTileGrid'

/** Base map style using OpenStreetMap raster tiles. Glyphs required for symbol layers with text-field. */
const OSM_STYLE: maplibregl.StyleSpecification = {
  version: 8,
  glyphs: 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf',
  sources: {
    osm: {
      type: 'raster',
      tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
      tileSize: 256,
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    },
  },
  layers: [
    {
      id: 'osm-tiles',
      type: 'raster',
      source: 'osm',
      minzoom: 0,
      maxzoom: 19,
    },
  ],
}
const DEFAULT_CENTER = [10, 53.5]
const DEFAULT_ZOOM = 7

/** Same rounding as MapView `onMapViewChange` (also used for self-sync fingerprint). */
function roundViewForHistory(c: { lng: number; lat: number }, z: number) {
  return {
    lng: Number(c.lng.toFixed(5)),
    lat: Number(c.lat.toFixed(5)),
    zoom: Math.min(19, Math.max(0, Number(z.toFixed(2)))),
  }
}

function historyKeyFromRounded(r: { lng: number; lat: number; zoom: number }) {
  return `${r.lng},${r.lat},${r.zoom}`
}
const FIT_PADDING = 60
const FIT_MAX_ZOOM = 14
/** Zoom after flying to an airport from ICAO lookup. */
const AIRPORT_ICAO_FLY_ZOOM = 13
const VIEWPORT_FETCH_DEBOUNCE_MS = 300
const MAP_FETCH_LIMIT = 2000
/** Don't request objects when zoomed out beyond this (avoids globe-sized bbox). */
const MIN_ZOOM_FOR_FETCH = 3

/** FlightGear scenery tile grid (https://wiki.flightgear.org/Tile_Index_Scheme) */
const FG_GRID_MIN_ZOOM = 6
const FG_GRID_DEBOUNCE_MS = 150

function fgGridMaxSpans(zoom: number): { lon: number; lat: number } {
  if (zoom < 7) return { lon: 16, lat: 12 }
  if (zoom < 8) return { lon: 24, lat: 16 }
  if (zoom < 9) return { lon: 32, lat: 22 }
  return { lon: 42, lat: 28 }
}

/** Cap GeoJSON line segments (MapLibre setData + tessellation is costly). */
function fgGridMaxSegments(zoom: number): number {
  if (zoom < 7) return 380
  if (zoom < 8) return 520
  if (zoom < 9) return 720
  if (zoom < 11) return 1000
  return 1300
}

const props = defineProps({
  /** List of objects with position: { lat, lon } (used when mapObjectsApiUrl is not set) */
  objects: { type: Array, default: () => [] },
  /** When set, fetch objects by viewport from this API URL (bbox + limit); enables clustering */
  mapObjectsApiUrl: { type: String, default: '' },
  /** If true, fit map bounds to show all objects (for selection/inset view) */
  fitToSelection: { type: Boolean, default: false },
  /** Compact height for use inside a panel */
  compact: { type: Boolean, default: false },
  /** When true, map height follows viewport (min vw / min vh) for wide layouts; disables compact height lock. */
  responsiveViewportHeight: { type: Boolean, default: false },
  /** Hover popup on object-markers with model thumbnail + name (expects objects with modelId; optional modelName). */
  markerHoverCard: { type: Boolean, default: false },
  /** Base URL for model thumbnails, e.g. from `auth.apiUrl('/api')`. Empty = same-origin `/api`. */
  resourceApiBase: { type: String, default: '' },
  /** Initial center [lng, lat] when not fitting to selection */
  initialCenter: { type: Array, default: () => [10, 53.5] },
  /** Initial zoom when not fitting to selection */
  initialZoom: { type: Number, default: 7 },
  /** When true, emit view-change after pan/zoom (debounced) and jump when initialCenter/initialZoom change (e.g. browser history). */
  syncViewToHistory: { type: Boolean, default: false },
  /** When true, clicking the map emits position-select with { lat, lon } and shows selectionPosition as a marker */
  selectionMode: { type: Boolean, default: false },
  /** If true (default), map clicks that hit object/cluster layers do not emit position-select (avoid adding on top of markers). */
  selectionSkipWhenFeatureHit: { type: Boolean, default: true },
  /** When true with selectionMode, use a draggable MapLibre marker instead of click-to-place (no map click select). */
  selectionDraggable: { type: Boolean, default: false },
  /** Current selected position to show as a marker when selectionMode is true. { lat, lon } or null */
  selectionPosition: { type: Object, default: null },
  /** Top-left ICAO field: fetch position from airport API and fly the map there. */
  showAirportIcaoSearch: { type: Boolean, default: false },
  /** Base path without trailing ICAO (e.g. /api/airports/by-icao). */
  airportLookupBasePath: { type: String, default: '/api/airports/by-icao' },
  /** Right-click menu on the map (e.g. main Map view). */
  mapContextMenu: { type: Boolean, default: false },
})

const emit = defineEmits(['object-click', 'position-select', 'view-change'])

const { toastSuccess, toastWarn } = useAppToast()

const containerRef = ref(null)
const shellRef = ref(null)
const mapContextMenuRef = ref(null)

type MeasureActiveState = {
  anchorLat: number
  anchorLng: number
  cursorLat: number
  cursorLng: number
  hudX: number
  hudY: number
  headingDeg: number
  distanceM: number
}

/** Right-click "Measure" mode: arrow at anchor, line to cursor, HUD with bearing + distance. */
const measureActive = ref<MeasureActiveState | null>(null)

/** Bottom-left readout while cursor is over the map (mousemove). */
const pointerReadout = ref(null)

const icaoInput = ref('')
const airportSearchLoading = ref(false)
const airportSearchError = ref('')

function onIcaoFieldInput(e: Event) {
  airportSearchError.value = ''
  const el = e.target as HTMLInputElement | null
  if (!el) return
  const next = el.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 4)
  if (icaoInput.value !== next) icaoInput.value = next
}

async function goToAirportIcao() {
  airportSearchError.value = ''
  const raw = icaoInput.value.trim().toUpperCase()
  if (!/^[A-Z0-9]{3,4}$/.test(raw)) {
    airportSearchError.value = 'Enter a 3–4 character ICAO code.'
    return
  }
  if (!map) return
  airportSearchLoading.value = true
  try {
    const base = String(props.airportLookupBasePath || '/api/airports/by-icao').replace(/\/$/, '')
    const res = await fetch(`${base}/${encodeURIComponent(raw)}`, {
      credentials: 'include',
      cache: 'no-store',
    })
    if (res.status === 404) {
      airportSearchError.value = 'Airport not found.'
      return
    }
    if (!res.ok) {
      airportSearchError.value = 'Could not look up airport.'
      return
    }
    const data = (await res.json()) as { longitude?: unknown; latitude?: unknown }
    const lng = Number(data.longitude)
    const lat = Number(data.latitude)
    if (!Number.isFinite(lng) || !Number.isFinite(lat)) {
      airportSearchError.value = 'Invalid response from server.'
      return
    }
    map.flyTo({
      center: [wrapLongitude(lng), clampLatitude(lat)],
      zoom: Math.min(19, AIRPORT_ICAO_FLY_ZOOM),
    })
  } catch {
    airportSearchError.value = 'Network error.'
  } finally {
    airportSearchLoading.value = false
  }
}

function wrapLongitude(lng: number): number {
  let x = lng
  while (x > 180) x -= 360
  while (x < -180) x += 360
  return x
}

function clampLatitude(lat: number): number {
  return Math.max(-90, Math.min(90, lat))
}

function formatLatLngForClipboard(lat: number, lng: number): string {
  return `${clampLatitude(lat).toFixed(6)} ${wrapLongitude(lng).toFixed(6)}`
}

async function copyTextToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text)
    return true
  } catch {
    try {
      const ta = document.createElement('textarea')
      ta.value = text
      ta.setAttribute('readonly', '')
      ta.style.position = 'fixed'
      ta.style.left = '-9999px'
      document.body.appendChild(ta)
      ta.select()
      const ok = document.execCommand('copy')
      document.body.removeChild(ta)
      return ok
    } catch {
      return false
    }
  }
}

type MapContextMenuState = { x: number; y: number; lat: number; lng: number }

/** Screen position inside shell + coordinates at click (decimal lat/lng). */
const mapContextMenuOpen = ref<MapContextMenuState | null>(null)

function closeMapContextMenu() {
  mapContextMenuOpen.value = null
}

function openMapContextMenuFromMapEvent(e: maplibregl.MapMouseEvent) {
  const shell = shellRef.value
  if (!shell) return
  const rect = shell.getBoundingClientRect()
  const lat = clampLatitude(e.lngLat.lat)
  const lng = wrapLongitude(e.lngLat.lng)
  const rawX = e.originalEvent.clientX - rect.left
  const rawY = e.originalEvent.clientY - rect.top
  const pad = 4
  const maxX = Math.max(pad, rect.width - 200)
  const maxY = Math.max(pad, rect.height - 48)
  mapContextMenuOpen.value = {
    x: Math.min(Math.max(pad, rawX), maxX),
    y: Math.min(Math.max(pad, rawY), maxY),
    lat,
    lng,
  }
}

function onPointerDownDismissContextMenu(ev: PointerEvent) {
  if (!mapContextMenuOpen.value) return
  const panel = mapContextMenuRef.value
  if (panel?.contains(ev.target as Node)) return
  closeMapContextMenu()
}

function onKeyDownDismissContextMenu(ev: KeyboardEvent) {
  if (!mapContextMenuOpen.value) return
  if (ev.key === 'Escape') closeMapContextMenu()
}

watch(mapContextMenuOpen, (open) => {
  if (open) {
    document.addEventListener('pointerdown', onPointerDownDismissContextMenu, true)
    document.addEventListener('keydown', onKeyDownDismissContextMenu, true)
  } else {
    document.removeEventListener('pointerdown', onPointerDownDismissContextMenu, true)
    document.removeEventListener('keydown', onKeyDownDismissContextMenu, true)
  }
})

async function onCopyContextMenuLatLng() {
  const m = mapContextMenuOpen.value
  if (!m) return
  const text = formatLatLngForClipboard(m.lat, m.lng)
  const ok = await copyTextToClipboard(text)
  closeMapContextMenu()
  if (ok) toastSuccess('lng/lat copied to clipboard', 'Copied')
  else toastWarn('Clipboard was not available.', 'Copy failed')
}

const MEASURE_SOURCE_ID = 'measure-ruler'
const MEASURE_LINE_LAYER_ID = 'measure-ruler-line'
const MEASURE_ARROW_LAYER_ID = 'measure-ruler-arrow'
const MEASURE_ARROW_ICON = 'measure-arrow'
const MEASURE_EARTH_RADIUS_M = 6371000

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const p1 = (lat1 * Math.PI) / 180
  const p2 = (lat2 * Math.PI) / 180
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLng = ((lng2 - lng1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(p1) * Math.cos(p2) * Math.sin(dLng / 2) * Math.sin(dLng / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(Math.max(0, 1 - a)))
  return MEASURE_EARTH_RADIUS_M * c
}

/** Degrees clockwise from true north (0–360): initial bearing from (lat1,lng1) toward (lat2,lng2). */
function bearingDegrees(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const φ1 = (lat1 * Math.PI) / 180
  const φ2 = (lat2 * Math.PI) / 180
  const Δλ = ((lng2 - lng1) * Math.PI) / 180
  const y = Math.sin(Δλ) * Math.cos(φ2)
  const x = Math.cos(φ1) * Math.sin(φ2) - Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ)
  const θ = (Math.atan2(y, x) * 180) / Math.PI
  return (θ + 360) % 360
}

function formatMeasureDistance(meters: number): string {
  if (!Number.isFinite(meters)) return '—'
  if (meters >= 1000) return `${(meters / 1000).toFixed(2)} km`
  if (meters >= 1) return `${meters.toFixed(0)} m`
  return `${(meters * 100).toFixed(0)} cm`
}

function createMeasureArrowImageData() {
  const size = 26
  const canvas = document.createElement('canvas')
  canvas.width = size
  canvas.height = size
  const ctx = canvas.getContext('2d')
  if (!ctx) return null
  const c = size / 2
  const r = size * 0.42
  ctx.fillStyle = '#b45309'
  ctx.strokeStyle = '#fff'
  ctx.lineWidth = 1.25
  ctx.beginPath()
  ctx.moveTo(c, c - r)
  ctx.lineTo(c + r * 0.58, c + r * 0.48)
  ctx.lineTo(c - r * 0.58, c + r * 0.48)
  ctx.closePath()
  ctx.fill()
  ctx.stroke()
  const imgData = ctx.getImageData(0, 0, size, size)
  return { width: size, height: size, data: imgData.data }
}

function clearMeasureGeo() {
  const src = map?.getSource(MEASURE_SOURCE_ID)
  if (src && src.type === 'geojson') {
    src.setData({ type: 'FeatureCollection', features: [] })
  }
}

function ensureMeasureRulerLayers(): boolean {
  if (!map?.isStyleLoaded()) return false
  if (!map.getSource(MEASURE_SOURCE_ID)) {
    const img = createMeasureArrowImageData()
    if (img && !map.hasImage(MEASURE_ARROW_ICON)) map.addImage(MEASURE_ARROW_ICON, img)
    map.addSource(MEASURE_SOURCE_ID, {
      type: 'geojson',
      data: { type: 'FeatureCollection', features: [] },
    })
    map.addLayer({
      id: MEASURE_LINE_LAYER_ID,
      type: 'line',
      source: MEASURE_SOURCE_ID,
      filter: ['==', ['get', 'kind'], 'line'],
      layout: { 'line-cap': 'round', 'line-join': 'round' },
      paint: {
        'line-color': '#b45309',
        'line-width': 3,
        'line-dasharray': [2, 2],
      },
    })
    map.addLayer({
      id: MEASURE_ARROW_LAYER_ID,
      type: 'symbol',
      source: MEASURE_SOURCE_ID,
      filter: ['==', ['get', 'kind'], 'arrow'],
      layout: {
        'icon-image': MEASURE_ARROW_ICON,
        'icon-size': 0.78,
        'icon-rotate': ['get', 'bearing'],
        'icon-allow-overlap': true,
        'icon-ignore-placement': true,
        'icon-anchor': 'center',
      },
    })
  }
  return true
}

function stopMeasureMode() {
  document.removeEventListener('keydown', onKeyDownMeasureEscape, true)
  measureActive.value = null
  clearMeasureGeo()
}

function onKeyDownMeasureEscape(ev: KeyboardEvent) {
  if (ev.key !== 'Escape' || !measureActive.value) return
  stopMeasureMode()
  ev.preventDefault()
}

function layoutMeasureHudPx(px: number, py: number): { hudX: number; hudY: number } {
  const shell = shellRef.value
  if (!shell) return { hudX: 12, hudY: 12 }
  const rect = shell.getBoundingClientRect()
  const pad = 8
  const hudW = 120
  const hudH = 44
  let hudX = px + pad
  let hudY = py - hudH - pad
  if (hudX + hudW > rect.width - 4) hudX = Math.max(4, rect.width - hudW - 4)
  if (hudX < 4) hudX = 4
  if (hudY < 4) hudY = py + pad
  if (hudY + hudH > rect.height - 4) hudY = Math.max(4, rect.height - hudH - 4)
  return { hudX, hudY }
}

function refreshMeasureHudScreenCoords() {
  const st = measureActive.value
  if (!st || !map || !shellRef.value) return
  const p = map.project([st.cursorLng, st.cursorLat])
  const { hudX, hudY } = layoutMeasureHudPx(p.x, p.y)
  measureActive.value = { ...st, hudX, hudY }
}

function updateMeasureFromMouseEvent(e: maplibregl.MapMouseEvent) {
  const st = measureActive.value
  if (!st || !map) return
  if (!ensureMeasureRulerLayers()) return
  const curLat = clampLatitude(e.lngLat.lat)
  const curLng = wrapLongitude(e.lngLat.lng)
  const aLat = st.anchorLat
  const aLng = st.anchorLng
  const dist = haversineMeters(aLat, aLng, curLat, curLng)
  const brg = dist < 0.5 ? 0 : bearingDegrees(aLat, aLng, curLat, curLng)

  const src = map.getSource(MEASURE_SOURCE_ID)
  if (src && src.type === 'geojson') {
    src.setData({
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          properties: { kind: 'line' },
          geometry: {
            type: 'LineString',
            coordinates: [
              [aLng, aLat],
              [curLng, curLat],
            ],
          },
        },
        {
          type: 'Feature',
          properties: { kind: 'arrow', bearing: brg },
          geometry: { type: 'Point', coordinates: [aLng, aLat] },
        },
      ],
    })
  }

  const p = map.project([curLng, curLat])
  const { hudX, hudY } = layoutMeasureHudPx(p.x, p.y)
  measureActive.value = {
    anchorLat: aLat,
    anchorLng: aLng,
    cursorLat: curLat,
    cursorLng: curLng,
    hudX,
    hudY,
    headingDeg: brg,
    distanceM: dist,
  }
}

function onMeasureFromContextMenu() {
  const m = mapContextMenuOpen.value
  if (!m || !map) return
  const aLat = m.lat
  const aLng = m.lng
  closeMapContextMenu()

  function beginMeasure() {
    if (!map) return
    if (!ensureMeasureRulerLayers()) return
    const p = map.project([aLng, aLat])
    const { hudX, hudY } = layoutMeasureHudPx(p.x, p.y)
    measureActive.value = {
      anchorLat: aLat,
      anchorLng: aLng,
      cursorLat: aLat,
      cursorLng: aLng,
      hudX,
      hudY,
      headingDeg: 0,
      distanceM: 0,
    }
    const src = map.getSource(MEASURE_SOURCE_ID)
    if (src && src.type === 'geojson') {
      src.setData({
        type: 'FeatureCollection',
        features: [
          {
            type: 'Feature',
            properties: { kind: 'line' },
            geometry: {
              type: 'LineString',
              coordinates: [
                [aLng, aLat],
                [aLng, aLat],
              ],
            },
          },
          {
            type: 'Feature',
            properties: { kind: 'arrow', bearing: 0 },
            geometry: { type: 'Point', coordinates: [aLng, aLat] },
          },
        ],
      })
    }
    document.addEventListener('keydown', onKeyDownMeasureEscape, true)
  }

  if (map.isStyleLoaded()) beginMeasure()
  else map.once('load', beginMeasure)
}

/** Format one angle as degrees° minutes′ seconds″ hemisphere (zero-padded for stable width). */
function formatDmsAngle(value: number, isLatitude: boolean): string {
  const hemi = isLatitude ? (value >= 0 ? 'N' : 'S') : value >= 0 ? 'E' : 'W'
  const v = Math.abs(value)
  const deg = Math.floor(v + 1e-12)
  const minFull = (v - deg) * 60
  const min = Math.floor(minFull + 1e-12)
  let sec = (minFull - min) * 60
  if (sec >= 59.9995) sec = 59.99

  const degW = String(deg).padStart(isLatitude ? 2 : 3, '0')
  const minW = String(min).padStart(2, '0')
  const secParts = sec.toFixed(2).split('.')
  const secW = `${secParts[0].padStart(2, '0')}.${secParts[1]}`

  return `${degW}° ${minW}′ ${secW}″ ${hemi}`
}
let map = null
let clusterIndex = null
let viewportFetchTimeout = null
let fgTileGridDebounceTimer = null
let fgGridIdleFallbackTimer = null
let viewHistoryEmitTimer = null
let suppressViewHistoryEmit = false
/** Fingerprint of last view we pushed to the URL (see roundViewForHistory); skips prop→jumpTo when route reflects our own emit). */
let lastSelfSyncedHistoryKey: string | null = null
/** Draggable selection marker (selectionMode + selectionDraggable) */
let selectionMarker = null
/** MODEL_ADD / OBJECTS_ADD hover: single popup instance, recycled with setDOMContent */
let markerHoverPopup: maplibregl.Popup | null = null
let lastMarkerHoverKey = ''

const useViewportFetch = computed(() => !!props.mapObjectsApiUrl)

function markerIconsCompactLayout(): boolean {
  return !!(props.compact && !props.responsiveViewportHeight)
}

const MARKER_SIZE = 32
const MARKER_STATIC_COLOR = '#2563eb'
const MARKER_OTHER_COLOR = '#ea580c'

/**
 * Draw circle with arrow: tip on circle (heading direction), opposite side split at circle center.
 * All three outer vertices on the circle. MapLibre rotates icon by heading.
 */
function createMarkerImageData(fillColor) {
  const canvas = document.createElement('canvas')
  canvas.width = MARKER_SIZE
  canvas.height = MARKER_SIZE
  const ctx = canvas.getContext('2d')
  if (!ctx) return null
  const c = MARKER_SIZE / 2
  const r = MARKER_SIZE / 2
  ctx.fillStyle = fillColor
  ctx.globalAlpha = 0.25
  ctx.beginPath()
  ctx.arc(c, c, r, 0, Math.PI * 2)
  ctx.fill()
  ctx.globalAlpha = 1
  ctx.strokeStyle = '#fff'
  ctx.lineWidth = 1.5
  ctx.lineJoin = 'round'
  ctx.lineCap = 'round'
  ctx.beginPath()
  ctx.arc(c, c, r, 0, Math.PI * 2)
  ctx.stroke()
  const tipX = c
  const tipY = c - r
  const leftBaseX = c + r * Math.sqrt(3) / 2
  const leftBaseY = c + r / 2
  const rightBaseX = c - r * Math.sqrt(3) / 2
  const rightBaseY = c + r / 2
  ctx.fillStyle = fillColor
  ctx.beginPath()
  ctx.moveTo(tipX, tipY)
  ctx.lineTo(leftBaseX, leftBaseY)
  ctx.lineTo(c, c)
  ctx.lineTo(rightBaseX, rightBaseY)
  ctx.closePath()
  ctx.fill()
  ctx.stroke()
  const imgData = ctx.getImageData(0, 0, MARKER_SIZE, MARKER_SIZE)
  return { width: MARKER_SIZE, height: MARKER_SIZE, data: imgData.data }
}

function objectsToGeoJSON(objects) {
  const features = (objects || []).map((obj) => {
    const lat = obj?.position?.lat
    const lon = obj?.position?.lon
    if (lat == null || lon == null || !Number.isFinite(lat) || !Number.isFinite(lon)) return null
    const heading = obj?.position?.heading != null && Number.isFinite(Number(obj.position.heading)) ? Number(obj.position.heading) : 0
    const shared = obj?.shared != null ? Number(obj.shared) : null
    const rawMid = obj?.modelId
    const modelId =
      rawMid != null && rawMid !== '' && Number.isFinite(Number(rawMid)) && Number(rawMid) > 0 ? Number(rawMid) : null
    const modelName = obj?.modelName != null ? String(obj.modelName) : ''
    return {
      type: 'Feature',
      id: obj.id,
      properties: {
        id: obj.id,
        description: obj.description ?? '',
        type: obj.type ?? '',
        shared,
        heading,
        modelId: modelId ?? '',
        modelName,
      },
      geometry: {
        type: 'Point',
        coordinates: [Number(lon), Number(lat)],
      },
    }
  }).filter(Boolean)
  return { type: 'FeatureCollection', features }
}

function objectsToFeatures(objects) {
  const fc = objectsToGeoJSON(objects)
  return fc.features || []
}

function fitMapToObjects() {
  if (!map || !props.fitToSelection || !props.objects?.length) return
  const coords = props.objects
    .map((o: { position?: { lat?: number; lon?: number } }) => o?.position?.lat != null && o?.position?.lon != null ? [Number(o.position.lon), Number(o.position.lat)] : null)
    .filter(Boolean)
  if (!coords.length) return
  const lngs = coords.map((c) => c[0])
  const lats = coords.map((c) => c[1])
  const minLng = Math.min(...lngs)
  const maxLng = Math.max(...lngs)
  const minLat = Math.min(...lats)
  const maxLat = Math.max(...lats)
  const padding = Math.max(20, FIT_PADDING - (markerIconsCompactLayout() ? 20 : 0))
  map.fitBounds(
    [[minLng, minLat], [maxLng, maxLat]],
    { padding, maxZoom: FIT_MAX_ZOOM }
  )
}

function hideMarkerHoverPopup() {
  lastMarkerHoverKey = ''
  if (markerHoverPopup) {
    markerHoverPopup.remove()
    markerHoverPopup = null
  }
}

function parseFeatureModelHoverProps(f: { properties?: Record<string, unknown> } | undefined) {
  const p = f?.properties || {}
  const rawId = p.modelId
  const modelId =
    rawId != null && rawId !== '' && Number.isFinite(Number(rawId)) && Number(rawId) > 0 ? Number(rawId) : null
  const modelName = p.modelName != null ? String(p.modelName) : ''
  const description = p.description != null ? String(p.description) : ''
  return { modelId, modelName, description }
}

function thumbnailUrlForModel(modelId: number): string {
  const base = String(props.resourceApiBase || '/api').replace(/\/$/, '')
  return `${base}/models/${modelId}/thumbnail`
}

function handleMarkerHoverMousemove(e: maplibregl.MapMouseEvent) {
  if (!props.markerHoverCard || !map?.isStyleLoaded()) return
  let hasLayer = false
  try {
    hasLayer = !!map.getLayer('object-markers')
  } catch {
    hasLayer = false
  }
  if (!hasLayer) {
    hideMarkerHoverPopup()
    return
  }
  const hits = map.queryRenderedFeatures(e.point, { layers: ['object-markers'] })
  const f = hits[0]
  if (!f || f.geometry?.type !== 'Point') {
    hideMarkerHoverPopup()
    return
  }
  const coords = f.geometry.coordinates
  const lngLat: [number, number] = [Number(coords[0]), Number(coords[1])]
  const meta = parseFeatureModelHoverProps(f)
  if (!meta.modelId && !String(meta.description).trim()) {
    hideMarkerHoverPopup()
    return
  }
  const fid = f.properties?.id != null ? String(f.properties.id) : `${lngLat[0]},${lngLat[1]}`
  if (fid === lastMarkerHoverKey && markerHoverPopup) return

  const wrap = document.createElement('div')
  wrap.className = 'object-map-marker-hover-card'
  const title = document.createElement('div')
  title.className = 'object-map-marker-hover-card__title'
  const namePart =
    meta.modelName.trim() ||
    (meta.modelId != null ? `Model #${meta.modelId}` : 'Placement')
  title.textContent = namePart
  wrap.appendChild(title)
  if (meta.modelId != null) {
    const img = document.createElement('img')
    img.className = 'object-map-marker-hover-card__img'
    img.alt = ''
    img.loading = 'lazy'
    img.src = thumbnailUrlForModel(meta.modelId)
    wrap.appendChild(img)
  }
  const desc = meta.description.trim()
  if (desc && desc !== namePart) {
    const d = document.createElement('div')
    d.className = 'object-map-marker-hover-card__desc'
    d.textContent = desc
    wrap.appendChild(d)
  }

  if (!markerHoverPopup) {
    markerHoverPopup = new maplibregl.Popup({
      closeButton: false,
      closeOnClick: false,
      focusAfterOpen: false,
      offset: 16,
      maxWidth: '280px',
      className: 'object-map-marker-hover-popup',
    })
  }
  markerHoverPopup.setLngLat(lngLat).setDOMContent(wrap).addTo(map)
  lastMarkerHoverKey = fid
}

function getBboxFromMap() {
  if (!map) return null
  const b = map.getBounds()
  const sw = b.getSouthWest()
  const ne = b.getNorthEast()
  return [sw.lng, sw.lat, ne.lng, ne.lat]
}

function selectionToGeoJSON(pos) {
  if (!pos || typeof pos.lat !== 'number' || typeof pos.lon !== 'number') return { type: 'FeatureCollection', features: [] }
  return {
    type: 'FeatureCollection',
    features: [{
      type: 'Feature',
      properties: {},
      geometry: { type: 'Point', coordinates: [Number(pos.lon), Number(pos.lat)] },
    }],
  }
}

function updateSelectionMarker() {
  if (!map || !props.selectionMode || props.selectionDraggable) return
  const source = map.getSource('selection-marker')
  if (!source) return
  source.setData(selectionToGeoJSON(props.selectionPosition))
}

const COORD_EPS = 1e-7

function updateDraggableSelectionMarker() {
  if (!map || !props.selectionMode || !props.selectionDraggable || !selectionMarker) return
  const pos = props.selectionPosition
  if (!pos || typeof pos.lat !== 'number' || typeof pos.lon !== 'number') return
  if (!Number.isFinite(pos.lat) || !Number.isFinite(pos.lon)) return
  const ll = selectionMarker.getLngLat()
  if (
    Math.abs(ll.lat - pos.lat) < COORD_EPS &&
    Math.abs(ll.lng - pos.lon) < COORD_EPS
  ) {
    return
  }
  selectionMarker.setLngLat([Number(pos.lon), Number(pos.lat)])
}

function updateClustersDisplay() {
  if (!map || !clusterIndex) return
  const source = map.getSource('objects')
  if (!source) return
  const bbox = getBboxFromMap()
  const zoom = Math.floor(map.getZoom())
  if (!bbox) return
  const features = clusterIndex.getClusters(bbox, zoom)
  source.setData({ type: 'FeatureCollection', features })
}

function clearObjectsSource() {
  if (!map) return
  const source = map.getSource('objects')
  if (source) source.setData({ type: 'FeatureCollection', features: [] })
  clusterIndex = null
}

function clearGridSource() {
  if (!map) return
  const source = map.getSource('grid')
  if (source) source.setData({ type: 'FeatureCollection', features: [] })
}

function gridToGeoJSON(grid) {
  if (!grid || !grid.cells?.length) return { type: 'FeatureCollection', features: [] }
  const { minLng, minLat, maxLng, maxLat, cols, rows } = grid
  const w = (maxLng - minLng) / cols
  const h = (maxLat - minLat) / rows
  const features = grid.cells.map(({ x, y, count }) => {
    const cellMinLng = minLng + x * w
    const cellMaxLng = minLng + (x + 1) * w
    const cellMinLat = minLat + y * h
    const cellMaxLat = minLat + (y + 1) * h
    return {
      type: 'Feature',
      properties: { count },
      geometry: {
        type: 'Polygon',
        coordinates: [[
          [cellMinLng, cellMinLat],
          [cellMaxLng, cellMinLat],
          [cellMaxLng, cellMaxLat],
          [cellMinLng, cellMaxLat],
          [cellMinLng, cellMinLat],
        ]],
      },
    }
  })
  return { type: 'FeatureCollection', features }
}

function setGridData(grid) {
  if (!map) return
  const source = map.getSource('grid')
  if (!source) return
  source.setData(gridToGeoJSON(grid))
}

async function fetchForViewport() {
  if (!map || !props.mapObjectsApiUrl) return
  const zoom = map.getZoom()
  if (zoom < MIN_ZOOM_FOR_FETCH) {
    clearObjectsSource()
    clearGridSource()
    return
  }
  const bbox = getBboxFromMap()
  if (!bbox) return
  const [minLng, minLat, maxLng, maxLat] = bbox
  const url = `${props.mapObjectsApiUrl}?bbox=${minLng},${minLat},${maxLng},${maxLat}&limit=${MAP_FETCH_LIMIT}`
  try {
    const res = await fetch(url, { credentials: 'include' })
    if (!res.ok) {
      const data = await res.json().catch(() => ({}))
      if (data.code === 'BBOX_TOO_LARGE') {
        clearObjectsSource()
        clearGridSource()
      }
      return
    }
    const data = await res.json()
    if (data.objects != null) {
      clearGridSource()
      const features = objectsToFeatures(data.objects)
      clusterIndex = new Supercluster({ radius: 50, maxZoom: 18 })
      clusterIndex.load(features)
      updateClustersDisplay()
    } else if (data.grid) {
      clearObjectsSource()
      setGridData(data.grid)
    }
  } catch {
    // ignore network errors
  }
}

function scheduleViewportFetch() {
  if (viewportFetchTimeout) clearTimeout(viewportFetchTimeout)
  viewportFetchTimeout = setTimeout(() => {
    viewportFetchTimeout = null
    fetchForViewport()
  }, VIEWPORT_FETCH_DEBOUNCE_MS)
}

function addViewportModeLayers() {
  if (!map) return
  map.addSource('objects', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } })
  map.addSource('grid', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } })
  map.addLayer({
    id: 'grid-fill',
    type: 'fill',
    source: 'grid',
    paint: {
      'fill-color': '#2563eb',
      'fill-opacity': 0.0,
      'fill-outline-color': '#2563eb',
    },
  })
  map.addLayer({
    id: 'grid-label',
    type: 'symbol',
    source: 'grid',
    layout: {
      'text-field': ['to-string', ['get', 'count']],
      'text-size': 11,
    },
    paint: { 'text-color': '#1e40af' },
  })
  map.addLayer({
    id: 'object-markers',
    type: 'symbol',
    source: 'objects',
    filter: ['!', ['has', 'point_count']],
    layout: {
      'icon-image': ['match', ['get', 'shared'], 0, 'marker-static', 'marker-other'],
      'icon-size': markerIconsCompactLayout() ? 0.65 : 0.85,
      'icon-rotate': ['get', 'heading'],
      'icon-allow-overlap': true,
      'icon-ignore-placement': true,
      'icon-anchor': 'center',
    },
  })
  map.addLayer({
    id: 'object-clusters',
    type: 'circle',
    source: 'objects',
    filter: ['has', 'point_count'],
    paint: {
      'circle-radius': ['step', ['get', 'point_count'], 14, 10, 18, 100, 22],
      'circle-color': '#2563eb',
      'circle-stroke-width': 2,
      'circle-stroke-color': '#fff',
    },
  })
  map.addLayer({
    id: 'object-cluster-count',
    type: 'symbol',
    source: 'objects',
    filter: ['has', 'point_count'],
    layout: {
      'text-field': ['to-string', ['get', 'point_count']],
      'text-size': 12,
    },
    paint: { 'text-color': '#fff' },
  })
}

function updateSource() {
  if (!map) return
  const source = map.getSource('objects')
  const geojson = objectsToGeoJSON(props.objects)
  if (source) {
    source.setData(geojson)
  } else {
    map.addSource('objects', { type: 'geojson', data: geojson })
    map.addLayer({
      id: 'object-markers',
      type: 'symbol',
      source: 'objects',
      layout: {
        'icon-image': ['match', ['get', 'shared'], 0, 'marker-static', 'marker-other'],
        'icon-size': markerIconsCompactLayout() ? 0.65 : 0.85,
        'icon-rotate': ['get', 'heading'],
        'icon-allow-overlap': true,
        'icon-ignore-placement': true,
        'icon-anchor': 'center',
      },
    })
  }
  if (props.fitToSelection && props.objects?.length) {
    setTimeout(fitMapToObjects, 50)
  }
}

onMounted(() => {
  if (!containerRef.value) return
  const [lng, lat] = Array.isArray(props.initialCenter) && props.initialCenter.length >= 2
    ? props.initialCenter
    : DEFAULT_CENTER
  const zoom = Number.isFinite(props.initialZoom) ? props.initialZoom : DEFAULT_ZOOM

  map = new maplibregl.Map({
    container: containerRef.value,
    style: OSM_STYLE,
    center: [Number(lng), Number(lat)],
    zoom,
    maxZoom: 19,
  })

  map.addControl(new maplibregl.NavigationControl(), 'top-right')

  if (props.mapContextMenu) {
    map.on('contextmenu', (e) => {
      e.originalEvent.preventDefault()
      if (measureActive.value) {
        stopMeasureMode()
        return
      }
      openMapContextMenuFromMapEvent(e)
    })
    map.on('movestart', closeMapContextMenu)
    map.on('wheel', closeMapContextMenu)
  }

  map.on('mousemove', (e) => {
    const lat = clampLatitude(e.lngLat.lat)
    const lng = wrapLongitude(e.lngLat.lng)
    pointerReadout.value = {
      tileIndex: fgTileIndex(lat, lng),
      dmsLat: formatDmsAngle(lat, true),
      dmsLon: formatDmsAngle(lng, false),
      decLat: lat.toFixed(6),
      decLon: lng.toFixed(6),
    }
    if (measureActive.value) updateMeasureFromMouseEvent(e)
    if (props.markerHoverCard) handleMarkerHoverMousemove(e)
  })
  map.on('mouseout', () => {
    pointerReadout.value = null
    hideMarkerHoverPopup()
  })

  map.on('move', () => {
    if (measureActive.value) refreshMeasureHudScreenCoords()
  })

  function updateFgTileGrid() {
    if (!map?.isStyleLoaded()) return
    const src = map.getSource('fg-scenery-tile-grid')
    if (!src || src.type !== 'geojson') return
    const z = map.getZoom()
    if (z < FG_GRID_MIN_ZOOM) {
      src.setData({ type: 'FeatureCollection', features: [] })
      return
    }
    const b = map.getBounds()
    const west = b.getWest()
    const south = b.getSouth()
    const east = b.getEast()
    const north = b.getNorth()
    let lonSpan = east - west
    if (lonSpan < 0) lonSpan += 360
    const latSpan = north - south
    const { lon: maxLon, lat: maxLat } = fgGridMaxSpans(z)
    if (lonSpan > maxLon || latSpan > maxLat) {
      src.setData({ type: 'FeatureCollection', features: [] })
      return
    }
    const bounds = { west, south, east, north }
    const gridOpts = {
      maxSegments: fgGridMaxSegments(z),
      meridiansOnly: z < 7,
    }
    requestAnimationFrame(() => {
      if (!map?.isStyleLoaded()) return
      const s = map.getSource('fg-scenery-tile-grid')
      if (!s || s.type !== 'geojson') return
      s.setData(fgTileGridFeatureCollection(bounds, gridOpts))
    })
  }

  function scheduleFgTileGridUpdate() {
    if (fgTileGridDebounceTimer) clearTimeout(fgTileGridDebounceTimer)
    fgTileGridDebounceTimer = setTimeout(() => {
      fgTileGridDebounceTimer = null
      updateFgTileGrid()
    }, FG_GRID_DEBOUNCE_MS)
  }

  function ensureFgTileGridLayer() {
    if (!map || map.getSource('fg-scenery-tile-grid')) return
    map.addSource('fg-scenery-tile-grid', {
      type: 'geojson',
      data: { type: 'FeatureCollection', features: [] },
    })
    map.addLayer({
      id: 'fg-scenery-tile-grid-lines',
      type: 'line',
      source: 'fg-scenery-tile-grid',
      minzoom: FG_GRID_MIN_ZOOM,
      layout: { 'line-join': 'miter', 'line-cap': 'butt' },
      paint: {
        'line-color': '#64748b',
        'line-width': props.compact ? 0.65 : 0.9,
        'line-opacity': 0.52,
      },
    })
  }

  function addMarkerImagesThenLayers() {
    ensureFgTileGridLayer()
    /** Defer grid until map is idle so first paint + tiles are not blocked by GeoJSON work. */
    if (fgGridIdleFallbackTimer) clearTimeout(fgGridIdleFallbackTimer)
    fgGridIdleFallbackTimer = setTimeout(() => {
      fgGridIdleFallbackTimer = null
      scheduleFgTileGridUpdate()
    }, 450)
    map.once('idle', () => {
      if (fgGridIdleFallbackTimer != null) {
        clearTimeout(fgGridIdleFallbackTimer)
        fgGridIdleFallbackTimer = null
      }
      scheduleFgTileGridUpdate()
    })
    const staticData = createMarkerImageData(MARKER_STATIC_COLOR)
    const otherData = createMarkerImageData(MARKER_OTHER_COLOR)
    if (staticData && !map.hasImage('marker-static')) {
      map.addImage('marker-static', staticData)
    }
    if (otherData && !map.hasImage('marker-other')) {
      map.addImage('marker-other', otherData)
    }
    if (props.selectionMode && props.selectionDraggable) {
      const pos = props.selectionPosition
      const mLng =
        pos && typeof pos.lon === 'number' && Number.isFinite(pos.lon) ? Number(pos.lon) : Number(lng)
      const mLat =
        pos && typeof pos.lat === 'number' && Number.isFinite(pos.lat) ? Number(pos.lat) : Number(lat)
      selectionMarker = new maplibregl.Marker({ color: '#dc2626', draggable: true })
        .setLngLat([mLng, mLat])
        .addTo(map)
      selectionMarker.on('dragend', () => {
        const end = selectionMarker.getLngLat()
        emit('position-select', { lat: end.lat, lon: end.lng })
      })
    } else if (props.selectionMode) {
      map.addSource('selection-marker', {
        type: 'geojson',
        data: selectionToGeoJSON(props.selectionPosition),
      })
      map.addLayer({
        id: 'selection-marker-layer',
        type: 'circle',
        source: 'selection-marker',
        paint: {
          'circle-radius': 10,
          'circle-color': '#dc2626',
          'circle-stroke-width': 3,
          'circle-stroke-color': '#fff',
        },
      })
    }
    if (useViewportFetch.value) {
      addViewportModeLayers()
      scheduleViewportFetch()
    } else {
      if (props.objects?.length) {
        updateSource()
        if (props.fitToSelection) fitMapToObjects()
      }
    }
  }

  map.on('load', addMarkerImagesThenLayers)

  if (props.selectionMode && !props.selectionDraggable) {
    map.on('click', (e) => {
      if (props.selectionSkipWhenFeatureHit) {
        const layers = ['object-markers', 'object-clusters', 'object-cluster-count'].filter((id) => {
          try {
            return !!map.getLayer(id)
          } catch {
            return false
          }
        })
        if (layers.length) {
          const hit = map.queryRenderedFeatures(e.point, { layers })
          if (hit.length) return
        }
      }
      emit('position-select', { lat: e.lngLat.lat, lon: e.lngLat.lng })
    })
  }

  function scheduleViewHistoryEmit() {
    if (!props.syncViewToHistory || !map || suppressViewHistoryEmit) return
    if (viewHistoryEmitTimer) clearTimeout(viewHistoryEmitTimer)
    viewHistoryEmitTimer = setTimeout(() => {
      viewHistoryEmitTimer = null
      if (!map || suppressViewHistoryEmit) return
      const c = map.getCenter()
      const z = map.getZoom()
      const r = roundViewForHistory(c, z)
      lastSelfSyncedHistoryKey = historyKeyFromRounded(r)
      emit('view-change', { lng: c.lng, lat: c.lat, zoom: z })
    }, 450)
  }

  map.on('moveend', () => {
    scheduleFgTileGridUpdate()
    if (props.syncViewToHistory) scheduleViewHistoryEmit()
    if (!useViewportFetch.value) return
    if (clusterIndex) updateClustersDisplay()
    scheduleViewportFetch()
  })

  function onClusterClick(e) {
    const f = e.features?.[0]
    const id = f?.properties?.cluster_id
    if (id != null && clusterIndex) {
      const expansionZoom = clusterIndex.getClusterExpansionZoom(id)
      map.flyTo({ center: f.geometry.coordinates, zoom: expansionZoom })
    }
  }
  map.on('click', 'object-clusters', onClusterClick)
  map.on('click', 'object-cluster-count', onClusterClick)

  map.on('click', 'object-markers', (e) => {
    const f = e.features?.[0]
    if (f?.properties?.id != null) emit('object-click', f.properties.id)
  })

  /** MapLibre CSS sets `cursor: grab` on `.maplibregl-canvas-container.maplibregl-interactive`; set cursor on that node so hover states win. */
  const setCursor = (cursor) => {
    const next =
      cursor && String(cursor).length > 0
        ? cursor
        : props.selectionMode && props.selectionDraggable
          ? 'grab'
          : 'crosshair'
    const canvasContainer = map.getCanvasContainer()
    const canvas = map.getCanvas()
    if (canvasContainer) canvasContainer.style.cursor = next
    if (canvas) canvas.style.cursor = next
    if (containerRef.value) containerRef.value.style.cursor = next
  }
  map.on('mouseenter', 'object-clusters', () => setCursor('pointer'))
  map.on('mouseleave', 'object-clusters', () => setCursor(''))
  map.on('mouseenter', 'object-cluster-count', () => setCursor('pointer'))
  map.on('mouseleave', 'object-cluster-count', () => setCursor(''))
  map.on('mouseenter', 'object-markers', () => setCursor('pointer'))
  map.on('mouseleave', 'object-markers', () => setCursor(''))

  /** MapLibre sets `grab` on the canvas container; apply our default (crosshair / grab) once it exists. */
  function primeDefaultMapCursor() {
    requestAnimationFrame(() => {
      if (!map) return
      setCursor('')
    })
  }
  if (map.loaded()) primeDefaultMapCursor()
  else map.once('load', primeDefaultMapCursor)
  map.once('idle', primeDefaultMapCursor)
})

watch(
  () => [props.objects, props.fitToSelection],
  () => {
    if (!map || useViewportFetch.value) return
    if (!map.isStyleLoaded()) {
      map.once('load', updateSource)
      return
    }
    updateSource()
  },
  { deep: true }
)

watch(
  () => [props.objects, props.markerHoverCard, props.resourceApiBase],
  () => {
    hideMarkerHoverPopup()
  },
  { deep: true }
)

watch(
  () => props.selectionPosition,
  () => {
    if (!props.selectionMode) return
    if (!map) return
    if (!map.isStyleLoaded()) {
      map.once('load', () => {
        if (props.selectionDraggable) updateDraggableSelectionMarker()
        else updateSelectionMarker()
      })
      return
    }
    if (props.selectionDraggable) updateDraggableSelectionMarker()
    else updateSelectionMarker()
  },
  { deep: true }
)

watch(
  () => {
    if (!props.syncViewToHistory) return ''
    const arr = props.initialCenter
    if (!Array.isArray(arr) || arr.length < 2) return ''
    const lng = Number(arr[0])
    const lat = Number(arr[1])
    const z = Number(props.initialZoom)
    if (!Number.isFinite(lng) || !Number.isFinite(lat) || !Number.isFinite(z)) return ''
    return historyKeyFromRounded(roundViewForHistory({ lng, lat }, z))
  },
  (key) => {
    if (!map || !props.syncViewToHistory || !key) return
    if (lastSelfSyncedHistoryKey !== null && key === lastSelfSyncedHistoryKey) {
      return
    }
    const parts = key.split(',').map(Number)
    const [lng, lat, zoom] = parts
    const c = map.getCenter()
    const z = map.getZoom()
    const r = roundViewForHistory(c, z)
    if (
      Math.abs(r.lng - lng) < 1e-6 &&
      Math.abs(r.lat - lat) < 1e-6 &&
      Math.abs(r.zoom - zoom) < 1e-4
    ) {
      return
    }
    suppressViewHistoryEmit = true
    lastSelfSyncedHistoryKey = historyKeyFromRounded(roundViewForHistory({ lng, lat }, zoom))
    map.jumpTo({ center: [lng, lat], zoom })
    requestAnimationFrame(() => {
      suppressViewHistoryEmit = false
    })
  },
  { flush: 'post' }
)

onBeforeUnmount(() => {
  hideMarkerHoverPopup()
  stopMeasureMode()
  document.removeEventListener('pointerdown', onPointerDownDismissContextMenu, true)
  document.removeEventListener('keydown', onKeyDownDismissContextMenu, true)
  if (viewportFetchTimeout) clearTimeout(viewportFetchTimeout)
  if (fgTileGridDebounceTimer) clearTimeout(fgTileGridDebounceTimer)
  if (fgGridIdleFallbackTimer) clearTimeout(fgGridIdleFallbackTimer)
  if (viewHistoryEmitTimer) {
    clearTimeout(viewHistoryEmitTimer)
    viewHistoryEmitTimer = null
  }
  if (selectionMarker) {
    selectionMarker.remove()
    selectionMarker = null
  }
  if (map) {
    map.remove()
    map = null
  }
  clusterIndex = null
  lastSelfSyncedHistoryKey = null
})
</script>

<style scoped>
.object-map-shell {
  position: relative;
  width: 100%;
  height: 400px;
  min-height: 200px;
  border-radius: 6px;
  overflow: hidden;
}
.object-map-maplibre-root {
  width: 100%;
  height: 100%;
  cursor: crosshair;
}
.object-map-draggable-selection .object-map-maplibre-root {
  cursor: grab;
}
.object-map-maplibre-root :deep(.maplibregl-ctrl button),
.object-map-maplibre-root :deep(.maplibregl-ctrl-group button) {
  cursor: pointer;
}
.map-html-overlays {
  position: absolute;
  inset: 0;
  z-index: 20;
  pointer-events: none;
  isolation: isolate;
}
.object-map-shell.object-map-compact {
  height: 240px;
  min-height: 160px;
}
/** Taller inset maps on wide viewports: scales with vw and vh (caps avoid excessive height). */
.object-map-shell.object-map-responsive-vh {
  height: clamp(220px, min(42vw, 62vh), 720px);
  min-height: 220px;
  max-height: min(72vh, 720px);
}
.map-pointer-readout {
  position: absolute;
  left: 8px;
  bottom: 8px;
  z-index: 2;
  pointer-events: none;
  box-sizing: border-box;
  width: max-content;
  max-width: calc(100% - 16px);
  padding: 8px 10px;
  font-family: ui-monospace, 'Cascadia Code', 'SF Mono', Menlo, monospace;
  font-size: 10.5px;
  line-height: 1.4;
  font-variant-numeric: tabular-nums;
  color: #0f172a;
  background: rgba(255, 255, 255, 0.93);
  border-radius: 6px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.12);
  border: 1px solid rgba(148, 163, 184, 0.5);
  overflow-x: auto;
  overscroll-behavior-x: contain;
}
.map-pointer-readout__row {
  display: block;
  margin-top: 4px;
  white-space: nowrap;
}
.map-pointer-readout__row:first-child {
  margin-top: 0;
}
.map-pointer-readout__label {
  color: #64748b;
  font-weight: 600;
}
.map-pointer-readout__value {
  display: block;
}
.object-map-selectable {
  cursor: crosshair;
}
.object-map-draggable-selection {
  cursor: grab;
}
.object-map-draggable-selection :deep(.maplibregl-marker) {
  cursor: grab;
}
.object-map-draggable-selection :deep(.maplibregl-marker:active) {
  cursor: grabbing;
}

.map-airport-search {
  position: absolute;
  top: 6px;
  left: 6px;
  z-index: 2;
  display: flex;
  flex-direction: column;
  gap: 4px;
  max-width: min(200px, calc(100% - 80px));
  pointer-events: auto;
  opacity: 0.88;
  transition: opacity 0.15s ease;
}
.map-airport-search:hover,
.map-airport-search:focus-within {
  opacity: 1;
}
.map-airport-search__form {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 3px 5px 3px 6px;
  background: rgba(255, 255, 255, 0.55);
  border-radius: 4px;
  box-shadow: 0 0 0 1px rgba(255, 255, 255, 0.35) inset;
  border: 1px solid rgba(148, 163, 184, 0.22);
  backdrop-filter: blur(5px);
}
/* InputText root is the <input> (custom class merged onto the same node). */
.map-airport-search__input {
  flex: 1;
  min-width: 0;
  width: 4.25rem;
  padding: 0.2rem 0.35rem !important;
  font-family: ui-monospace, 'Cascadia Code', 'SF Mono', Menlo, monospace;
  font-size: 0.7rem;
  background: transparent !important;
  border: none !important;
  box-shadow: none !important;
  color: #334155;
}
.map-airport-search__input:enabled:focus {
  outline: none;
  box-shadow: 0 0 0 1px rgba(100, 116, 139, 0.35) !important;
}
.map-airport-search__input::placeholder {
  color: rgba(100, 116, 139, 0.65);
}
.map-airport-search__msg {
  padding: 4px 7px;
  font-size: 10.5px;
  line-height: 1.3;
  color: #475569;
  background: rgba(255, 255, 255, 0.62);
  border-radius: 4px;
  border: 1px solid rgba(148, 163, 184, 0.2);
  backdrop-filter: blur(4px);
}
.map-context-menu {
  position: absolute;
  z-index: 40;
  min-width: 11rem;
  padding: 4px 0;
  pointer-events: auto;
  background: rgba(255, 255, 255, 0.98);
  border: 1px solid rgba(148, 163, 184, 0.45);
  border-radius: 6px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}
.map-context-menu__item {
  display: block;
  width: 100%;
  margin: 0;
  padding: 8px 12px;
  border: none;
  background: transparent;
  text-align: left;
  font-size: 0.8125rem;
  color: #0f172a;
  cursor: pointer;
}
.map-context-menu__item:hover,
.map-context-menu__item:focus-visible {
  background: rgba(241, 245, 249, 0.95);
  outline: none;
}

.map-measure-hud {
  position: absolute;
  z-index: 35;
  min-width: 6.5rem;
  padding: 6px 10px;
  pointer-events: none;
  font-family: ui-monospace, 'Cascadia Code', 'SF Mono', Menlo, monospace;
  font-size: 11px;
  line-height: 1.35;
  font-variant-numeric: tabular-nums;
  color: #0f172a;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 6px;
  border: 1px solid rgba(180, 83, 9, 0.45);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.12);
}
.map-measure-hud__heading {
  font-weight: 600;
  color: #9a3412;
}
.map-measure-hud__dist {
  color: #334155;
}

.map-airport-search__msg--err {
  color: #9f1239;
  border-color: rgba(244, 63, 94, 0.22);
  background: rgba(255, 241, 242, 0.75);
}
</style>

<style>
/* MapLibre hoists popups outside the Vue root; keep these global. */
.object-map-marker-hover-popup .maplibregl-popup-content {
  padding: 0;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.18);
}
.object-map-marker-hover-card {
  padding: 8px 10px 10px;
  max-width: 260px;
  background: rgba(255, 255, 255, 0.98);
  color: #0f172a;
}
.object-map-marker-hover-card__title {
  font-weight: 600;
  font-size: 0.8125rem;
  line-height: 1.3;
  margin-bottom: 6px;
}
.object-map-marker-hover-card__img {
  display: block;
  width: 100%;
  max-height: 140px;
  object-fit: contain;
  border-radius: 4px;
  background: #f1f5f9;
}
.object-map-marker-hover-card__desc {
  margin-top: 6px;
  font-size: 0.75rem;
  line-height: 1.35;
  color: #475569;
  word-break: break-word;
}
.dark .object-map-marker-hover-card {
  background: rgba(30, 41, 59, 0.98);
  color: #f1f5f9;
}
.dark .object-map-marker-hover-card__img {
  background: #0f172a;
}
.dark .object-map-marker-hover-card__desc {
  color: #94a3b8;
}
</style>
