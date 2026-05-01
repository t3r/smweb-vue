<template>
  <div class="model-update-details">
    <p v-if="loading" class="m-0 text-color-secondary">Loading current model…</p>
    <template v-else-if="currentModel">
      <p class="model-detail-link mb-2">
        <router-link :to="'/models/' + modelId" target="_blank" rel="noopener noreferrer">
          View model in detail <i class="pi pi-external-link" />
        </router-link>
      </p>
      <div class="comparison-grid">
        <div class="comparison-column">
          <h4 class="comparison-heading">Requested</h4>
          <dl class="comparison-fields">
            <dt>Name</dt>
            <dd :class="{ 'value-modified': fieldDiffs.name }">{{ formatVal(requested.name) }}</dd>
            <dt>Description</dt>
            <dd :class="{ 'value-modified': fieldDiffs.description }">{{ formatVal(requested.description) }}</dd>
            <dt>Filename (path)</dt>
            <dd :class="{ 'value-modified': fieldDiffs.filename }">{{ formatVal(requested.filename) }}</dd>
            <dt>Model family</dt>
            <dd :class="{ 'value-modified': fieldDiffs.group }">{{ requestedGroupLabel }}</dd>
            <dt>Author</dt>
            <dd :class="{ 'value-modified': fieldDiffs.author }">
              <router-link v-if="Number.isFinite(requested.authorId)" :to="'/authors/' + requested.authorId">
                Author #{{ requested.authorId }}
              </router-link>
              <span v-else>—</span>
            </dd>
          </dl>
        </div>
        <div class="comparison-column">
          <h4 class="comparison-heading">Current (in database)</h4>
          <dl class="comparison-fields">
            <dt>Name</dt>
            <dd :class="{ 'value-modified': fieldDiffs.name }">{{ formatVal(currentModel.name) }}</dd>
            <dt>Description</dt>
            <dd :class="{ 'value-modified': fieldDiffs.description }">{{ formatVal(currentModel.description) }}</dd>
            <dt>Filename (path)</dt>
            <dd :class="{ 'value-modified': fieldDiffs.filename }">{{ formatVal(currentModel.filename) }}</dd>
            <dt>Model family</dt>
            <dd :class="{ 'value-modified': fieldDiffs.group }">{{ currentGroupLabel }}</dd>
            <dt>Author</dt>
            <dd :class="{ 'value-modified': fieldDiffs.author }">
              <router-link v-if="currentModel.author?.id != null" :to="'/authors/' + currentModel.author.id">
                {{ currentModel.author.name || 'Author #' + currentModel.author.id }}
              </router-link>
              <span v-else>—</span>
            </dd>
          </dl>
        </div>
      </div>
      <div v-if="requestSig" class="comparison-package mt-3">
        <h4 class="comparison-heading">Requested package</h4>
        <ModelContentCard :request-sig="requestSig" :filename="requested.filename || undefined" compact />
      </div>
    </template>
    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
import ModelContentCard from '@/components/ModelContentCard.vue'

export interface ModelUpdateDetailsShape {
  modelid?: number | null
  modelId?: number | null
  name?: string | null
  description?: string | null
  filename?: string | null
  modelgroup?: number | null
  author?: number | null
}

interface FetchedModel {
  id?: number
  name?: string | null
  filename?: string | null
  description?: string | null
  groupId?: number | null
  group?: string | number | null
  author?: { id?: number; name?: string | null } | null
}

const props = defineProps<{
  details: ModelUpdateDetailsShape | Record<string, unknown>
  requestSig: string
}>()

const auth = useAuthStore()
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()
const currentModel = ref<FetchedModel | null>(null)
const loading = ref(true)
const modelGroups = ref<{ id: number; name: string | null; path: string | null }[]>([])

const requested = computed(() => {
  const d = props.details as Record<string, unknown>
  const mid = d.modelid ?? d.modelId
  const modelId = mid != null && Number.isFinite(Number(mid)) ? Number(mid) : NaN
  const mg = d.modelgroup
  const groupId = mg != null && Number.isFinite(Number(mg)) ? Number(mg) : NaN
  const authRaw = d.author
  const authorId = authRaw != null && Number.isFinite(Number(authRaw)) ? Number(authRaw) : NaN
  return {
    modelId,
    name: d.name != null ? String(d.name).trim() : '',
    description: d.description != null ? String(d.description).trim() : '',
    filename: d.filename != null ? String(d.filename).trim() : '',
    groupId,
    authorId,
  }
})

const modelId = computed(() => (Number.isFinite(requested.value.modelId) ? requested.value.modelId : NaN))

