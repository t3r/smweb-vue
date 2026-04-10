<template>
  <div>
    <h1 class="mt-0">Authors</h1>
    <p class="text-color-secondary mb-4">Browse authors. Click a name to view details and their models.</p>

    <DataTable
      v-model:filters="filters"
      :value="authors"
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
      <Column field="id" header="ID" style="width: 5rem" sortable>
        <template #body="{ data }">
          <router-link :to="`/authors/${data.id}`">#{{ data.id }}</router-link>
        </template>
      </Column>
      <Column field="name" header="Name" sortable filter-field="name" :show-filter-menu="false">
        <template #filter="{ filterModel, filterCallback }">
          <InputText
            v-model="filterModel.value"
            type="text"
            placeholder="Search name"
            class="w-full"
            @keydown.enter.prevent="applyAuthorsTextFilter(filterCallback)"
            @blur="applyAuthorsTextFilter(filterCallback)"
          />
        </template>
        <template #body="{ data }">
          <span class="author-name-cell inline-flex align-items-center flex-wrap gap-1">
            <router-link :to="`/authors/${data.id}`">{{ data.name || 'Unnamed' }}</router-link>
            <AuthorIdentityProviderBadge :linked="Boolean(data.linkedIdentityProvider)" />
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
            @keydown.enter.prevent="applyAuthorsTextFilter(filterCallback)"
            @blur="applyAuthorsTextFilter(filterCallback)"
          />
        </template>
        <template #body="{ data }">{{ truncate(data.description) }}</template>
      </Column>
      <template #empty>
        <p class="m-0 p-3 text-center text-color-secondary">No authors found.</p>
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
import { ref, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import ErrorDialog from '@/components/ErrorDialog.vue'
import AuthorIdentityProviderBadge from '@/components/AuthorIdentityProviderBadge.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'

const route = useRoute()
const router = useRouter()

const authors = ref([])
const total = ref(0)
const offset = ref(0)
const limit = 20
const sortField = ref('name')
const sortOrder = ref(1)
const filters = ref({
  name: { value: null as string | null, matchMode: 'contains' },
  description: { value: null as string | null, matchMode: 'contains' },
})
const loading = ref(true)
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()

function truncate(str: unknown) {
  if (!str || typeof str !== 'string') return '—'
  const s = str.trim()
  if (s.length <= 60) return s || '—'
  return `${s.slice(0, 60)}…`
}

function syncFiltersFromRoute() {
  const q = route.query
  filters.value.name.value = q.name ? String(q.name) : null
  filters.value.description.value = q.description ? String(q.description) : null
}

function syncRouteFromFilters() {
  const query: Record<string, string> = {}
  const n = filters.value.name?.value
  if (n && String(n).trim()) query.name = String(n).trim()
  const d = filters.value.description?.value
  if (d && String(d).trim()) query.description = String(d).trim()
  router.replace({ path: '/authors', query }).catch(() => {})
}

/** Same pattern as Objects list: contains search, apply on Enter/blur via DataTable filter callback + URL sync. */
function applyAuthorsTextFilter(filterCallback?: () => void) {
  filterCallback?.()
  offset.value = 0
  syncRouteFromFilters()
}

watch(
  () => ({ ...route.query }),
  () => {
    syncFiltersFromRoute()
    offset.value = 0
    fetchAuthors()
  },
  { deep: true }
)

async function fetchAuthors() {
  loading.value = true
  clearError()
  try {
    const params = new URLSearchParams({ offset: String(offset.value), limit: String(limit) })
    const nameVal = filters.value.name?.value
    const descVal = filters.value.description?.value
    if (nameVal && String(nameVal).trim()) params.set('name', String(nameVal).trim())
    if (descVal && String(descVal).trim()) params.set('description', String(descVal).trim())
    if (sortField.value) params.set('sortField', sortField.value)
    if (sortOrder.value !== null && sortOrder.value !== undefined) params.set('sortOrder', String(sortOrder.value))
    const res = await fetch(`/api/authors?${params}`)
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    authors.value = data.authors || []
    total.value = data.total ?? 0
  } catch (err) {
    showError((err as Error).message || 'Failed to load authors')
    authors.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

function onPage(event: { first: number }) {
  offset.value = event.first
  fetchAuthors()
}

function onSort(event: { sortField?: string; sortOrder?: number }) {
  sortField.value = event.sortField ?? 'name'
  sortOrder.value = event.sortOrder ?? 1
  offset.value = 0
  fetchAuthors()
}

onMounted(() => {
  syncFiltersFromRoute()
  fetchAuthors()
})
</script>

<style scoped>
.flex { display: flex; }
.align-items-center { align-items: center; }
.justify-content-center { justify-content: center; }
.mb-3 { margin-bottom: 0.75rem; }
.mb-4 { margin-bottom: 1rem; }
.mt-0 { margin-top: 0; }
.m-0 { margin: 0; }
.p-3 { padding: 0.75rem; }
.p-4 { padding: 1rem; }
.text-center { text-align: center; }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
.inline-flex { display: inline-flex; }
.align-items-center { align-items: center; }
.flex-wrap { flex-wrap: wrap; }
.gap-1 { gap: 0.25rem; }
</style>
