<template>
  <div>
    <h1 class="mt-0">Pending requests</h1>
    <p v-if="auth.isReviewer" class="text-color-secondary mb-4">
      Review and accept or decline queued submissions.
      <span class="keyboard-hint">Keys: <kbd>↑</kbd><kbd>↓</kbd> navigate · <kbd>Enter</kbd> expand · <kbd>A</kbd> accept · <kbd>D</kbd> decline · <kbd>Esc</kbd> collapse</span>
    </p>
    <p v-else class="text-color-secondary mb-4">
      All pending submissions are listed here. Expanding a request shows everything your account may access; model files
      and some details stay restricted unless you submitted the request or are a reviewer.
    </p>

    <div v-if="loading" class="flex align-items-center justify-content-center p-4">
      <i class="pi pi-spin pi-spinner" style="font-size: 2rem"></i>
    </div>

    <template v-else>
      <Card class="mb-4">
        <template #title>Pending</template>
        <template #content>
          <p v-if="!pending.length" class="m-0 text-color-secondary">No pending requests.</p>
          <DataTable
            v-else
            :value="pending"
            data-key="id"
            responsive-layout="scroll"
            class="p-datatable-sm"
            v-model:expandedRows="expandedRows"
            :row-class="rowClass"
          >
            <Column expander style="width: 3rem" />
            <Column field="id" header="ID" style="width: 5rem" />
            <Column field="type" header="Type" />
            <Column field="authorName" header="Author">
              <template #body="{ data }">
                <router-link v-if="data.authorId" :to="'/authors/' + data.authorId">{{ displayAuthorLabel(data) }}</router-link>
                <span v-else>{{ displayAuthorLabel(data) }}</span>
              </template>
            </Column>
            <Column field="comment" header="Comment">
              <template #body="{ data }">{{ truncate(data.comment) }}</template>
            </Column>
            <template #expansion="{ data }">
              <div class="request-details-expansion">
                <div v-if="auth.isReviewer" class="details-actions mb-2">
                  <Button
                    label="Accept"
                    icon="pi pi-check"
                    severity="success"
                    size="small"
                    :loading="acceptLoading && actionRequest?.sig === data.sig"
                    :disabled="!!(acceptLoading || declineLoading)"
                    @click="openAcceptDialog(data)"
                  />
                  <Button
                    label="Decline"
                    icon="pi pi-times"
                    severity="secondary"
                    size="small"
                    :loading="declineLoading && actionRequest?.sig === data.sig"
                    :disabled="!!(acceptLoading || declineLoading)"
                    @click="openDeclineDialog(data)"
                  />
                </div>
                <h4 class="details-heading">Request details</h4>
                <template v-if="data.type === 'MODEL_ADD' && data.details?.model">
                  <ModelDetailsCard
                    :model="modelAddDetailsModel(data.details, data.authorId, data.authorName)"
                    :author-override="data.details.author || null"
                    :request-sig="data.sig"
                    compact
                  />
                  <div v-if="data.details.object" class="details-object mt-2">
                    <strong>Location:</strong>
                    {{ formatObjectSummary(data.details.object) }}
                  </div>
                  <div class="details-model-and-map mt-2">
                    <div class="details-model-content">
                      <ModelContentCard
                        :request-sig="data.sig"
                        :filename="data.details.model?.filename"
                        compact
                      />
                      <ModelContentCard
                        v-if="modelAddHasGltf(data.details)"
                        class="mt-2"
                        :request-sig="data.sig"
                        :filename="data.details.model?.filename"
                        format="gltf"
                        compact
                      />
                    </div>
                    <div v-if="objectPositionFromDetails(data.details.object)" class="details-map-wrap">
                      <ObjectMap
                        :selection-mode="true"
                        :selection-position="objectPositionFromDetails(data.details.object)"
                        :initial-center="objectMapCenter(data.details.object)"
                        :initial-zoom="14"
                        compact
                      />
                      <span class="details-map-hint">Requested position (not yet in database)</span>
                    </div>
                  </div>
                </template>
                <template v-else-if="data.type === 'OBJECT_DELETE' && data.details?.objId != null">
                  <ObjectDetailsCardLoader
                    :obj-id="Number(data.details.objId)"
                    :countries="countries"
                  />
                </template>
                <template v-else-if="data.type === 'OBJECT_UPDATE' && data.details?.objectId != null">
                  <ObjectUpdateRequestDetails :details="data.details" />
                </template>
                <template v-else-if="data.type === 'MODEL_UPDATE'">
                  <ModelUpdateRequestDetails :details="data.details || {}" :request-sig="data.sig" />
                </template>
                <template v-else-if="data.type === 'OBJECTS_ADD'">
                  <ObjectsAddRequestDetails :details="data.details" />
                </template>
                <template v-else-if="data.type === 'MODEL_DELETE' && data.details?.modelId != null">
                  <p class="m-0">Request to delete model ID <router-link :to="'/models/' + data.details.modelId">{{ data.details.modelId }}</router-link>.</p>
                </template>
                <pre v-else class="details-json">{{ formatDetails(data.details) }}</pre>
              </div>
            </template>
          </DataTable>
        </template>
      </Card>

      <template v-if="auth.isReviewer">
        <Dialog
          v-model:visible="acceptDialogVisible"
          header="Accept request"
          modal
          :style="{ width: '28rem' }"
          :closable="true"
          @hide="actionRequest = null"
        >
          <p class="m-0">Accept this request? The change will be applied to the database.</p>
          <template #footer>
            <Button label="Cancel" severity="secondary" @click="acceptDialogVisible = false" />
            <Button label="Accept" icon="pi pi-check" severity="success" :loading="acceptLoading" @click="confirmAccept" />
          </template>
        </Dialog>

        <Dialog
          v-model:visible="declineDialogVisible"
          header="Decline request"
          modal
          :style="{ width: '28rem' }"
          :closable="true"
          @hide="onDeclineDialogHide"
        >
          <p class="mb-2">Optionally provide a reason for declining (e.g. for internal notes or to inform the submitter).</p>
          <div class="field">
            <label for="decline-reason">Reason</label>
            <InputText id="decline-reason" v-model="declineReason" type="text" placeholder="Reason for declining" class="w-full" />
          </div>
          <template #footer>
            <Button label="Cancel" severity="secondary" @click="declineDialogVisible = false" />
            <Button label="Decline" icon="pi pi-times" severity="secondary" :loading="declineLoading" @click="confirmDecline" />
          </template>
        </Dialog>
      </template>

      <Card v-if="auth.isReviewer && failed.length" >
        <template #title>Failed to decode</template>
        <template #content>
          <DataTable :value="failed" data-key="id" responsive-layout="scroll" class="p-datatable-sm">
            <Column field="id" header="ID" style="width: 5rem" />
            <Column field="sig" header="Signature" style="max-width: 12rem">
              <template #body="{ data }">
                <span class="text-truncate d-inline-block" style="max-width: 12rem" :title="data.sig">{{ data.sig }}</span>
              </template>
            </Column>
            <Column field="error" header="Error" />
          </DataTable>
        </template>
      </Card>
    </template>

    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { usePendingRequestCountStore } from '@/stores/pendingRequestCount'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
