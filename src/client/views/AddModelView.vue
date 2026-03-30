<template>
  <div class="add-model-view">
    <h1 class="mt-0">Add a model</h1>
    <p class="text-color-secondary mt-0 mb-4">
      Submit a static or shared 3D model to the FlightGear scenery database. Complete the steps below; you can go back to edit any step before submitting.
    </p>

    <Message v-if="success" severity="success" class="mb-3" :closable="false">
      Your model has been queued for review (request #{{ successId }}). A reviewer will process it shortly.
      <router-link to="/models">Back to models</router-link>
    </Message>

    <template v-if="!success">
      <div class="stepper mb-4">
        <div
          v-for="(label, i) in stepLabels"
          :key="i"
          class="stepper-item"
          :class="{ active: currentStep === i, done: currentStep > i }"
        >
          <span class="stepper-num">{{ i + 1 }}</span>
          <span class="stepper-label">{{ label }}</span>
          <span v-if="i < stepLabels.length - 1" class="stepper-sep" />
        </div>
      </div>

      <Card>
        <template #content>
          <!-- Step 0: Model info & files -->
          <div v-show="currentStep === 0" class="step-panel">
            <h2 class="mt-0">Model details and files</h2>
            <ul class="help-list mb-4">
              <li>Use a common base name for files (e.g. <code>tower.ac</code>, <code>tower.xml</code>, <code>tower.png</code>).</li>
              <li>PNG textures must have width and height as a power of 2.</li>
              <li>Thumbnail can be any image format; it will be converted to 320×240 JPEG.</li>
            </ul>
            <div class="form-grid">
              <label for="add-model-group">Model family <span class="required">*</span></label>
              <Select
                id="add-model-group"
                v-model="form.groupId"
                :options="groupOptions"
                option-label="label"
                option-value="value"
                placeholder="Select family"
                class="w-full"
              />
              <label for="add-model-name">Model name <span class="required">*</span></label>
              <InputText
                id="add-model-name"
                v-model="form.name"
                maxlength="100"
                placeholder="e.g. Cornet antenna radome - Brittany - France"
                class="w-full"
              />
              <label for="add-model-desc">Description</label>
              <InputText
                id="add-model-desc"
                v-model="form.description"
                maxlength="100"
                placeholder="Optional details about the model"
                class="w-full"
              />
              <label for="add-model-ac3d">AC3D file <span class="required">*</span></label>
              <div class="file-cell">
                <input
                  id="add-model-ac3d"
                  type="file"
                  accept=".ac"
                  @change="onAc3dChange"
                />
                <span class="file-name">{{ ac3dFileName || 'No file chosen' }}</span>
              </div>
              <label for="add-model-thumb">Thumbnail image <span class="required">*</span></label>
              <div class="file-cell">
                <input
                  id="add-model-thumb"
                  type="file"
                  accept="image/*"
                  @change="onThumbChange"
                />
                <span class="file-name">{{ thumbFileName || 'No file chosen' }}</span>
              </div>
              <label for="add-model-xml">XML file (optional)</label>
              <div class="file-cell">
                <input
                  id="add-model-xml"
                  type="file"
                  accept=".xml,text/xml,application/xml"
                  @change="onXmlChange"
                />
                <span class="file-name">{{ xmlFileName || 'None' }}</span>
              </div>
              <label for="add-model-png">PNG texture(s) (optional)</label>
              <div class="file-cell">
                <input
                  id="add-model-png"
                  type="file"
                  accept=".png,image/png"
                  multiple
                  @change="onPngChange"
                />
                <span class="file-name">{{ pngFileSummary }}</span>
              </div>
            </div>
          </div>

          <!-- Step 1: Location -->
          <div v-show="currentStep === 1" class="step-panel">
            <h2 class="mt-0">Location</h2>
            <p class="text-color-secondary">Enter the position where the model is placed, or click on the map to set it. Required even for shared models.</p>
            <div class="location-map-wrap mb-4">
              <ObjectMap
                :selection-mode="true"
                :selection-position="locationSelectionPosition"
                :initial-center="locationMapCenter"
                :initial-zoom="10"
                compact
                @position-select="onMapPositionSelect"
              />
              <span class="location-map-hint">Click on the map to place the marker</span>
            </div>
            <div class="form-grid">
              <label for="add-model-lon">Longitude <span class="required">*</span></label>
              <InputText
                id="add-model-lon"
                v-model="form.longitude"
                type="text"
                placeholder="-180 … 180"
                class="w-full"
              />
              <label for="add-model-lat">Latitude <span class="required">*</span></label>
              <InputText
                id="add-model-lat"
                v-model="form.latitude"
                type="text"
                placeholder="-90 … 90"
                class="w-full"
              />
              <label for="add-model-country">Country <span class="required">*</span></label>
              <Select
                id="add-model-country"
                v-model="form.country"
                :options="countryOptions"
                option-label="label"
                option-value="value"
                placeholder="Select country"
                class="w-full"
              />
              <label for="add-model-offset">Elevation offset (m)</label>
              <InputText
                id="add-model-offset"
                v-model="form.offset"
                type="text"
                placeholder="0"
                class="w-full"
              />
              <label for="add-model-heading">Heading (°)</label>
              <InputText
                id="add-model-heading"
                v-model="form.heading"
                type="text"
                placeholder="0"
                class="w-full"
              />
            </div>
          </div>

          <!-- Step 2: Author & submit -->
          <div v-show="currentStep === 2" class="step-panel">
            <h2 class="mt-0">Author and license</h2>
            <div class="form-grid">
              <label for="add-model-author">Author <span class="required">*</span></label>
              <Select
                id="add-model-author"
                v-model="form.authorId"
                :options="authorOptions"
                option-label="label"
                option-value="value"
                placeholder="Select author"
                class="w-full"
                @change="onAuthorChange"
              />
              <template v-if="form.authorId === '1'">
                <label for="add-model-author-name">Your name <span class="required">*</span></label>
                <InputText
                  id="add-model-author-name"
                  v-model="form.authorName"
                  maxlength="50"
                  placeholder="Full name"
                  class="w-full"
                />
                <label for="add-model-author-email">Your email <span class="required">*</span></label>
                <InputText
                  id="add-model-author-email"
                  v-model="form.authorEmail"
                  type="email"
                  maxlength="50"
                  placeholder="email@example.com"
                  class="w-full"
                />
              </template>
              <template v-if="!auth.isAuthenticated">
                <label for="add-model-contact-email" class="full-width">Your email (for this submission) <span class="required">*</span></label>
                <InputText
                  id="add-model-contact-email"
                  v-model="form.contactEmail"
                  type="email"
                  maxlength="50"
                  placeholder="email@example.com"
                  class="w-full full-width"
                />
              </template>
              <label for="add-model-comment" class="full-width">Comment (optional)</label>
              <InputText
                id="add-model-comment"
                v-model="form.comment"
                maxlength="100"
                placeholder="Note for reviewers"
                class="w-full full-width"
              />
              <div class="full-width flex align-items-center gap-2">
                <input
                  id="add-model-gpl"
                  v-model="form.gplAccepted"
                  type="checkbox"
                  class="gpl-checkbox"
                />
                <label for="add-model-gpl" class="m-0">
                  I release my contribution under the
                  <a href="https://www.gnu.org/licenses/gpl-2.0.html" target="_blank" rel="noopener noreferrer">GNU GPL v2</a>.
                </label>
              </div>
            </div>
          </div>

          <div class="step-actions mt-4">
            <Button
              v-if="currentStep > 0"
              label="Back"
              severity="secondary"
              @click="currentStep--"
            />
            <span class="flex-1" />
            <Button
              v-if="currentStep < 2"
              label="Next"
              :disabled="!canProceed"
              @click="currentStep++"
            />
            <Button
              v-else
              label="Submit model"
              :loading="submitting"
              :disabled="!canSubmit"
              @click="submit"
            />
          </div>
        </template>
      </Card>
    </template>

    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import Card from 'primevue/card'
import Message from 'primevue/message'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Button from 'primevue/button'
import ObjectMap from '@/components/ObjectMap.vue'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const stepLabels = ['Model & files', 'Location', 'Author & submit']
const currentStep = ref(0)
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()
const success = ref(false)
const successId = ref<number | null>(null)
const submitting = ref(false)

const form = ref({
  groupId: null as string | null,
  name: '',
  description: '',
  authorId: '1',
  authorName: '',
  authorEmail: '',
  contactEmail: '',
  longitude: '',
  latitude: '',
  country: null as string | null,
  offset: '0',
  heading: '0',
  comment: '',
  gplAccepted: false,
})
const ac3dFile = ref<File | null>(null)
const thumbFile = ref<File | null>(null)
const xmlFile = ref<File | null>(null)
const pngFiles = ref<File[]>([])

const modelGroups = ref<{ id: number; name: string | null; path: string | null }[]>([])
const countries = ref<{ code: string; name: string | null }[]>([])
const authors = ref<{ id: number; name: string | null }[]>([])

const ac3dFileName = computed(() => ac3dFile.value?.name ?? null)
const thumbFileName = computed(() => thumbFile.value?.name ?? null)
const xmlFileName = computed(() => xmlFile.value?.name ?? null)
const pngFileSummary = computed(() => {
  const n = pngFiles.value.length
  return n === 0 ? 'None' : n === 1 ? pngFiles.value[0].name : `${n} files`
})

const groupOptions = computed(() =>
  (modelGroups.value || []).map((g) => ({
    label: g.name || g.path || `Group ${g.id}`,
    value: String(g.id),
  }))
)
const countryOptions = computed(() =>
  (countries.value || []).map((c) => ({
    label: c.name ? `${c.name} (${c.code})` : c.code,
    value: c.code?.toLowerCase() ?? '',
  }))
)
const authorOptions = computed(() => {
  const list = (authors.value || []).map((a) => ({
    label: a.name || `Author #${a.id}`,
    value: String(a.id),
  }))
  const other = { label: 'Other (not listed)', value: '1' }
  return [...list, other]
})

const locationSelectionPosition = computed(() => {
  const lat = Number(form.value.latitude)
  const lon = Number(form.value.longitude)
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) return null
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null
  return { lat, lon }
})

