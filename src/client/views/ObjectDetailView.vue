<template>
  <div>
    <p v-if="loading" class="m-0">Loading…</p>
    <template v-else-if="object">
      <Breadcrumb :model="breadcrumbItems" class="mb-3">
        <template #item="{ item }">
          <router-link v-if="item.to" :to="item.to" class="p-breadcrumb-link">{{ item.label }}</router-link>
          <span v-else class="p-breadcrumb-chevron">{{ item.label }}</span>
        </template>
      </Breadcrumb>

      <h1 class="mt-0">{{ object.description || 'Object' }}</h1>
      <Tag v-if="hasPendingRequest" severity="info" icon="pi pi-inbox" class="mb-3">Pending request</Tag>

      <div class="button-bar mb-3">
        <Button label="Update" icon="pi pi-pencil" :disabled="hasPendingRequest" @click="showUpdateForm = true" />
        <Button label="Delete" icon="pi pi-trash" severity="danger" :disabled="hasPendingRequest" @click="openDeleteDialog" />
      </div>

      <ObjectDetailsCard :object="object" :countries="countries" />

      <Panel v-if="showUpdateForm" class="mt-4" header="Submit update request">
        <p class="text-secondary mb-3">Change the values below and submit to queue an update for review. Only longitude, latitude, elevation offset and heading are editable here.</p>
        <div class="update-map-block mb-3">
          <span class="update-map-label">Drag the marker to set latitude and longitude</span>
          <ObjectMap
            selection-mode
            selection-draggable
            compact
            :initial-center="updatePanelMapCenter"
            :initial-zoom="15"
            :selection-position="updatePanelMapPosition"
            @position-select="onUpdateMapPosition"
          />
        </div>
        <div class="update-form-grid">
          <div class="field">
            <label for="edit-longitude">Longitude</label>
            <InputNumber id="edit-longitude" v-model="editForm.longitude" :min-fraction-digits="2" :max-fraction-digits="6" />
          </div>
          <div class="field">
            <label for="edit-latitude">Latitude</label>
            <InputNumber id="edit-latitude" v-model="editForm.latitude" :min-fraction-digits="2" :max-fraction-digits="6" />
          </div>
          <div class="field">
            <label for="edit-offset">Elevation offset (m)</label>
            <InputNumber id="edit-offset" v-model="editForm.offset" />
          </div>
          <div class="field">
            <label for="edit-heading">Heading (°)</label>
            <InputNumber id="edit-heading" v-model="editForm.heading" :min="0" :max="360" />
          </div>
        </div>
        <div v-if="needsContactEmail" class="field mt-2">
          <label for="edit-email">Email <span class="required">*</span></label>
          <InputText id="edit-email" v-model="requestEmail" type="email" placeholder="Your email address" class="w-full" />
          <small class="text-secondary">Required to associate this request with your contact.</small>
        </div>
        <div class="field mt-2">
          <label for="edit-comment">Comment (optional)</label>
          <InputText id="edit-comment" v-model="editForm.comment" class="w-full" placeholder="Reason for update" />
        </div>
        <div class="form-actions mt-3">
          <Button label="Submit" icon="pi pi-send" @click="submitUpdateRequest" :disabled="!canSubmitUpdate || hasPendingRequest" :loading="updateSubmitting" />
          <Button label="Cancel" severity="secondary" text @click="showUpdateForm = false" class="ml-2" />
        </div>
      </Panel>
    </template>

    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />

    <Dialog
      v-model:visible="deleteDialogVisible"
      header="Delete object"
      modal
      :closable="true"
      :style="{ width: '28rem' }"
      @hide="onDeleteDialogHide"
    >
      <p class="mb-2">Do you really want to delete this object? To confirm, enter the object ID <strong>{{ object?.id }}</strong> below.</p>
      <div class="field mb-2">
        <label for="delete-confirm-id">Object ID</label>
        <InputText id="delete-confirm-id" v-model="deleteConfirmId" placeholder="Enter object ID" class="w-full" />
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
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import Dialog from 'primevue/dialog'
import InputNumber from 'primevue/inputnumber'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
import { useAppToast } from '@/composables/useAppToast'
import ObjectDetailsCard from '@/components/ObjectDetailsCard.vue'
import ObjectMap from '@/components/ObjectMap.vue'