import { useAppToast } from '@/composables/useAppToast'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import ModelDetailsCard from '@/components/ModelDetailsCard.vue'
import ModelContentCard from '@/components/ModelContentCard.vue'
import ObjectMap from '@/components/ObjectMap.vue'
import ObjectDetailsCardLoader from '@/components/ObjectDetailsCardLoader.vue'
import ObjectUpdateRequestDetails from '@/components/ObjectUpdateRequestDetails.vue'
import ModelUpdateRequestDetails from '@/components/ModelUpdateRequestDetails.vue'
import ObjectsAddRequestDetails from '@/components/ObjectsAddRequestDetails.vue'
import type { ModelDetailsModel } from '@/components/ModelDetailsCard.vue'

interface PendingItem {
  id: number
  sig: string
  type: string
  email?: string
  authorId?: number | null
  authorName?: string | null
  comment?: string
  details?: unknown
}

const auth = useAuthStore()
const pendingCountStore = usePendingRequestCountStore()
const pending = ref<PendingItem[]>([])
const failed = ref([])
const expandedRows = ref<Record<number, boolean>>({})
const loading = ref(true)
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()
const { toastSuccess } = useAppToast()
const countries = ref<{ code: string; name?: string | null }[]>([])

const actionRequest = ref<{ sig: string } | null>(null)
const acceptDialogVisible = ref(false)
const declineDialogVisible = ref(false)
const acceptLoading = ref(false)
const declineLoading = ref(false)
const declineReason = ref('')

