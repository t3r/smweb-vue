<template>
  <div>
    <h1 class="mt-0">Objects</h1>
    <div class="flex flex-wrap align-items-center gap-3 mb-2">
      <router-link to="/objects/import" class="objects-import-link">Mass import</router-link>
    </div>
    <p class="text-color-secondary mb-4">Browse object positions. Use the row filters for description, type, and country.</p>

    <DataTable
      v-model:filters="filters"
      :value="objects"
      :loading="loading"
      :lazy="true"
      :paginator="true"
      :rows="limit"
      :totalRecords="total"
      :first="offset"
      :sort-field="sortField"
      :sort-order="sortOrder"
      filter-display="row"
      data-key="id"
      paginator-template="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport"
      current-page-report-template="Showing {first} to {last} of {totalRecords} entries"
      responsive-layout="scroll"
      @page="onPage"
      @sort="onSort"
    >
      <Column header="" style="width: 4rem">
        <template #body="{ data }">
          <router-link :to="`/objects/${data.id}`">
            <img
              :src="thumbnailUrl(data.modelId)"
              :alt="data.description || 'Object'"
              class="thumb-cell"
              @error="onThumbError"
            />
          </router-link>
        </template>
      </Column>
      <Column field="id" header="ID" style="width: 5rem" sortable>
        <template #body="{ data }">
          <span class="id-cell">
            <router-link :to="`/objects/${data.id}`">#{{ data.id }}</router-link>
            <i v-if="objectIdsWithPending.has(data.id)" class="pi pi-inbox pending-icon" title="Pending request" />
          </span>
        </template>
      </Column>
      <Column field="description" header="Description" sortable filter-field="description" :show-filter-menu="false">
        <template #filter="{ filterModel, filterCallback }">
          <InputText
            v-model="filterModel.value"
            type="text"
            placeholder="Search description"
            class="w-full"
            @keydown.enter.prevent="applyDescriptionFilter(filterCallback)"
            @blur="applyDescriptionFilter(filterCallback)"
          />
        </template>
        <template #body="{ data }">
          <router-link :to="`/objects/${data.id}`">{{ data.description || 'Unnamed' }}</router-link>
        </template>
      </Column>
      <Column field="type" header="Type" sortable filter-field="type" :show-filter-menu="false">
        <template #filter="{ filterModel, filterCallback }">
          <Select
            v-model="filterModel.value"
            :options="typeFilterOptions"
            option-label="label"
            option-value="value"
            placeholder="All types"
            class="w-full"
            show-clear
            @change="() => applyTypeFilter(filterCallback)"
          />
        </template>
        <template #body="{ data }">{{ data.type || '—' }}</template>
      </Column>
      <Column field="country" header="Country" sortable filter-field="country" :show-filter-menu="false">
        <template #filter="{ filterModel, filterCallback }">
          <Select
            v-model="filterModel.value"
            :options="countryFilterOptions"
            option-label="label"
            option-value="value"
            placeholder="All countries"
            class="w-full"
            show-clear
            filter
            @change="() => applyCountryFilter(filterCallback)"
          />
        </template>
        <template #body="{ data }">{{ countryNameFor(data.country) }}</template>
      </Column>
      <Column field="lat" header="Lat" sortable>
        <template #body="{ data }">{{ formatNum(data.position?.lat) }}</template>
      </Column>
      <Column field="lon" header="Lon" sortable>
        <template #body="{ data }">{{ formatNum(data.position?.lon) }}</template>
      </Column>
      <Column header="Elev offset">
        <template #body="{ data }">{{ formatOffset(data.position?.offset) }}</template>
      </Column>
      <Column header="Heading">
        <template #body="{ data }">{{ formatHeading(data.position?.heading) }}</template>
      </Column>
      <Column field="lastUpdated" header="Updated" sortable>
        <template #body="{ data }">{{ formatDate(data.lastUpdated) }}</template>
      </Column>
      <template #empty>
        <p class="m-0 p-3 text-center text-color-secondary">No objects found.</p>
      </template>
      <template #loading>
        <div class="flex align-items-center justify-content-center p-4">
          <i class="pi pi-spin pi-spinner" style="font-size: 2rem"></i>
        </div>
      </template>
    </DataTable>

    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'

