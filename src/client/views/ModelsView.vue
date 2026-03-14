<template>
  <div>
    <h1 class="mt-0">Models</h1>
    <div class="flex flex-wrap align-items-center gap-3 mb-4">
      <router-link to="/models/add" class="add-model-link">Add model</router-link>
    </div>

    <Message v-if="error" severity="error" class="mb-3">{{ error }}</Message>

    <DataTable
      v-model:filters="filters"
      :value="models"
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
          <router-link :to="`/models/${data.id}`">
            <img
              :src="thumbnailUrl(data.id)"
              :alt="data.name || data.filename || 'Model'"
              class="thumb-cell"
              @error="onThumbError"
            />
          </router-link>
        </template>
      </Column>
      <Column field="id" header="ID" style="width: 5rem" sortable>
        <template #body="{ data }">
          <span class="id-cell">
            <router-link :to="`/models/${data.id}`">#{{ data.id }}</router-link>
            <i v-if="modelIdsWithPending.has(data.id)" class="pi pi-inbox pending-icon" title="Pending request" />
          </span>
        </template>
      </Column>
      <Column field="name" header="Name" sortable filter-field="name" :show-filter-menu="false">
        <template #filter="{ filterModel, filterCallback }">
          <InputText
            v-model="filterModel.value"
            type="text"
            placeholder="Search name"
            class="w-full"
            @keydown.enter.prevent="applyNameAuthorFilters(filterCallback)"
            @blur="applyNameAuthorFilters(filterCallback)"
          />
        </template>
        <template #body="{ data }">
          <router-link :to="`/models/${data.id}`">{{ data.name || data.filename || 'Unnamed' }}</router-link>
        </template>
      </Column>
      <Column field="group" header="Type" sortable filter-field="group" :show-filter-menu="false">
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
        <template #body="{ data }">{{ data.group ?? '—' }}</template>
      </Column>
      <Column field="author" header="Author" sortable filter-field="author" :show-filter-menu="false">
        <template #filter="{ filterModel, filterCallback }">
          <InputText
            v-model="filterModel.value"
            type="text"
            placeholder="Search author"
            class="w-full"
            @keydown.enter.prevent="applyNameAuthorFilters(filterCallback)"
            @blur="applyNameAuthorFilters(filterCallback)"
          />
        </template>
        <template #body="{ data }">
          <template v-if="data.author">
            <router-link :to="`/authors/${data.author.id}`">{{ data.author.name }}</router-link>
          </template>
          <span v-else>—</span>
        </template>
      </Column>
      <Column field="lastUpdated" header="Updated" sortable>
        <template #body="{ data }">{{ formatDate(data.lastUpdated) }}</template>
      </Column>
      <template #empty>
        <p class="m-0 p-3 text-center text-color-secondary">No models found.</p>
      </template>
      <template #loading>
        <div class="flex align-items-center justify-content-center p-4">
          <i class="pi pi-spin pi-spinner" style="font-size: 2rem"></i>
        </div>
      </template>
    </DataTable>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

const modelGroups = ref<{ id: number; name?: string; path?: string }[]>([])
const models = ref([])
const total = ref(0)

const modelIdsWithPending = computed(() =>
  new Set((models.value || []).filter((m: { hasPendingRequest?: boolean }) => m.hasPendingRequest === true).map((m: { id: number }) => m.id))
)
const offset = ref(0)
const limit = 20
const sortField = ref('lastUpdated')
const sortOrder = ref(-1)
const filters = ref({
  name: { value: null as string | null, matchMode: 'contains' },
  group: { value: null as string | null, matchMode: 'equals' },
  author: { value: null as string | null, matchMode: 'contains' },
})
const loading = ref(true)
const error = ref<string | null>(null)

const typeFilterOptions = computed(() => {
  const all = { label: 'All types', value: null as string | null }
  const opts = (modelGroups.value || []).map((g) => ({
    label: g.name || g.path || `Group ${g.id}`,
    value: String(g.id),
  }))
  return [all, ...opts]
})

function syncFiltersFromRoute() {
  const q = route.query
  filters.value.name.value = q.search ? String(q.search) : null
  filters.value.group.value = q.group ? String(q.group) : null
  filters.value.author.value = q.authorSearch ? String(q.authorSearch) : null
}

function syncRouteFromFilters() {
  const query: Record<string, string> = {}
  const nameVal = filters.value.name?.value
  if (nameVal && String(nameVal).trim()) query.search = String(nameVal).trim()
  const g = filters.value.group?.value
  if (g != null && g !== '') query.group = String(g)
  const av = filters.value.author?.value
  if (av && String(av).trim()) query.authorSearch = String(av).trim()
  router.replace({ path: '/models', query }).catch(() => {})
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
    fetchModels()
  },
  { deep: true }
)

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

/** Notify DataTable filter row, then sync URL and reload (route watch runs fetch). */
function applyNameAuthorFilters(filterCallback?: () => void) {
  filterCallback?.()
  offset.value = 0
  syncRouteFromFilters()
}

/** Apply type (group) filter as soon as the dropdown selection changes. */
function applyTypeFilter(filterCallback?: () => void) {
  filterCallback?.()
  offset.value = 0
  nextTick(() => {
    syncRouteFromFilters()
  })
}

async function fetchModels() {
  loading.value = true
  error.value = null
  try {
    const params = new URLSearchParams({ offset: String(offset.value), limit: String(limit) })
    const nameVal = filters.value.name?.value
    if (nameVal && String(nameVal).trim()) params.set('search', String(nameVal).trim())
    const groupVal = filters.value.group?.value
    if (groupVal != null && String(groupVal) !== '') params.set('group', String(groupVal))
    const authorVal = filters.value.author?.value
    if (authorVal && String(authorVal).trim()) params.set('authorSearch', String(authorVal).trim())
    if (sortField.value) params.set('sortField', sortField.value)
    if (sortOrder.value !== null && sortOrder.value !== undefined) params.set('sortOrder', String(sortOrder.value))
    const res = await fetch(`/api/models?${params}`)
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    models.value = data.models || []
    total.value = data.total ?? 0
  } catch (err) {
    error.value = (err as Error).message || 'Failed to load models'
    models.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

function onPage(event: { first: number }) {
  offset.value = event.first
  fetchModels()
}

function onSort(event: { sortField?: string; sortOrder?: number }) {
  sortField.value = event.sortField ?? 'lastUpdated'
  sortOrder.value = event.sortOrder ?? -1
  offset.value = 0
  fetchModels()
}

onMounted(async () => {
  await fetchModelGroups()
  syncFiltersFromRoute()
  await fetchModels()
})
</script>

<style scoped>
.flex { display: flex; }
.flex-wrap { flex-wrap: wrap; }
.align-items-center { align-items: center; }
.justify-content-center { justify-content: center; }
.gap-3 { gap: 0.75rem; }
.mb-3 { margin-bottom: 0.75rem; }
.mb-4 { margin-bottom: 1rem; }
.mt-0 { margin-top: 0; }
.m-0 { margin: 0; }
.p-3 { padding: 0.75rem; }
.p-4 { padding: 1rem; }
.text-center { text-align: center; }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
.add-model-link { margin-right: 0.5rem; font-weight: 500; }
.thumb-cell { width: 40px; height: 40px; object-fit: cover; border-radius: 4px; display: block; }
.id-cell { display: inline-flex; align-items: center; gap: 0.35rem; }
.pending-icon { font-size: 0.875rem; color: var(--p-primary-color); }
</style>
