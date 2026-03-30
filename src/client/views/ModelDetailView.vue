<template>
  <div>
    <p v-if="loading" class="m-0">Loading…</p>
    <template v-else-if="model">
      <Breadcrumb :model="breadcrumbItems" class="mb-3">
        <template #item="{ item }">
          <router-link v-if="item.to" :to="item.to" class="p-breadcrumb-link">{{ item.label }}</router-link>
          <span v-else>{{ item.label }}</span>
        </template>
      </Breadcrumb>

      <Tag v-if="hasPendingRequest" severity="info" icon="pi pi-inbox" class="mb-3">Pending request</Tag>

      <div class="button-bar mb-3">
        <Button label="Update" icon="pi pi-pencil" :disabled="hasPendingRequest" @click="showUpdatePanel = true" />
        <Button
          label="Delete"
          icon="pi pi-trash"
          severity="danger"
          :disabled="deleteModelButtonDisabled"
          @click="openDeleteDialog"
        />
      </div>
      <p
        v-if="deleteModelBlockedByObjects"
        class="text-secondary text-sm m-0 mb-2"
      >
        Delete is only available when no object placements use this model. Remove those objects first.
      </p>

      <Message v-if="deleteSuccessMessage" severity="success" class="mb-3" :closable="true" @close="deleteSuccessMessage = ''">{{ deleteSuccessMessage }}</Message>

      <ModelDetailsCard :model="modelForDetailsCard" />

      <ModelContentCard class="mt-3" :model-id="model.id" />

      <ModelAddPlacementsPanel
        v-if="model.isStatic === false"
        class="mt-4"
        :model-id="model.id"
        :model-name="model.name || model.filename || `Model #${model.id}`"
        :map-center="objectsMapCenter"
        @submitted="onPlacementsSubmitted"
      />

      <Panel class="mt-4" header="Objects using this model">
        <p class="text-secondary mt-0 mb-3">Placements in the scenery database for this model.</p>
        <DataTable
          :value="modelObjects"
          :loading="objectsLoading"
          lazy
          data-key="id"
          paginator
          :rows="objectsPageSize"
          :total-records="objectsTotal"
          :first="objectsFirst"
          :sort-field="objectsSortField"
          :sort-order="objectsSortOrder"
          paginator-template="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport"
          current-page-report-template="Showing {first} to {last} of {totalRecords} entries"
          responsive-layout="scroll"
          @page="onObjectsPage"
          @sort="onObjectsSort"
        >
          <Column header="" style="width: 3.5rem">
            <template #body="{ data }">
              <router-link :to="`/objects/${data.id}`">
                <img
                  :src="objectThumbUrl(model.id)"
                  alt=""
                  class="thumb-cell"
                  @error="onThumbError"
                />
              </router-link>
            </template>
          </Column>
          <Column field="id" header="ID" sortable style="width: 5rem">
            <template #body="{ data }">
              <router-link :to="`/objects/${data.id}`">#{{ data.id }}</router-link>
            </template>
          </Column>
          <Column field="description" header="Description" sortable>
            <template #body="{ data }">
              <router-link :to="`/objects/${data.id}`">{{ data.description || 'Unnamed' }}</router-link>
            </template>
          </Column>
          <Column field="country" header="Country" sortable>
            <template #body="{ data }">{{ data.country || '—' }}</template>
          </Column>
          <Column field="lat" header="Lat" sortable>
            <template #body="{ data }">{{ formatCoord(data.position?.lat) }}</template>
          </Column>
          <Column field="lon" header="Lon" sortable>
            <template #body="{ data }">{{ formatCoord(data.position?.lon) }}</template>
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
            <p v-if="!objectsLoading" class="m-0 p-3 text-center text-secondary">No objects use this model yet.</p>
          </template>
        </DataTable>
      </Panel>

      <Panel v-if="showUpdatePanel" class="mt-4" header="Request model update">
        <p class="text-secondary mb-3 model-update-hint m-0">
          To request changes to this model (e.g. name, description, thumbnail, or files), please submit a new version via
          <router-link to="/models/add" class="model-update-add-model-link">
            <Button label="Add model" icon="pi pi-plus" />
          </router-link>
          <span>, or contact the maintainers.</span>
        </p>
        <Button label="Close" severity="secondary" @click="showUpdatePanel = false" />
      </Panel>
    </template>

    <Dialog
      v-model:visible="deleteDialogVisible"
      header="Delete model"
      modal
      :closable="true"
      :style="{ width: '28rem' }"
      @hide="onDeleteDialogHide"
    >
      <p class="mb-2">Do you really want to delete this model? To confirm, enter the model ID <strong>{{ model?.id }}</strong> below.</p>
      <div class="field mb-2">
        <label for="delete-confirm-id">Model ID</label>
        <InputText id="delete-confirm-id" v-model="deleteConfirmId" placeholder="Enter model ID" class="w-full" />
      </div>
      <div v-if="needsContactEmail" class="field">
        <label for="delete-email">Email <span class="required">*</span></label>
        <InputText id="delete-email" v-model="requestEmail" type="email" placeholder="Your email address" class="w-full" />
        <small class="text-secondary">Required to associate this request with your contact.</small>
      </div>
      <template #footer>
        <Button label="Cancel" severity="secondary" @click="deleteDialogVisible = false" />
        <Button label="Delete" severity="danger" :disabled="!canSubmitDelete" @click="confirmDelete" :loading="deleteSubmitting" />
      </template>
    </Dialog>

    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
    <ErrorDialog v-model:visible="objectsErrorDialogVisible" :message="objectsError ?? ''" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Panel from 'primevue/panel'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
