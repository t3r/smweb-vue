<template>
  <div
    class="object-map-shell object-map-container"
    :class="{
      'object-map-compact': compact,
      'object-map-selectable': selectionMode && !selectionDraggable,
      'object-map-draggable-selection': selectionMode && selectionDraggable,
    }"
  >
    <div ref="containerRef" class="object-map-maplibre-root"></div>
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
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, onBeforeUnmount, computed } from 'vue'
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
})

const emit = defineEmits(['object-click', 'position-select', 'view-change'])

const containerRef = ref(null)

/** Bottom-left readout while cursor is over the map (mousemove). */
const pointerReadout = ref(null)

function wrapLongitude(lng: number): number {
  let x = lng
  while (x > 180) x -= 360
  while (x < -180) x += 360
  return x
}

function clampLatitude(lat: number): number {
  return Math.max(-90, Math.min(90, lat))
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

const useViewportFetch = computed(() => !!props.mapObjectsApiUrl)

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
    return {
      type: 'Feature',
      id: obj.id,
      properties: {
        id: obj.id,
        description: obj.description ?? '',
        type: obj.type ?? '',
        shared,
        heading,
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
  const padding = Math.max(20, FIT_PADDING - (props.compact ? 20 : 0))
  map.fitBounds(
    [[minLng, minLat], [maxLng, maxLat]],
    { padding, maxZoom: FIT_MAX_ZOOM }
  )
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
      'icon-size': props.compact ? 0.65 : 0.85,
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
        'icon-size': props.compact ? 0.65 : 0.85,
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
  })
  map.on('mouseout', () => {
    pointerReadout.value = null
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

  const setCursor = (cursor) => {
    if (containerRef.value) containerRef.value.style.cursor = cursor
  }
  map.on('mouseenter', 'object-clusters', () => setCursor('pointer'))
  map.on('mouseleave', 'object-clusters', () => setCursor(''))
  map.on('mouseenter', 'object-markers', () => setCursor('pointer'))
  map.on('mouseleave', 'object-markers', () => setCursor(''))
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
}
.object-map-shell.object-map-compact {
  height: 240px;
  min-height: 160px;
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
</style>