const route = useRoute()
const router = useRouter()

const modelGroups = ref<{ id: number; name?: string; path?: string }[]>([])
const countries = ref<{ code?: string; name?: string }[]>([])
/** When URL has ?country=X and that code isn't in the countries list, show it in the dropdown */
const countryFromUrl = ref<string | null>(null)
const objects = ref([])
const total = ref(0)

const objectIdsWithPending = computed(() =>
  new Set((objects.value || []).filter((o: { hasPendingRequest?: boolean }) => o.hasPendingRequest === true).map((o: { id: number }) => o.id))
)
const offset = ref(0)
const limit = 20
const sortField = ref('lastUpdated')
const sortOrder = ref(-1)
const filters = ref({
  description: { value: null as string | null, matchMode: 'contains' },
  type: { value: null as string | null, matchMode: 'equals' },
  country: { value: null as string | null, matchMode: 'equals' },
})
const loading = ref(true)
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()

const typeFilterOptions = computed(() => {
  const all = { label: 'All types', value: null as string | null }
  const opts = (modelGroups.value || []).map((g) => ({
    label: g.name || g.path || `Group ${g.id}`,
    value: String(g.id),
  }))
  return [all, ...opts]
})

const countryFilterOptions = computed(() => {
  const all = { label: 'All countries', value: null as string | null }
  const opts = (countries.value || []).map((c) => {
    const code = (c.code || '').trim().toLowerCase()
    return {
      label: c.name && c.name.trim() ? c.name.trim() : code || c.code || '',
      value: code || (c.code || '').trim().toLowerCase(),
    }
  })
  const fromUrl = countryFromUrl.value
  if (fromUrl && !opts.some((o) => String(o.value).toLowerCase() === String(fromUrl).toLowerCase())) {
    opts.unshift({ label: fromUrl, value: fromUrl.toLowerCase() })
  }
  return [all, ...opts]
})

function syncFiltersFromRoute() {
  const q = route.query
  filters.value.description.value = q.description ? String(q.description) : null
  filters.value.type.value = q.group ? String(q.group) : null
  filters.value.country.value = q.country ? String(q.country).trim().toLowerCase() || null : null
}

function syncRouteFromFilters() {
  const query: Record<string, string> = {}
  const desc = filters.value.description?.value
  if (desc && String(desc).trim()) query.description = String(desc).trim()
  const g = filters.value.type?.value
  if (g != null && g !== '') query.group = String(g)
  const c = filters.value.country?.value
  if (c && String(c).trim()) query.country = String(c).trim().toLowerCase()
  router.replace({ path: '/objects', query }).catch(() => {})
}

function ensureCountryInOptions(code: unknown) {
  if (!code) {
    countryFromUrl.value = null
    return
  }
  const normalized = String(code).trim().toLowerCase()
  const inList = (countries.value || []).some(
    (c) => String(c.code || '').trim().toLowerCase() === normalized
  )
  if (inList) {
    countryFromUrl.value = null
    return
  }
  countryFromUrl.value = normalized
}

function countryNameFor(code: unknown) {
  if (!code) return '—'
  const lower = String(code).trim().toLowerCase()
  const c = countries.value.find((x) => String(x.code || '').trim().toLowerCase() === lower)
  if (c) return c.name && c.name.trim() ? c.name.trim() : c.code || '—'
  return String(code).trim() || '—'
}

function formatNum(n: unknown) {
  if (n == null || Number.isNaN(Number(n))) return '—'
  return Number(n).toFixed(5)
}

function formatOffset(n: unknown) {
  if (n == null || Number.isNaN(Number(n))) return '—'
  const v = Number(n)
  return v === 0 ? '0' : `${v} m`
}

function formatHeading(n: unknown) {
  if (n == null || Number.isNaN(Number(n))) return '—'
  return `${Number(n)}°`
}