import ModelDetailsCard from '@/components/ModelDetailsCard.vue'
import ModelContentCard from '@/components/ModelContentCard.vue'
import ModelAddPlacementsPanel from '@/components/ModelAddPlacementsPanel.vue'

const route = useRoute()
const auth = useAuthStore()
const model = ref<{
  id: number
  name?: string
  filename?: string
  hasPendingRequest?: boolean
  isStatic?: boolean
  groupId?: number
} | null>(null)
const loading = ref(true)
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()

const deleteDialogVisible = ref(false)
const deleteConfirmId = ref('')
const deleteSubmitting = ref(false)
const deleteSuccessMessage = ref('')
const requestEmail = ref('')
const showUpdatePanel = ref(false)

const modelObjects = ref<
  {
    id: number
    description?: string | null
    country?: string | null
    position?: { lat?: number; lon?: number; offset?: number; heading?: number }
    lastUpdated?: unknown
  }[]
>([])
const objectsTotal = ref(0)
const objectsFirst = ref(0)
const objectsPageSize = 15
const objectsLoading = ref(false)
const objectsError = ref<string | null>(null)
const objectsErrorDialogVisible = ref(false)
const objectsSortField = ref('lastUpdated')
const objectsSortOrder = ref(-1)

/** Up to API max limit (100); used only for the add-placements map overlay. */
const objectsForMap = ref<
  {
    id: number
    description?: string | null
    type?: string | null
    shared?: number | null
    country?: string | null
    position?: { lat?: number; lon?: number; offset?: number; heading?: number }
  }[]
>([])

const hasPendingRequest = computed(() => model.value?.hasPendingRequest === true)

/** True when we know the model is still used by at least one (non-deleted) object. */
const deleteModelBlockedByObjects = computed(
  () => !objectsLoading.value && !objectsError.value && objectsTotal.value > 0
)

const deleteModelButtonDisabled = computed(
  () => hasPendingRequest.value || objectsLoading.value || objectsError.value != null || objectsTotal.value > 0
)

const objectsMapCenter = computed((): [number, number] => {
  const withPos = objectsForMap.value.filter(
    (o) =>
      o.position?.lat != null &&
      o.position?.lon != null &&
      Number.isFinite(o.position.lat) &&
      Number.isFinite(o.position.lon)
  )
  if (withPos.length === 0) return [10, 53.5]
  const lat = withPos.reduce((s, o) => s + Number(o.position!.lat), 0) / withPos.length
  const lon = withPos.reduce((s, o) => s + Number(o.position!.lon), 0) / withPos.length
  return [lon, lat]
})

const breadcrumbItems = computed(() => [
  { label: 'Models', to: '/models' },
  { label: model.value?.name || model.value?.filename || 'Model', to: null },
])

const modelForDetailsCard = computed(() => model.value || { id: undefined, name: '', filename: '', author: undefined })

const deleteConfirmMatches = computed(() => {
  const id = model.value?.id
  if (id == null) return false
  return String(deleteConfirmId.value).trim() === String(id)
})

/** Signed-in with a non-empty author email — no extra field. */
const hasSessionContactEmail = computed(
  () => auth.isAuthenticated && !!(auth.user?.email && String(auth.user.email).trim())
)

/** Guest or signed-in without email on the author record. */
const needsContactEmail = computed(() => !hasSessionContactEmail.value)

const hasValidEmail = computed(
  () => hasSessionContactEmail.value || (requestEmail.value || '').trim().length > 0
)

const canSubmitDelete = computed(() => deleteConfirmMatches.value && hasValidEmail.value)

function openDeleteDialog() {
  if (deleteModelButtonDisabled.value) return
  deleteConfirmId.value = ''
  deleteDialogVisible.value = true
}

function onDeleteDialogHide() {
  deleteConfirmId.value = ''
  requestEmail.value = ''
}

async function confirmDelete() {
  if (!deleteConfirmMatches.value || !model.value || objectsTotal.value > 0) return
  deleteSubmitting.value = true
  clearError()
  try {
    const url = auth.apiUrl('/api/submissions/model/delete')
    const email =
      (auth.user?.email && String(auth.user.email).trim()) || requestEmail.value.trim()
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        modelId: model.value.id,
        comment: '',
        email,
      }),
    })
    const data = await res.json().catch(() => ({}))
    if (res.ok) {
      deleteDialogVisible.value = false
      deleteSuccessMessage.value = (data.message as string) || 'Delete request queued for review.'
    } else {
      showError((data.error as string) || res.statusText)
    }
  } catch (err) {
    showError((err as Error).message || 'Failed to submit delete request')
  } finally {
    deleteSubmitting.value = false
  }
}