function groupLabel(id: number | null): string {
  if (id == null || !Number.isFinite(id)) return '—'
  const g = modelGroups.value.find((x) => x.id === id)
  if (!g) return `Group #${id}`
  return (g.name || g.path || `Group #${id}`).trim() || `Group #${id}`
}

const requestedGroupLabel = computed(() => groupLabel(Number.isFinite(requested.value.groupId) ? requested.value.groupId : null))

const currentGroupLabel = computed(() => {
  const cur = currentModel.value
  if (!cur) return '—'
  const gid = cur.groupId != null && Number.isFinite(Number(cur.groupId)) ? Number(cur.groupId) : null
  return groupLabel(gid)
})

function normStr(a: unknown, b: unknown): boolean {
  const sa = a != null ? String(a).trim() : ''
  const sb = b != null ? String(b).trim() : ''
  return sa !== sb
}

const fieldDiffs = computed(() => {
  const cur = currentModel.value
  const r = requested.value
  if (!cur) {
    return { name: false, description: false, filename: false, group: false, author: false }
  }
  const curGid = cur.groupId != null && Number.isFinite(Number(cur.groupId)) ? Number(cur.groupId) : null
  const reqGid = Number.isFinite(r.groupId) ? r.groupId : null
  const curAid = cur.author?.id != null && Number.isFinite(Number(cur.author.id)) ? Number(cur.author.id) : null
  const reqAid = Number.isFinite(r.authorId) ? r.authorId : null
  return {
    name: normStr(r.name, cur.name),
    description: normStr(r.description, cur.description),
    filename: normStr(r.filename, cur.filename),
    group: reqGid !== curGid,
    author: reqAid !== curAid,
  }
})

function formatVal(v: unknown) {
  if (v == null || v === '') return '—'
  const s = String(v).trim()
  return s || '—'
}

async function loadModelGroups() {
  try {
    const res = await fetch(auth.apiUrl('/api/modelgroups'), { credentials: 'include' })
    if (!res.ok) return
    const data = (await res.json()) as { groups?: { id: number; name: string | null; path: string | null }[] }
    modelGroups.value = data.groups ?? []
  } catch {
    modelGroups.value = []
  }
}

async function fetchCurrentModel() {
  const id = modelId.value
  if (!Number.isInteger(id) || id < 1) {
    loading.value = false
    showError('Invalid model id in request')
    return
  }
  loading.value = true
  currentModel.value = null
  clearError()
  try {
    const url = auth.apiUrl(`/api/models/${id}`)
    const res = await fetch(url, { credentials: 'include' })
    if (!res.ok) {
      if (res.status === 404) showError('Model not found')
      else throw new Error(res.statusText)
      return
    }
    const data = (await res.json()) as FetchedModel
    currentModel.value = data
  } catch (err) {
    showError((err as Error).message || 'Failed to load model')
  } finally {
    loading.value = false
  }
}

watch(
  () => [modelId.value, props.requestSig] as const,
  async () => {
    await loadModelGroups()
    await fetchCurrentModel()
  },
  { immediate: true }
)
</script>

<style scoped>
.model-update-details {
  margin: 0;
}
.model-detail-link {
  margin: 0;
}
.model-detail-link a {
  color: var(--p-primary-color);
  text-decoration: none;
}
.model-detail-link a:hover {
  text-decoration: underline;
}
.model-detail-link .pi {
  font-size: 0.75rem;
  margin-left: 0.25rem;
  vertical-align: middle;
}
.mb-2 {
  margin-bottom: 0.5rem;
}
.mt-3 {
  margin-top: 1rem;
}
.comparison-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  margin-bottom: 0.5rem;
}
@media (max-width: 600px) {
  .comparison-grid {
    grid-template-columns: 1fr;
  }
}
.comparison-column {
  min-width: 0;
}
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
.comparison-fields dt {
  color: var(--p-text-muted-color);
  font-weight: 500;
}
.comparison-fields dd {
  margin: 0;
}
.comparison-fields dd.value-modified {
  background: var(--p-highlight-background, rgba(59, 130, 246, 0.15));
  border-radius: 4px;
  padding: 0.2rem 0.4rem;
  margin: 0 -0.4rem;
}
.comparison-fields a {
  color: var(--p-primary-color);
  text-decoration: none;
}
.comparison-fields a:hover {
  text-decoration: underline;
}
.comparison-package {
  padding-top: 1rem;
  border-top: 1px solid var(--p-content-border-color, rgba(0, 0, 0, 0.08));
}
.m-0 {
  margin: 0;
}
.text-color-secondary {
  color: var(--p-text-muted-color);
}
</style>