function thumbnailUrl(modelId: number) {
  return `/api/models/${modelId}/thumbnail`
}

function onThumbError(e: Event) {
  const t = e.target as HTMLImageElement
  if (t) t.style.display = 'none'
}

function formatDate(iso: unknown) {
  if (!iso) return ''
  try {
    const d = new Date(String(iso))
    return d.toLocaleDateString(undefined, { dateStyle: 'short' })
  } catch {
    return String(iso)
  }
}

watch(
  () => ({ ...route.query }),
  () => {
    syncFiltersFromRoute()
    offset.value = 0
    ensureCountryInOptions(route.query.country)
    fetchObjects()
  },
  { deep: true }
)

function applyDescriptionFilter(filterCallback?: () => void) {
  filterCallback?.()
  offset.value = 0
  syncRouteFromFilters()
}

function applyTypeFilter(filterCallback?: () => void) {
  filterCallback?.()
  offset.value = 0
  nextTick(() => {
    syncRouteFromFilters()
  })
}

function applyCountryFilter(filterCallback?: () => void) {
  filterCallback?.()
  offset.value = 0
  nextTick(() => {
    syncRouteFromFilters()
  })
}

function onPage(event: { first: number }) {
  offset.value = event.first
  fetchObjects()
}

function onSort(event: { sortField?: string; sortOrder?: number }) {
  sortField.value = event.sortField ?? 'lastUpdated'
  sortOrder.value = event.sortOrder ?? -1
  offset.value = 0
  fetchObjects()
}

async function fetchModelGroups() {
  try {
    const res = await fetch('/api/modelgroups')
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    modelGroups.value = data.groups || []
  } catch (err) {
    console.error('Failed to load model groups', err)
    modelGroups.value = []
  }
}

async function fetchCountries() {
  try {
    const res = await fetch('/api/countries')
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    countries.value = data.countries || []
  } catch (err) {
    console.error('Failed to load countries', err)
    countries.value = []
  }
}

async function fetchObjects() {
  loading.value = true
  clearError()
  try {
    const params = new URLSearchParams({ offset: String(offset.value), limit: String(limit) })
    const descVal = filters.value.description?.value
    if (descVal && String(descVal).trim()) params.set('description', String(descVal).trim())
    const groupVal = filters.value.type?.value
    if (groupVal != null && String(groupVal) !== '') params.set('group', String(groupVal))
    const countryVal = filters.value.country?.value
    if (countryVal && String(countryVal).trim()) params.set('country', String(countryVal).trim().toLowerCase())
    if (sortField.value) params.set('sortField', sortField.value)
    if (sortOrder.value !== null && sortOrder.value !== undefined) params.set('sortOrder', String(sortOrder.value))
    const res = await fetch(`/api/objects?${params}`)
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    objects.value = data.objects || []
    total.value = data.total ?? 0
  } catch (err) {
    showError((err as Error).message || 'Failed to load objects')
    objects.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await Promise.all([fetchModelGroups(), fetchCountries()])
  syncFiltersFromRoute()
  ensureCountryInOptions(route.query.country)
  await fetchObjects()
})
</script>

<style scoped>
.flex { display: flex; }
.flex-wrap { flex-wrap: wrap; }
.align-items-center { align-items: center; }
.mb-2 { margin-bottom: 0.5rem; }
.justify-content-center { justify-content: center; }
.mb-3 { margin-bottom: 0.75rem; }
.mb-4 { margin-bottom: 1rem; }
.mt-0 { margin-top: 0; }
.m-0 { margin: 0; }
.p-3 { padding: 0.75rem; }
.p-4 { padding: 1rem; }
.text-center { text-align: center; }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
.thumb-cell { width: 40px; height: 40px; object-fit: cover; border-radius: 4px; display: block; }
.id-cell { display: inline-flex; align-items: center; gap: 0.35rem; }
.pending-icon { font-size: 0.875rem; color: var(--p-primary-color); }
.gap-3 { gap: 0.75rem; }
.objects-import-link { font-weight: 500; }
</style>
