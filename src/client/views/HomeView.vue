<template>
  <div>
    <h1 class="mt-0">FlightGear Scenery Repository</h1>
    <p class="text-color-secondary mb-4">
      Welcome to the New FlightGear Scenery Repository.
    </p>
    <p>
    For decades, our PHP-based scenery platform has been a trusted cornerstone of the FlightGear community — reliably serving thousands of 3D object placements and worldwide position data to simmers across the globe. <br />
Now we've rebuilt it from the ground up. The new platform is based on a modern Vue 3 + Node.js + PostgreSQL architecture, is fully open source, and available on <a href="https://github.com/t3r/smweb-vue">GitHub</a>.
</p>
<p>The codebase is backed by hundreds of automated tests and a continuous build and deployment pipeline, so contributions are easier, improvements and fixes reach you faster.<br />
Dependencies are kept up to date automatically via Dependabot, keeping the platform secure and maintainable long into the future. <br />
Contributing to the dataset has never been easier. A streamlined workflow lets community members submit and manage 3D scenery objects and their geographic positions with less friction, while a cleaner review process helps maintainers evaluate and approve contributions efficiently. <br />
Role-based access control ensures that contributors, reviewers, and administrators each have clearly defined permissions — keeping collaboration both open and well-organized.
</p>
<p>Same trusted data. Modern tools. <br />
Built by the community, for the community.</p>

    <h2>Temporarily limited write access</h2>
    <p>During an initial phase, this site restricts contributions to Admins only. <br />
    We want to make sure everything works as expected before opening all service for public access. </br >
    Feel free to look around. The old site is still available at <a href="https://legacy.scenery.flightgear.org">https://legacy.scenery.flightgear.org</a>.
    </p>
    <Card class="mb-4">
      <template #title>Statistics</template>
      <template #content>
        <p v-if="statsLoading" class="m-0">Loading…</p>
        <template v-else>
          <p class="m-0 mb-3">
            {{ stats.models }} models · {{ stats.objects }} objects · {{ stats.authors }} authors ·
            {{ stats.pendingRequests }}
            pending request{{ stats.pendingRequests === 1 ? '' : 's' }}
          </p>
          <p v-if="!statsSeries.length" class="m-0 text-color-secondary stats-chart-empty">
            No rows in <code>fgs_statistics</code> yet — history chart will appear once snapshot data exists.
          </p>
          <div v-else-if="statsChart" class="stats-chart-block">
            <p class="stats-chart-hint m-0 text-color-secondary">
              Look, how our database has evolved over time!
            </p>
            <div
              class="stats-chart-stack"
              role="group"
              :aria-label="statsChartAriaLabel"
            >
              <div
                v-for="panel in statsChart.panels"
                :key="panel.key"
                class="stats-chart-panel"
              >
                <svg
                  class="stats-chart-svg stats-chart-panel-svg"
                  :viewBox="`0 0 ${panel.w} ${panel.h}`"
                  preserveAspectRatio="xMidYMid meet"
                  aria-hidden="true"
                  focusable="false"
                >
                  <text
                    :x="panel.padL"
                    :y="panel.titleY"
                    class="stats-chart-row-title"
                    :class="`stats-chart-row-title--${panel.key}`"
                  >
                    {{ panel.title }}
                  </text>
                  <line
                    v-for="(g, i) in panel.gridLines"
                    :key="`${panel.key}-g${i}`"
                    class="stats-chart-grid"
                    :x1="panel.padL"
                    :y1="g.y"
                    :x2="panel.w - panel.padR"
                    :y2="g.y"
                  />
                  <text
                    v-for="(g, i) in panel.yLabels"
                    :key="`${panel.key}-yl${i}`"
                    class="stats-chart-y-label"
                    :class="`stats-chart-y-label--${panel.key}`"
                    :x="panel.padL - 6"
                    :y="g.y"
                    text-anchor="end"
                  >
                    {{ g.label }}
                  </text>
                  <polyline
                    fill="none"
                    :class="`stats-chart-line stats-chart-line--${panel.key}`"
                    :points="panel.points"
                  />
                  <template v-if="panel.xBaselineY != null && panel.xAxisLabels">
                    <line
                      class="stats-chart-x-baseline"
                      :x1="panel.padL"
                      :y1="panel.xBaselineY"
                      :x2="panel.w - panel.padR"
                      :y2="panel.xBaselineY"
                    />
                    <text
                      v-for="(xl, i) in panel.xAxisLabels"
                      :key="'xlab-' + panel.key + '-' + i"
                      class="stats-chart-x-label"
                      :class="{ 'stats-chart-x-label--muted': xl.muted }"
                      :x="xl.x"
                      :y="xl.y"
                      :text-anchor="xl.anchor"
                      dominant-baseline="alphabetic"
                    >
                      {{ xl.label }}
                    </text>
                  </template>
                </svg>
              </div>
            </div>
            <div class="stats-chart-legend">
              <span class="stats-chart-legend-item"><span class="stats-chart-swatch stats-chart-swatch--models" aria-hidden="true" /> Models</span>
              <span class="stats-chart-legend-item"><span class="stats-chart-swatch stats-chart-swatch--objects" aria-hidden="true" /> Objects</span>
              <span class="stats-chart-legend-item"><span class="stats-chart-swatch stats-chart-swatch--authors" aria-hidden="true" /> Authors</span>
            </div>
          </div>
        </template>
      </template>
    </Card>

    <Card class="mb-4">
      <template #title>News</template>
      <template #content>
        <p v-if="newsLoading" class="m-0">Loading…</p>
        <p v-else-if="newsError" class="m-0 text-color-secondary">{{ newsError }}</p>
        <template v-else-if="news.length">
          <ul class="news-list list-none p-0 m-0">
            <li v-for="item in news" :key="item.id" class="news-item py-2 border-bottom-1 surface-border">
              <span class="news-date text-color-secondary">{{ formatNewsDate(item.timestamp) }}</span>
              <NewsTextWithLinks :text="item.text" :author-id="item.authorId" :author-name="item.authorName" />
            </li>
          </ul>
          <div class="mt-2">
            <router-link to="/news" class="news-more-link">
              <Button label="More" icon="pi pi-arrow-right" icon-pos="right" text size="small" />
            </router-link>
          </div>
        </template>
        <p v-else class="m-0 text-color-secondary">No news yet.</p>
      </template>
    </Card>

    <div class="grid grid-nogutter gap-4">
      <Card>
        <template #title>Recently updated objects</template>
        <template #content>
          <p v-if="recentObjectsLoading" class="m-0">Loading…</p>
          <p v-else-if="recentObjectsError" class="m-0 text-color-secondary">Could not load this list.</p>
          <p v-else-if="!recentObjects.length" class="m-0 text-color-secondary">No objects yet.</p>
          <ul v-else class="list-none p-0 m-0">
            <li v-for="obj in recentObjects" :key="obj.id" class="flex align-items-center gap-2 py-2 border-bottom-1 surface-border">
              <img
                :src="thumbnailUrl(obj.modelId)"
                :alt="obj.description || 'Object'"
                class="object-thumb"
                @error="onThumbError"
              />
              <router-link :to="`/objects/${obj.id}`" class="object-model-link">{{ obj.description || 'Unnamed' }}</router-link>
            </li>
          </ul>
        </template>
      </Card>
      <Card>
        <template #title>Recently updated models</template>
        <template #content>
          <p v-if="recentModelsLoading" class="m-0">Loading…</p>
          <p v-else-if="recentModelsError" class="m-0 text-color-secondary">Could not load this list.</p>
          <p v-else-if="!recentModels.length" class="m-0 text-color-secondary">No models yet.</p>
          <ul v-else class="list-none p-0 m-0">
            <li v-for="model in recentModels" :key="model.id" class="flex align-items-center gap-2 py-2 border-bottom-1 surface-border">
              <img
                :src="thumbnailUrl(model.id)"
                :alt="model.name || 'Model'"
                class="object-thumb"
                @error="onThumbError"
              />
              <router-link :to="`/models/${model.id}`" class="object-model-link">{{ model.name || model.filename || 'Unnamed' }}</router-link>
            </li>
          </ul>
        </template>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import Button from 'primevue/button'