const route = useRoute()
const auth = useAuthStore()
const object = ref<{
  id: number
  description?: string | null
  modelId?: number
  country?: string | null
  hasPendingRequest?: boolean
  position?: { lat?: number; lon?: number; offset?: number; heading?: number }
} | null>(null)
const loading = ref(true)
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()
const { toastSuccess } = useAppToast()
const countries = ref<{ code: string; name?: string | null }[]>([])

const deleteDialogVisible = ref(false)
const deleteConfirmId = ref('')
const deleteSubmitting = ref(false)
const requestEmail = ref('')
const showUpdateForm = ref(false)
const updateSubmitting = ref(false)

const hasPendingRequest = computed(() => object.value?.hasPendingRequest === true)

const editForm = ref({
  longitude: 0,
  latitude: 0,
  offset: null as number | null,
  heading: 0,
  comment: '',
})

const breadcrumbItems = computed(() => [
  { label: 'Objects', to: '/objects' },
  { label: object.value?.description || 'Object', to: null },
])

const deleteConfirmMatches = computed(() => {
  const id = object.value?.id
  if (id == null) return false
  const entered = String(deleteConfirmId.value).trim()
  return entered === String(id)
})

const hasSessionContactEmail = computed(
  () => auth.isAuthenticated && !!(auth.user?.email && String(auth.user.email).trim())
)

const needsContactEmail = computed(() => !hasSessionContactEmail.value)

const hasValidEmail = computed(
  () => hasSessionContactEmail.value || (requestEmail.value || '').trim().length > 0
)

const canSubmitDelete = computed(() => deleteConfirmMatches.value && hasValidEmail.value)

const canSubmitUpdate = computed(() => hasValidEmail.value)

const mapUrl = computed(() => {
  const lon = object.value?.position?.lon
  const lat = object.value?.position?.lat
  if (lon == null || lat == null) return '#'
  return `/map/?lon=${Number(lon)}&lat=${Number(lat)}&z=14`
})

/** Center for the update-panel map [lng, lat] */
const updatePanelMapCenter = computed((): [number, number] => {
  const lon = Number(editForm.value.longitude)
  const lat = Number(editForm.value.latitude)
  if (Number.isFinite(lon) && Number.isFinite(lat)) return [lon, lat]
  const p = object.value?.position
  const plon = p?.lon != null ? Number(p.lon) : NaN
  const plat = p?.lat != null ? Number(p.lat) : NaN
  if (Number.isFinite(plon) && Number.isFinite(plat)) return [plon, plat]
  return [10, 53.5]
})

const updatePanelMapPosition = computed(() => {
  let lat = Number(editForm.value.latitude)
  let lon = Number(editForm.value.longitude)
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    const p = object.value?.position
    lat = p?.lat != null ? Number(p.lat) : 0
    lon = p?.lon != null ? Number(p.lon) : 0
  }
  return { lat, lon }
})

function roundCoord(n: number): number {
  return Math.round(n * 1e6) / 1e6
}

function onUpdateMapPosition(pos: { lat: number; lon: number }) {
  editForm.value.latitude = roundCoord(pos.lat)
  editForm.value.longitude = roundCoord(pos.lon)
}

function syncEditFormFromObject() {
  const obj = object.value
  if (!obj?.position) return
  editForm.value = {
    longitude: Number(obj.position.lon) || 0,
    latitude: Number(obj.position.lat) || 0,
    offset: obj.position.offset != null ? Number(obj.position.offset) : null,
    heading: obj.position.heading != null ? Number(obj.position.heading) : 0,
    comment: editForm.value.comment,
  }
}

function openDeleteDialog() {
  deleteConfirmId.value = ''
  deleteDialogVisible.value = true
}

function onDeleteDialogHide() {
  deleteConfirmId.value = ''
  requestEmail.value = ''
}

