<template>
  <div>
    <h1 class="mt-0">Authors</h1>
    <p class="text-color-secondary mb-4">Browse authors. Click a name to view details and their models.</p>

    <Message v-if="error" severity="error" class="mb-3">{{ error }}</Message>

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
      <Column field="id" header="ID" style="width: 5rem" sortable filter-field="id">
        <template #filter> </template>
        <template #body="{ data }">
          <router-link :to="`/authors/${data.id}`">#{{ data.id }}</router-link>
        </template>
      </Column>
      <Column field="name" header="Name" sortable filter-field="name">
        <template #filter="{ filterModel }">
          <InputText
            v-model="filterModel.value"
            type="text"
            placeholder="Search name"
            class="w-full"
            @keydown.enter.prevent="applyStringFilters"
            @blur="applyStringFilters"
          />
        </template>
        <template #body="{ data }">
          <router-link :to="`/authors/${data.id}`">{{ data.name || 'Unnamed' }}</router-link>
        </template>
      </Column>
      <Column field="description" header="Description" sortable filter-field="description">
        <template #filter="{ filterModel }">
          <InputText
            v-model="filterModel.value"
            type="text"
            placeholder="Search description"
            class="w-full"
            @keydown.enter.prevent="applyStringFilters"
            @blur="applyStringFilters"
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
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const authors = ref([])
const total = ref(0)
const offset = ref(0)
const limit = 20
const sortField = ref('name')
const sortOrder = ref(1)
const filters = ref({
  id: { value: null, matchMode: 'contains' },
  name: { value: null, matchMode: 'contains' },
  description: { value: null, matchMode: 'contains' },
})
const loading = ref(true)
const error = ref(null)

function truncate(str) {
  if (!str || typeof str !== 'string') return '—'
  const s = str.trim()
  if (s.length <= 60) return s || '—'
  return s.slice(0, 60) + '…'
}

function applyStringFilters() {
  offset.value = 0
  fetchAuthors()
}

async function fetchAuthors() {
  loading.value = true
  error.value = null
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
    error.value = (err as Error).message || 'Failed to load authors'
    authors.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

function onPage(event) {
  offset.value = event.first
  fetchAuthors()
}

function onSort(event) {
  sortField.value = event.sortField ?? 'name'
  sortOrder.value = event.sortOrder ?? 1
  offset.value = 0
  fetchAuthors()
}

onMounted(() => {
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
</style>