import NewsTextWithLinks from '@/components/NewsTextWithLinks.vue'
import { useAuthStore } from '@/stores/auth'
import { useAppToast } from '@/composables/useAppToast'

const HOME_NEWS_LIMIT = 5
const auth = useAuthStore()
const { toastInfo, toastWarn } = useAppToast()
let authHintToasted = false

interface NewsItem {
  id: number
  timestamp: string
  authorId: number
  authorName: string | null
  text: string
}

const stats = ref({ models: 0, objects: 0, authors: 0, pendingRequests: 0 })
const statsLoading = ref(true)

interface StatsHistoryPoint {
  date: string
  models: number
  objects: number
  authors: number
}

const statsSeries = ref<StatsHistoryPoint[]>([])

/**
 * Wide viewBox so `preserveAspectRatio="meet"` tends to scale from width (not height) on
 * typical wide cards; a narrow viewBox made height the limit and letterboxed the sides.
 */
const CHART_W = 1200
const CHART_PAD_L = 64
const CHART_PAD_R = 12
const ROW_TITLE_H = 14
const ROW_PLOT_H = 74
/** Space between plot bottom and x baseline (last panel only). */
const X_AXIS_LABEL_TOP = 5
const X_AXIS_LABEL_LINE = 12
/** Padding below plot area on panels without an x-axis. */
const PANEL_PLOT_BOTTOM_PAD = 8
/** Space below x-axis date labels (last panel). */
const X_AXIS_BOTTOM_PAD = 12