function formatDetails(details: unknown) {
  if (details == null) return '—'
  try {
    return JSON.stringify(details, null, 2)
  } catch {
    return String(details)
  }
}

function modelAddDetailsModel(
  details: { model?: Record<string, unknown>; author?: Record<string, unknown> },
  rowAuthorId?: number | null,
  rowAuthorName?: string | null,
): ModelDetailsModel {
  const m = details.model || {}
  const author = m.author
  const rowId = rowAuthorId != null && Number.isFinite(Number(rowAuthorId)) ? Number(rowAuthorId) : null
  const rowName = rowAuthorName != null ? String(rowAuthorName).trim() : ''

  let resolvedAuthor: ModelDetailsModel['author']
  if (typeof author === 'number' && rowId != null && author === rowId) {
    resolvedAuthor = { id: author, name: rowName || undefined }
  } else if (typeof author === 'number') {
    resolvedAuthor = author
  } else if (author && typeof author === 'object' && typeof (author as { id?: number }).id === 'number') {
    resolvedAuthor = {
      id: (author as { id: number }).id,
      name: (author as { name?: string }).name,
    }
  } else {
    resolvedAuthor = undefined
  }

  return {
    name: typeof m.name === 'string' ? m.name : undefined,
    filename: typeof m.filename === 'string' ? m.filename : undefined,
    description: typeof m.description === 'string' ? m.description : undefined,
    author: resolvedAuthor,
  }
}

function formatObjectSummary(obj: Record<string, unknown>) {
  const parts = []
  if (obj.longitude != null && obj.latitude != null) parts.push(`${obj.latitude}, ${obj.longitude}`)
  if (obj.country) parts.push(String(obj.country))
  if (obj.offset != null) parts.push(`offset ${obj.offset}`)
  if (obj.orientation != null) parts.push(`heading ${obj.orientation}`)
  return parts.length ? parts.join(' · ') : formatDetails(obj)
}