const locationMapCenter = computed(() => {
  const pos = locationSelectionPosition.value
  if (pos) return [pos.lon, pos.lat]
  return [10, 53.5]
})

async function fetchCountryAtPosition(lat: number, lon: number) {
  try {
    const res = await fetch(auth.apiUrl(`/api/countries/at?lon=${encodeURIComponent(lon)}&lat=${encodeURIComponent(lat)}`), {
      credentials: 'include',
    })
    if (!res.ok) return
    const data = (await res.json()) as { country?: { code: string } | null }
    if (data.country?.code) form.value.country = data.country.code.toLowerCase()
  } catch {
    // ignore
  }
}

function onMapPositionSelect(p: { lat: number; lon: number }) {
  form.value.latitude = String(p.lat)
  form.value.longitude = String(p.lon)
  fetchCountryAtPosition(p.lat, p.lon)
}

let countryLookupDebounce: ReturnType<typeof setTimeout> | null = null
watch(
  () => [form.value.latitude, form.value.longitude],
  () => {
    const pos = locationSelectionPosition.value
    if (!pos) return
    if (countryLookupDebounce) clearTimeout(countryLookupDebounce)
    countryLookupDebounce = setTimeout(() => {
      countryLookupDebounce = null
      fetchCountryAtPosition(pos.lat, pos.lon)
    }, 400)
  }
)