type MetricKey = 'models' | 'objects' | 'authors'

const METRIC_ROWS: { key: MetricKey; title: string }[] = [
  { key: 'models', title: 'Models' },
  { key: 'objects', title: 'Objects' },
  { key: 'authors', title: 'Authors' },
]

function extentSeries(values: number[]): { min: number; max: number } {
  let min = Math.min(...values)
  let max = Math.max(...values)
  if (!Number.isFinite(min) || !Number.isFinite(max)) {
    return { min: 0, max: 1 }
  }
  if (min === max) {
    const pad = Math.max(Math.abs(min) * 0.02, 1)
    min -= pad
    max += pad
  }
  return { min, max }
}

function uniqueSortedAxisTicks(vMin: number, vMax: number): number[] {
  const mid = (vMin + vMax) / 2
  const raw = [vMin, mid, vMax]
  const rounded = raw.map((v) => Number(v.toPrecision(6)))
  const out = [...new Set(rounded)].sort((a, b) => a - b)
  return out.length >= 2 ? out : [vMin, vMax]
}

function formatStatCount(n: number) {
  return Number.isFinite(n) ? n.toLocaleString() : '0'
}

function roundToNearestTen(n: number): number {
  return Math.round(n / 10) * 10
}

/** 3 significant figures (after rounding to 10 for display labels). */
function roundToThreeSignificantFigures(n: number): number {
  if (n === 0 || !Number.isFinite(n)) return 0
  const sign = n < 0 ? -1 : 1
  const x = Math.abs(n)
  const p = 10 ** (3 - 1 - Math.floor(Math.log10(x)))
  return sign * Math.round(x * p) / p
}

function formatYAxisTickLabel(v: number): string {
  const r10 = roundToNearestTen(v)
  const s3 = roundToThreeSignificantFigures(r10)
  return s3.toLocaleString(undefined, { maximumFractionDigits: 0 })
}

function formatChartAxisDate(isoDate: string) {
  if (!isoDate) return '—'
  try {
    return new Date(`${isoDate}T12:00:00`).toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    })
  } catch {
    return isoDate
  }
}

type XAxisAnchor = 'start' | 'middle' | 'end'

interface StatsChartPanel {
  key: MetricKey
  title: string
  titleY: number
  w: number
  h: number
  padL: number
  padR: number
  gridLines: { y: number }[]
  yLabels: { y: number; label: string }[]
  points: string
  xBaselineY?: number
  xAxisLabels?: Array<{ x: number; y: number; label: string; anchor: XAxisAnchor; muted: boolean }>
}