function objectPositionFromDetails(obj: Record<string, unknown> | null | undefined): { lat: number; lon: number } | null {
  if (obj == null) return null
  const lat = Number(obj.latitude)
  const lon = Number(obj.longitude)
  if (!Number.isFinite(lat) || !Number.isFinite(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180) return null
  return { lat, lon }
}

function objectMapCenter(obj: Record<string, unknown> | null | undefined): [number, number] {
  const pos = objectPositionFromDetails(obj)
  return pos ? [pos.lon, pos.lat] : [10, 53.5]
}

function modelAddHasGltf(details: unknown): boolean {
  if (!details || typeof details !== 'object') return false
  const model = (details as { model?: unknown }).model
  if (!model || typeof model !== 'object') return false
  return (model as { hasGltf?: unknown }).hasGltf === true
}

function truncate(str) {
  if (str == null || typeof str !== 'string') return '—'
  const s = str.trim()
  if (s.length <= 200) return s || '—'
  return s.slice(0, 200) + '…'
}

/** Prefer directory author name; fall back to submitter email when unknown or empty name. */
function displayAuthorLabel(data: PendingItem) {
  const name = data.authorName != null ? String(data.authorName).trim() : ''
  if (name) return name
  if (data.email != null && String(data.email).trim()) return String(data.email).trim()
  return '—'
}

async function fetchCountries() {
  try {
    const res = await fetch(auth.apiUrl('/api/countries'), { credentials: 'include' })
    if (!res.ok) return
    const data = await res.json()
    countries.value = data.countries ?? []
  } catch {
    countries.value = []
  }
}

async function fetchRequests() {
  loading.value = true
  clearError()
  try {
    const res = await fetch(auth.apiUrl('/api/position-requests'), { credentials: 'include' })
    if (res.status === 401) {
      showError('Please sign in to view pending requests.')
      pending.value = []
      failed.value = []
      return
    }
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    pending.value = data.pending ?? []
    failed.value = data.failed ?? []
  } catch (err) {
    showError((err as Error).message || 'Failed to load position requests')
    pending.value = []
    failed.value = []
  } finally {
    loading.value = false
  }
}

function openAcceptDialog(data: PendingItem) {
  actionRequest.value = { sig: data.sig }
  acceptDialogVisible.value = true
}

function openDeclineDialog(data: PendingItem) {
  actionRequest.value = { sig: data.sig }
  declineReason.value = ''
  declineDialogVisible.value = true
}

function onDeclineDialogHide() {
  actionRequest.value = null
  declineReason.value = ''
}

async function confirmAccept() {
  const sig = actionRequest.value?.sig
  if (!sig) return
  acceptLoading.value = true
  clearError()
  try {
    const res = await fetch(auth.apiUrl(`/api/submissions/pending/${encodeURIComponent(sig)}/accept`), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
    })
    const data = await res.json().catch(() => ({}))
    if (res.ok) {
      acceptDialogVisible.value = false
      actionRequest.value = null
      toastSuccess('The request was accepted and applied.', 'Accepted')
      void pendingCountStore.fetchCount()
      await fetchRequests()
    } else {
      showError((data.error as string) || res.statusText)
    }
  } catch (err) {
    showError((err as Error).message || 'Failed to accept request')
  } finally {
    acceptLoading.value = false
  }
}

async function confirmDecline() {
  const sig = actionRequest.value?.sig
  if (!sig) return
  declineLoading.value = true
  clearError()
  try {
    const res = await fetch(auth.apiUrl(`/api/submissions/pending/${encodeURIComponent(sig)}/reject`), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ reason: declineReason.value.trim() }),
    })
    const data = await res.json().catch(() => ({}))
    if (res.ok) {
      declineDialogVisible.value = false
      onDeclineDialogHide()
      toastSuccess('The request was declined.', 'Declined')
      void pendingCountStore.fetchCount()
      await fetchRequests()
    } else {
      showError((data.error as string) || res.statusText)
    }
  } catch (err) {
    showError((err as Error).message || 'Failed to decline request')
  } finally {
    declineLoading.value = false
  }
}

onMounted(async () => {
  await fetchCountries()
  fetchRequests()
  document.addEventListener('keydown', onKeyDown)
})

onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKeyDown)
})

/** Index of the currently focused row in the pending list. */
const focusedIndex = ref(0)

/** The currently expanded request (if exactly one is expanded). */
const expandedRequest = computed(() => {
  const ids = Object.keys(expandedRows.value).filter((k) => expandedRows.value[k])
  if (ids.length !== 1) return null
  const id = Number(ids[0])
  return pending.value.find((p) => p.id === id) || null
})

function rowClass(data: PendingItem) {
  const idx = pending.value.indexOf(data)
  return idx === focusedIndex.value ? 'row-focused' : ''
}