const canProceed = computed(() => {
  if (currentStep.value === 0) {
    return (
      (form.value.name?.trim().length ?? 0) > 0 &&
      form.value.groupId != null &&
      ac3dFile.value != null &&
      thumbFile.value != null
    )
  }
  if (currentStep.value === 1) {
    const lon = Number(form.value.longitude)
    const lat = Number(form.value.latitude)
    return (
      Number.isFinite(lon) && lon >= -180 && lon <= 180 &&
      Number.isFinite(lat) && lat >= -90 && lat <= 90 &&
      (form.value.country?.trim().length ?? 0) > 0
    )
  }
  return true
})

const canSubmit = computed(() => {
  const hasContactEmail = auth.isAuthenticated && auth.user?.email
    ? true
    : (form.value.contactEmail?.trim().length ?? 0) > 0
  if (!form.value.gplAccepted || !hasContactEmail) return false
  if (form.value.authorId !== '1') {
    return form.value.authorId != null
  }
  return (
    (form.value.authorName?.trim().length ?? 0) > 0 &&
    (form.value.authorEmail?.trim().length ?? 0) > 0
  )
})

function onAc3dChange(e: Event) {
  const input = e.target as HTMLInputElement
  ac3dFile.value = input.files?.[0] ?? null
}
function onThumbChange(e: Event) {
  const input = e.target as HTMLInputElement
  thumbFile.value = input.files?.[0] ?? null
}
function onXmlChange(e: Event) {
  const input = e.target as HTMLInputElement
  xmlFile.value = input.files?.[0] ?? null
}
function onPngChange(e: Event) {
  const input = e.target as HTMLInputElement
  pngFiles.value = input.files ? Array.from(input.files) : []
}
function onAuthorChange() {
  if (form.value.authorId !== '1') {
    form.value.authorName = ''
    form.value.authorEmail = ''
  }
}

function applyLoggedInUserToAuthorStep() {
  const u = auth.user
  if (!u) return
  if (u.name) form.value.authorName = u.name
  if (u.email) {
    form.value.authorEmail = u.email
    form.value.contactEmail = u.email
  }
  // Match author by id, else by name (dropdown shows logged-in user when applicable)
  const matchById = authors.value.find((a) => a.id === u.id)
  const matchByName = (u.name && authors.value.find((a) => (a.name || '').trim().toLowerCase() === (u.name || '').trim().toLowerCase())) ?? null
  const match = matchById ?? matchByName
  if (match) form.value.authorId = String(match.id)
}