async function confirmDelete() {
  if (!deleteConfirmMatches.value || !object.value) return
  deleteSubmitting.value = true
  try {
    const url = auth.apiUrl('/api/submissions/object/delete')
    const email =
      (auth.user?.email && String(auth.user.email).trim()) || requestEmail.value.trim()
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        objId: object.value.id,
        comment: '',
        email,
      }),
    })
    const data = await res.json().catch(() => ({}))
    if (res.ok) {
      deleteDialogVisible.value = false
      clearError()
      toastSuccess((data.message as string) || 'Delete request queued for review.', 'Submitted')
    } else {
      showError((data.error as string) || res.statusText)
    }
  } catch (err) {
    showError((err as Error).message || 'Failed to submit delete request')
  } finally {
    deleteSubmitting.value = false
  }
}

async function submitUpdateRequest() {
  if (!object.value || !canSubmitUpdate.value) return
  updateSubmitting.value = true
  try {
    const url = auth.apiUrl('/api/submissions/object/update')
    const email =
      (auth.user?.email && String(auth.user.email).trim()) || requestEmail.value.trim()
    const body = {
      objectId: object.value.id,
      modelId: object.value.modelId ?? 0,
      description: object.value.description ?? '',
      country: object.value.country ?? '',
      longitude: editForm.value.longitude,
      latitude: editForm.value.latitude,
      offset: editForm.value.offset,
      orientation: editForm.value.heading,
      comment: editForm.value.comment.trim(),
      email,
    }
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify(body),
    })
    const data = await res.json().catch(() => ({}))
    if (res.ok) {
      toastSuccess((data.message as string) || 'Update request queued for review.', 'Submitted')
    } else {
      showError((data.error as string) || res.statusText)
    }
  } catch (err) {
    showError((err as Error).message || 'Failed to submit update request')
  } finally {
    updateSubmitting.value = false
  }
}

async function fetchObject() {
  const id = route.params.id
  if (!id) return
  loading.value = true
  clearError()
  object.value = null
  try {
    const res = await fetch(auth.apiUrl(`/api/objects/${id}`), { credentials: 'include' })
    if (!res.ok) {
      if (res.status === 404) showError('Object not found')
      else throw new Error(res.statusText)
      return
    }
    const data = await res.json()
    object.value = data
    syncEditFormFromObject()
  } catch (err) {
    showError((err as Error).message || 'Failed to load object')
  } finally {
    loading.value = false
  }
}

async function fetchCountries() {
  try {
    const res = await fetch(auth.apiUrl('/api/countries'), { credentials: 'include' })
    if (!res.ok) return
    const data = await res.json()
    countries.value = data.countries || []
  } catch {
    countries.value = []
  }
}

onMounted(async () => {
  await fetchCountries()
  await fetchObject()
})

watch(() => route.params.id, () => {
  fetchObject()
})

watch(object, (obj) => {
  if (obj) {
    document.title = `${obj.description || 'Object'} – FlightGear Scenemodels`
    syncEditFormFromObject()
  }
}, { immediate: true })

watch(showUpdateForm, (visible) => {
  if (visible && object.value) syncEditFormFromObject()
})

watch(needsContactEmail, () => {
  if (!needsContactEmail.value) requestEmail.value = ''
})
</script>

<style scoped>
.button-bar { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.update-form-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(12rem, 1fr)); gap: 1rem; }
.field { display: flex; flex-direction: column; gap: 0.25rem; }
.field label { font-weight: 500; font-size: 0.875rem; color: var(--p-text-color); }
.required { color: var(--p-error-color, #e24c4c); }
.field small { font-size: 0.75rem; margin-top: 0.15rem; }
.form-actions { display: flex; align-items: center; flex-wrap: wrap; gap: 0.5rem; }
.update-map-block { max-width: 28rem; }
.update-map-label { display: block; font-weight: 500; font-size: 0.875rem; color: var(--p-text-color); margin-bottom: 0.35rem; }
.text-secondary { color: var(--p-text-muted-color); font-size: 0.875rem; }
.mt-0 { margin-top: 0; }
.mt-2 { margin-top: 0.5rem; }
.mt-3 { margin-top: 0.75rem; }
.mt-4 { margin-top: 1rem; }
.mb-2 { margin-bottom: 0.5rem; }
.mb-3 { margin-bottom: 0.75rem; }
.ml-2 { margin-left: 0.5rem; }
.m-0 { margin: 0; }
.w-full { width: 100%; }
</style>