function onKeyDown(e: KeyboardEvent) {
  // Don't intercept when a dialog is open or user is typing in an input
  if (acceptDialogVisible.value || declineDialogVisible.value) return
  const tag = (e.target as HTMLElement)?.tagName?.toLowerCase()
  if (tag === 'input' || tag === 'textarea' || tag === 'select') return
  if (!pending.value.length) return

  switch (e.key) {
    case 'ArrowDown':
    case 'j': {
      e.preventDefault()
      focusedIndex.value = Math.min(focusedIndex.value + 1, pending.value.length - 1)
      break
    }
    case 'ArrowUp':
    case 'k': {
      e.preventDefault()
      focusedIndex.value = Math.max(focusedIndex.value - 1, 0)
      break
    }
    case 'Enter':
    case ' ': {
      e.preventDefault()
      const item = pending.value[focusedIndex.value]
      if (!item) break
      // Toggle expansion
      if (expandedRows.value[item.id]) {
        const copy = { ...expandedRows.value }
        delete copy[item.id]
        expandedRows.value = copy
      } else {
        // Collapse others, expand this one
        expandedRows.value = { [item.id]: true }
      }
      break
    }
    case 'Escape': {
      // Collapse all expanded rows
      if (Object.keys(expandedRows.value).length) {
        e.preventDefault()
        expandedRows.value = {}
      }
      break
    }
    case 'a':
    case 'A': {
      if (!auth.isReviewer) break
      const req = expandedRequest.value
      if (req) {
        e.preventDefault()
        openAcceptDialog(req)
      }
      break
    }
    case 'd':
    case 'D': {
      if (!auth.isReviewer) break
      const req = expandedRequest.value
      if (req) {
        e.preventDefault()
        openDeclineDialog(req)
      }
      break
    }
  }
}
</script>

<style scoped>
.mt-0 { margin-top: 0; }
.mb-3 { margin-bottom: 0.75rem; }
.mb-4 { margin-bottom: 1rem; }
.m-0 { margin: 0; }
.p-4 { padding: 1rem; }
.text-color-secondary { color: var(--p-text-muted-color); }
.flex { display: flex; }
.align-items-center { align-items: center; }
.justify-content-center { justify-content: center; }
.text-truncate { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.d-inline-block { display: inline-block; }
.request-details-expansion {
  padding: 0.75rem 1rem;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color, rgba(0, 0, 0, 0.08));
  border-radius: 6px;
  margin: 0 0.5rem 0.5rem 0.5rem;
}
.details-actions { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.details-heading { margin: 0 0 0.5rem 0; font-size: 0.875rem; font-weight: 600; color: var(--p-text-color); }
.field { display: flex; flex-direction: column; gap: 0.25rem; }
.field label { font-weight: 500; font-size: 0.875rem; color: var(--p-text-color); }
.mb-2 { margin-bottom: 0.5rem; }
.w-full { width: 100%; }
.details-json { margin: 0; font-size: 0.8rem; overflow-x: auto; white-space: pre-wrap; word-break: break-word; color: var(--p-text-color); }
.details-object { font-size: 0.875rem; color: var(--p-text-color); }
.details-model-and-map {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: flex-start;
}
.details-model-content {
  flex: 1 1 240px;
  min-width: 0;
}
.details-map-wrap {
  flex: 1 1 280px;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  min-width: 0;
}
.details-map-wrap :deep(.object-map-container) {
  max-height: 200px;
  border-radius: 6px;
  overflow: hidden;
}
.details-map-hint {
  font-size: 0.75rem;
  color: var(--p-text-color-secondary);
}
.mt-2 { margin-top: 0.5rem; }
.keyboard-hint {
  display: block;
  margin-top: 0.25rem;
  font-size: 0.75rem;
  opacity: 0.7;
}
.keyboard-hint kbd {
  display: inline-block;
  padding: 0.1rem 0.35rem;
  margin: 0 0.1rem;
  font-size: 0.7rem;
  font-family: inherit;
  border: 1px solid var(--p-content-border-color, #ccc);
  border-radius: 3px;
  background: var(--p-surface-50, #f8f9fa);
  box-shadow: 0 1px 0 var(--p-content-border-color, #ccc);
}
:deep(.row-focused) {
  outline: 2px solid var(--p-primary-color, #3b82f6);
  outline-offset: -2px;
  background: color-mix(in srgb, var(--p-primary-color, #3b82f6) 8%, transparent) !important;
}
</style>
<style>
/* Unscoped: dark mode override for expansion (element may be rendered inside DataTable) */
.dark .request-details-expansion {
  background: var(--p-surface-600);
}
</style>