async function loadOptions() {
  try {
    const [groupsRes, countriesRes, authorsRes] = await Promise.all([
      fetch(auth.apiUrl('/api/modelgroups')),
      fetch(auth.apiUrl('/api/countries')),
      fetch(auth.apiUrl('/api/authors?limit=5000')),
    ])
    if (groupsRes.ok) {
      const d = await groupsRes.json()
      modelGroups.value = d.groups ?? []
      if (form.value.groupId == null && modelGroups.value.length > 0) {
        const staticGroup = modelGroups.value.find((g: { name?: string }) => g.name?.toLowerCase().includes('static'))
        form.value.groupId = staticGroup ? String(staticGroup.id) : String(modelGroups.value[0].id)
      }
    }
    if (countriesRes.ok) {
      const d = await countriesRes.json()
      countries.value = d.countries ?? []
    }
    if (authorsRes.ok) {
      const d = await authorsRes.json()
      authors.value = d.authors ?? []
    }
    applyLoggedInUserToAuthorStep()
  } catch (err) {
    console.error('Failed to load options', err)
  }
}

async function submit() {
  if (!canSubmit.value || !ac3dFile.value || !thumbFile.value) return
  clearError()
  submitting.value = true
  try {
    const fd = new FormData()
    fd.append('name', form.value.name.trim())
    fd.append('description', form.value.description.trim())
    fd.append('groupId', form.value.groupId ?? '1')
    fd.append('longitude', form.value.longitude.trim())
    fd.append('latitude', form.value.latitude.trim())
    fd.append('country', (form.value.country ?? '').trim().toLowerCase().slice(0, 2))
    fd.append('offset', form.value.offset.trim() || '0')
    fd.append('heading', form.value.heading.trim() || '0')
    fd.append('comment', form.value.comment.trim())
    fd.append('gplAccepted', form.value.gplAccepted ? 'true' : 'false')
    fd.append('authorId', form.value.authorId ?? '1')
    if (form.value.authorId === '1') {
      fd.append('authorName', form.value.authorName.trim())
      fd.append('authorEmail', form.value.authorEmail.trim())
    }
    const requestEmail = auth.user?.email ?? form.value.contactEmail.trim()
    fd.append('email', requestEmail)
    fd.append('thumbnail', thumbFile.value)
    fd.append('ac3d', ac3dFile.value)
    if (xmlFile.value) fd.append('xml', xmlFile.value)
    for (const f of pngFiles.value) fd.append('png', f)

    const res = await fetch(auth.apiUrl('/api/submissions/models/upload'), {
      method: 'POST',
      credentials: 'include',
      body: fd,
    })
    const data = await res.json().catch(() => ({}))
    if (!res.ok) {
      showError((data.error as string) || res.statusText || 'Upload failed')
      return
    }
    successId.value = data.id ?? null
    success.value = true
  } catch (err) {
    showError(err instanceof Error ? err.message : 'Upload failed')
  } finally {
    submitting.value = false
  }
}

onMounted(async () => {
  await auth.fetchUser()
  await loadOptions()
})
</script>

<style scoped>
.add-model-view {
  max-width: 42rem;
}
.stepper {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.25rem;
}
.stepper-item {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}
.stepper-num {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 1.75rem;
  height: 1.75rem;
  border-radius: 50%;
  background: var(--p-surface-200);
  color: var(--p-text-color);
  font-weight: 600;
  font-size: 0.875rem;
}
.stepper-item.active .stepper-num {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
}
.stepper-item.done .stepper-num {
  background: var(--p-surface-400);
  color: var(--p-surface-0);
}
.stepper-sep {
  width: 1.5rem;
  height: 2px;
  background: var(--p-surface-300);
  margin: 0 0.25rem;
}
.stepper-label {
  font-size: 0.875rem;
  color: var(--p-text-color-secondary);
}
.stepper-item.active .stepper-label {
  color: var(--p-text-color);
  font-weight: 600;
}
.step-panel {
  min-height: 12rem;
}
.location-map-wrap {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.location-map-hint {
  font-size: 0.875rem;
  color: var(--p-text-color-secondary);
}
.form-grid {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 0.75rem 1rem;
  align-items: center;
}
.form-grid label {
  justify-self: end;
}
.form-grid .full-width,
.form-grid label.full-width {
  grid-column: 1 / -1;
}
.form-grid label.full-width {
  justify-self: start;
}
.file-cell {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.file-cell input[type="file"] {
  font-size: 0.875rem;
}
.file-name {
  font-size: 0.875rem;
  color: var(--p-text-color-secondary);
}
.help-list {
  padding-left: 1.25rem;
  margin: 0;
}
.help-list li {
  margin-bottom: 0.25rem;
}
.help-list code {
  font-size: 0.875em;
  padding: 0.1em 0.35em;
  border-radius: 4px;
  background: var(--p-surface-100);
}
.required {
  color: var(--p-danger-color);
}
.step-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.flex-1 {
  flex: 1;
}
</style>