const statsChart = computed(() => {
  const series = statsSeries.value
  if (!series.length) return null

  const times = series.map((p) => new Date(`${p.date}T12:00:00`).getTime())
  const tMin = Math.min(...times)
  const tMax = Math.max(...times)
  const innerW = CHART_W - CHART_PAD_L - CHART_PAD_R

  function xAt(t: number): number {
    if (times.length === 1 || tMin === tMax) return CHART_PAD_L + innerW / 2
    return CHART_PAD_L + ((t - tMin) / (tMax - tMin)) * innerW
  }

  const panels: StatsChartPanel[] = []

  METRIC_ROWS.forEach(({ key, title }, mi) => {
    const isLast = mi === METRIC_ROWS.length - 1
    const vals = series.map((p) => p[key])
    const { min: vMin, max: vMax } = extentSeries(vals)

    const titleY = 11
    const plotTop = ROW_TITLE_H
    const plotH = ROW_PLOT_H

    function yAt(v: number): number {
      const span = vMax - vMin || 1
      return plotTop + plotH - ((v - vMin) / span) * plotH
    }

    const ticks = uniqueSortedAxisTicks(vMin, vMax)

    function linePointsForMetric(): string {
      if (times.length === 1) {
        const x = xAt(times[0])
        const y = yAt(series[0][key])
        return `${(x - 6).toFixed(2)},${y.toFixed(2)} ${(x + 6).toFixed(2)},${y.toFixed(2)}`
      }
      return series
        .map((p, i) => `${xAt(times[i]).toFixed(2)},${yAt(p[key]).toFixed(2)}`)
        .join(' ')
    }

    const panelH = isLast
      ? ROW_TITLE_H + ROW_PLOT_H + X_AXIS_LABEL_TOP + X_AXIS_LABEL_LINE + X_AXIS_BOTTOM_PAD
      : ROW_TITLE_H + ROW_PLOT_H + PANEL_PLOT_BOTTOM_PAD

    const panel: StatsChartPanel = {
      key,
      title,
      titleY,
      w: CHART_W,
      h: panelH,
      padL: CHART_PAD_L,
      padR: CHART_PAD_R,
      gridLines: ticks.map((tv) => ({ y: yAt(tv) })),
      yLabels: ticks.map((tv) => ({
        y: yAt(tv) + 4,
        label: formatYAxisTickLabel(tv),
      })),
      points: linePointsForMetric(),
    }

    if (isLast) {
      const xBaselineY = plotTop + plotH + X_AXIS_LABEL_TOP
      const xLabelY = xBaselineY + X_AXIS_LABEL_LINE
      const xAxisLabels: NonNullable<StatsChartPanel['xAxisLabels']> = []
      if (series.length === 1) {
        xAxisLabels.push({
          x: xAt(times[0]),
          y: xLabelY,
          label: formatChartAxisDate(series[0].date),
          anchor: 'middle',
          muted: false,
        })
      } else {
        xAxisLabels.push({
          x: xAt(times[0]),
          y: xLabelY,
          label: formatChartAxisDate(series[0].date),
          anchor: 'start',
          muted: false,
        })
        const midIdx = Math.floor(series.length / 2)
        if (series.length > 2 && midIdx > 0 && midIdx < series.length - 1) {
          xAxisLabels.push({
            x: xAt(times[midIdx]),
            y: xLabelY,
            label: formatChartAxisDate(series[midIdx].date),
            anchor: 'middle',
            muted: true,
          })
        }
        const lastIdx = series.length - 1
        xAxisLabels.push({
          x: xAt(times[lastIdx]),
          y: xLabelY,
          label: formatChartAxisDate(series[lastIdx].date),
          anchor: 'end',
          muted: false,
        })
      }
      panel.xBaselineY = xBaselineY
      panel.xAxisLabels = xAxisLabels
    }

    panels.push(panel)
  })

  return {
    panels,
    w: CHART_W,
    padL: CHART_PAD_L,
    padR: CHART_PAD_R,
  }
})