async function fetchModel() {
  const id = route.params.id
  if (!id) return
  loading.value = true
  clearError()
  model.value = null
  objectsFirst.value = 0
  try {
    const res = await fetch(auth.apiUrl(`/api/models/${id}`), { credentials: 'include' })
    if (!res.ok) {
      if (res.status === 404) showError('Model not found')
      else throw new Error(res.statusText)
      return
    }
    const data = await res.json()
    model.value = data
    await Promise.all([fetchModelObjects(), fetchObjectsForMap()])
  } catch (err) {
    showError((err as Error).message || 'Failed to load model')
  } finally {
    loading.value = false
  }
}

function objectThumbUrl(modelId: number) {
  return auth.apiUrl(`/api/models/${modelId}/thumbnail`)
}

function onThumbError(e: Event) {
  const t = e.target as HTMLImageElement
  if (t) t.style.display = 'none'
}

function formatCoord(n: unknown) {
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

function formatDate(iso: unknown) {
  if (!iso) return '—'
  try {
    return new Date(String(iso)).toLocaleDateString(undefined, { dateStyle: 'short' })
  } catch {
    return String(iso)
  }
}

async function fetchModelObjects() {
  const mid = model.value?.id
  if (mid == null) {
    modelObjects.value = []
    objectsTotal.value = 0
    return
  }
  objectsLoading.value = true
  objectsError.value = null
  objectsErrorDialogVisible.value = false
  try {
    const params = new URLSearchParams({
      model: String(mid),
      offset: String(objectsFirst.value),
      limit: String(objectsPageSize),
      sortField: objectsSortField.value,
      sortOrder: String(objectsSortOrder.value),
    })
    const res = await fetch(auth.apiUrl(`/api/objects?${params}`), { credentials: 'include' })
    const text = await res.text()
    if (!res.ok) {
      let msg = text || res.statusText
      try {
        const j = JSON.parse(text) as { error?: string }
        if (j.error) msg = j.error
      } catch {
        /* keep msg */
      }
      throw new Error(msg)
    }
    const data = JSON.parse(text) as { objects?: typeof modelObjects.value; total?: number }
    modelObjects.value = data.objects || []
    objectsTotal.value = data.total ?? 0
  } catch (err) {
    objectsError.value = (err as Error).message || 'Failed to load objects'
    objectsErrorDialogVisible.value = true
    modelObjects.value = []
    objectsTotal.value = 0
  } finally {
    objectsLoading.value = false
  }
}

function onObjectsPage(e: { first: number }) {
  objectsFirst.value = e.first
  void fetchModelObjects()
}

function onObjectsSort(e: { sortField?: string; sortOrder?: number }) {
  objectsSortField.value = e.sortField ?? 'lastUpdated'
  objectsSortOrder.value = e.sortOrder ?? -1
  objectsFirst.value = 0
  void fetchModelObjects()
}

async function fetchObjectsForMap() {
  const mid = model.value?.id
  if (mid == null || model.value.isStatic !== false) {
    objectsForMap.value = []
    return
  }
  try {
    const params = new URLSearchParams({
      model: String(mid),
      offset: '0',
      limit: '100',
      sortField: 'id',
      sortOrder: '1',
    })
    const res = await fetch(auth.apiUrl(`/api/objects?${params}`), { credentials: 'include' })
    if (!res.ok) {
      objectsForMap.value = []
      return
    }
    const data = (await res.json()) as { objects?: typeof objectsForMap.value }
    objectsForMap.value = data.objects || []
  } catch {
    objectsForMap.value = []
  }
}

function onPlacementsSubmitted() {
  void fetchModelObjects()
  void fetchObjectsForMap()
}

onMounted(() => fetchModel())
watch(() => route.params.id, () => fetchModel())

watch(needsContactEmail, () => {
  if (!needsContactEmail.value) requestEmail.value = ''
})
</script>

<style scoped>
.button-bar { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.model-update-hint {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.35rem 0.5rem;
  line-height: 1.5;
}
.model-update-add-model-link {
  display: inline-flex;
  text-decoration: none;
  color: inherit;
  vertical-align: middle;
}
.field { display: flex; flex-direction: column; gap: 0.25rem; }
.field label { font-weight: 500; font-size: 0.875rem; color: var(--p-text-color); }
.required { color: var(--p-error-color, #e24c4c); }
.field small { font-size: 0.75rem; margin-top: 0.15rem; }
.text-secondary { color: var(--p-text-muted-color); font-size: 0.875rem; }
.text-sm { font-size: 0.8125rem; }
.mt-0 { margin-top: 0; }
.mt-3 { margin-top: 1rem; }
.mt-4 { margin-top: 1rem; }
.mb-2 { margin-bottom: 0.5rem; }
.mb-3 { margin-bottom: 0.75rem; }
.m-0 { margin: 0; }
.w-full { width: 100%; }
.text-secondary { color: var(--p-text-muted-color); font-size: 0.875rem; }
.thumb-cell { width: 36px; height: 36px; object-fit: cover; border-radius: 4px; display: block; }
</style>