const statsChartAriaLabel = computed(() => {
  const s = statsSeries.value
  if (!s.length) return 'Statistics history chart.'
  const a = s[0].date
  const b = s[s.length - 1].date
  return `Time series of models, objects, and authors from ${a} through ${b}, ${s.length} snapshots; three stacked charts, each with its own y-axis.`
})

const recentObjects = ref([])
const recentObjectsLoading = ref(true)
const recentObjectsError = ref<string | null>(null)
const recentModels = ref([])
const recentModelsLoading = ref(true)
const recentModelsError = ref<string | null>(null)
const news = ref<NewsItem[]>([])
const newsLoading = ref(true)
const newsError = ref<string | null>(null)

function formatNewsDate(iso: string) {
  if (!iso) return '—'
  try {
    const d = new Date(iso)
    return d.toLocaleDateString(undefined, { dateStyle: 'short' })
  } catch {
    return iso
  }
}

function thumbnailUrl(modelId: number) {
  return auth.apiUrl(`/api/models/${modelId}/thumbnail`)
}

function onThumbError(e: Event) {
  const t = e.target as HTMLImageElement
  if (t) t.style.display = 'none'
}

watch(
  () => [auth.loaded, auth.isAuthenticated] as const,
  ([loaded, isAuthed]) => {
    if (!loaded || isAuthed || authHintToasted) return
    authHintToasted = true
    toastInfo(
      'You need to be signed in to place a model request. This may change once the system is stable.',
      'Signing in'
    )
  },
  { immediate: true }
)

watch(newsError, (msg) => {
  if (msg) toastWarn(msg, 'News')
})

watch(recentObjectsError, (msg) => {
  if (msg) toastWarn(msg, 'Recent objects')
})

watch(recentModelsError, (msg) => {
  if (msg) toastWarn(msg, 'Recent models')
})

onMounted(async () => {
  try {
    const [resLatest, resHist] = await Promise.all([
      fetch(auth.apiUrl('/api/statistics')),
      fetch(auth.apiUrl('/api/statistics/history')),
    ])
    if (resLatest.ok) {
      const data = await resLatest.json()
      stats.value = {
        models: data.models ?? 0,
        objects: data.objects ?? 0,
        authors: data.authors ?? 0,
        pendingRequests: data.pendingRequests ?? 0,
      }
    }
    if (resHist.ok) {
      const hist = await resHist.json()
      const raw = (hist.series ?? []) as StatsHistoryPoint[]
      statsSeries.value = raw.filter(
        (p) =>
          p &&
          typeof p.date === 'string' &&
          typeof p.models === 'number' &&
          typeof p.objects === 'number' &&
          typeof p.authors === 'number'
      )
    }
  } catch (_) { /* ignore */ }
  finally {
    statsLoading.value = false
  }

  try {
    const res = await fetch(auth.apiUrl('/api/objects?limit=10&offset=0'))
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    recentObjects.value = data.objects || []
  } catch (err) {
    recentObjectsError.value = (err as Error).message || 'Failed to load objects'
  } finally {
    recentObjectsLoading.value = false
  }

  try {
    const res = await fetch(auth.apiUrl('/api/models/recent'))
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    recentModels.value = data.models || []
  } catch (err) {
    recentModelsError.value = (err as Error).message || 'Failed to load models'
  } finally {
    recentModelsLoading.value = false
  }

  try {
    const res = await fetch(auth.apiUrl(`/api/news?limit=${HOME_NEWS_LIMIT}&offset=0`))
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    const raw = (data.news ?? []) as NewsItem[]
    news.value = raw.filter((n, i, a) => a.findIndex((x) => x.id === n.id) === i)
  } catch (err) {
    newsError.value = (err as Error).message || 'Failed to load news'
  } finally {
    newsLoading.value = false
  }
})
</script>

<style scoped>
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
@media (max-width: 768px) { .grid { grid-template-columns: 1fr; } }
.object-thumb { width: 80px; height: 60px; object-fit: cover; border-radius: 4px; flex-shrink: 0; }
.list-none { list-style: none; }
.p-0 { padding: 0; }
.m-0 { margin: 0; }
.mb-4 { margin-bottom: 1rem; }
.mt-0 { margin-top: 0; }
.gap-4 { gap: 1rem; }
.gap-2 { gap: 0.5rem; }
.py-2 { padding-top: 0.5rem; padding-bottom: 0.5rem; }
.flex { display: flex; }
.align-items-center { align-items: center; }
.border-bottom-1 { border-bottom: 1px solid var(--p-content-border-color, #e2e8f0); }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
.object-model-link { color: var(--p-primary-color); text-decoration: none; }
.object-model-link:hover { text-decoration: underline; }
.news-list { display: flex; flex-direction: column; gap: 0.25rem; }
.news-item { display: flex; flex-direction: column; gap: 0.15rem; }
.news-date { font-size: 0.8rem; }
.news-text { font-size: 0.9rem; color: var(--p-text-color); }
.news-more-link { text-decoration: none; color: var(--p-primary-color); }
.mt-2 { margin-top: 0.5rem; }
.mb-3 { margin-bottom: 0.75rem; }

.stats-chart-empty {
  padding-top: 0.5rem;
  border-top: 1px solid var(--p-content-border-color, #e2e8f0);
  font-size: 0.9rem;
}

.stats-chart-block {
  padding-top: 0.5rem;
  border-top: 1px solid var(--p-content-border-color, #e2e8f0);
}

.stats-chart-hint {
  font-size: 0.8rem;
  margin-bottom: 0.5rem;
}

.stats-chart-stack {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.stats-chart-panel {
  width: 100%;
}

.stats-chart-svg,
.stats-chart-panel-svg {
  display: block;
  width: 100%;
  height: auto;
}

.stats-chart-row-title {
  font-size: 11px;
  font-weight: 600;
  fill: var(--p-text-muted-color, #64748b);
}

.stats-chart-row-title--models {
  fill: var(--p-primary-color, #3b82f6);
}

.stats-chart-row-title--objects {
  fill: var(--p-text-color, #334155);
}

.stats-chart-row-title--authors {
  fill: var(--p-text-muted-color, #64748b);
}

.stats-chart-x-baseline {
  stroke: var(--p-content-border-color, #e2e8f0);
  stroke-width: 1;
}

.stats-chart-x-label {
  font-size: 11px;
  fill: var(--p-text-color, #334155);
}

.stats-chart-x-label--muted {
  fill: var(--p-text-muted-color, #64748b);
}

.stats-chart-grid {
  stroke: var(--p-content-border-color, #e2e8f0);
  stroke-width: 1;
  stroke-dasharray: 4 3;
}

.stats-chart-y-label {
  font-size: 10px;
  font-variant-numeric: tabular-nums;
}

.stats-chart-y-label--models {
  fill: var(--p-primary-color, #3b82f6);
}

.stats-chart-y-label--objects {
  fill: var(--p-text-color, #334155);
}

.stats-chart-y-label--authors {
  fill: var(--p-text-muted-color, #64748b);
}

.stats-chart-line {
  stroke-width: 2.25;
  stroke-linejoin: round;
  stroke-linecap: round;
  vector-effect: non-scaling-stroke;
}

.stats-chart-line--models {
  stroke: var(--p-primary-color, #3b82f6);
}

.stats-chart-line--objects {
  stroke: var(--p-text-color, #334155);
}

.stats-chart-line--authors {
  stroke: var(--p-text-muted-color, #64748b);
}

.stats-chart-legend {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  margin-top: 0.75rem;
  font-size: 0.8rem;
  color: var(--p-text-muted-color, #64748b);
}

.stats-chart-legend-item {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

.stats-chart-swatch {
  display: inline-block;
  width: 14px;
  height: 3px;
  border-radius: 2px;
  flex-shrink: 0;
}

.stats-chart-swatch--models {
  background: var(--p-primary-color, #3b82f6);
}

.stats-chart-swatch--objects {
  background: var(--p-text-color, #334155);
}

.stats-chart-swatch--authors {
  background: var(--p-text-muted-color, #64748b);
}
</style>
