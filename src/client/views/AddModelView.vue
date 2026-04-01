<template>
  <div class="add-model-view">
    <h1 class="mt-0">Add a model</h1>
    <p class="text-color-secondary mt-0 intro-lead">
      Submit a static or shared 3D model to the FlightGear scenery database. Fill in the sections below, then submit for review.
    </p>

    <Message v-if="success" severity="success" class="mb-3" :closable="false">
      Your model has been queued for review (request #{{ successId }}). A reviewer will process it shortly.
      <router-link to="/models">Back to models</router-link>
    </Message>

    <template v-if="!success">
      <Card>
        <template #content>
          <div class="add-form-shell">
            <div class="add-form-columns">
              <!-- Left: model + files -->
              <div class="add-form-col add-form-col--main">
                <section class="form-section" aria-labelledby="add-model-section-model">
                  <h2 id="add-model-section-model" class="form-section-title">Model</h2>
                  <div class="field-pair">
                    <div class="field">
                      <label for="add-model-group" class="field-label">Model family <span class="required">*</span></label>
                      <Select
                        id="add-model-group"
                        v-model="form.groupId"
                        :options="groupOptions"
                        option-label="label"
                        option-value="value"
                        placeholder="Select family"
                        class="w-full"
                      />
                    </div>
                    <div class="field">
                      <label for="add-model-name" class="field-label">Model name <span class="required">*</span></label>
                      <InputText
                        id="add-model-name"
                        v-model="form.name"
                        maxlength="100"
                        placeholder="e.g. Cornet antenna radome - Brittany - France"
                        class="w-full"
                      />
                    </div>
                  </div>
                  <div class="field mt-field">
                    <label for="add-model-desc" class="field-label">Description</label>
                    <InputText
                      id="add-model-desc"
                      v-model="form.description"
                      maxlength="100"
                      placeholder="Optional details about the model"
                      class="w-full"
                    />
                  </div>
                </section>

                <section class="form-section" aria-labelledby="add-model-section-files">
                  <h2 id="add-model-section-files" class="form-section-title">Files</h2>
                  <ul class="help-list-compact">
                    <li>Same base name for <code>.ac</code> / <code>.xml</code> / <code>.png</code> files.</li>
                    <li>PNG dimensions must be powers of 2. Thumbnail becomes 320×240 JPEG.</li>
                  </ul>
                  <div class="field-pair">
                    <div class="field">
                      <label for="add-model-ac3d" class="field-label">AC3D <span class="required">*</span></label>
                      <div class="file-cell">
                        <input id="add-model-ac3d" type="file" accept=".ac" @change="onAc3dChange" />
                        <span class="file-name">{{ ac3dFileName || 'No file chosen' }}</span>
                      </div>
                    </div>
                    <div class="field">
                      <label for="add-model-thumb" class="field-label">Thumbnail <span class="required">*</span></label>
                      <div class="file-cell">
                        <input id="add-model-thumb" type="file" accept="image/*" @change="onThumbChange" />
                        <span class="file-name">{{ thumbFileName || 'No file chosen' }}</span>
                      </div>
                    </div>
                  </div>
                  <div class="field-pair mt-field">
                    <div class="field">
                      <label for="add-model-xml" class="field-label">XML (optional)</label>
                      <div class="file-cell">
                        <input
                          id="add-model-xml"
                          type="file"
                          accept=".xml,text/xml,application/xml"
                          @change="onXmlChange"
                        />
                        <span class="file-name">{{ xmlFileName || 'None' }}</span>
                      </div>
                    </div>
                    <div class="field">
                      <label for="add-model-png" class="field-label">PNG texture(s)</label>
                      <div class="file-cell">
                        <input id="add-model-png" type="file" accept=".png,image/png" multiple @change="onPngChange" />
                        <span class="file-name">{{ pngFileSummary }}</span>
                      </div>
                    </div>
                  </div>
                </section>
              </div>

              <!-- Right: map + position -->
              <div class="add-form-col add-form-col--map">
                <section class="form-section" aria-labelledby="add-model-section-location">
                  <h2 id="add-model-section-location" class="form-section-title">Location</h2>
                  <p class="section-hint">Click the map or enter coordinates. Country is set from the database when you submit.</p>
                  <div class="map-box">
                    <ObjectMap
                      :selection-mode="true"
                      :selection-position="locationSelectionPosition"
                      :initial-center="locationMapCenter"
                      :initial-zoom="10"
                      compact
                      :show-airport-icao-search="true"
                      :airport-lookup-base-path="auth.apiUrl('/api/airports/by-icao')"
                      @position-select="onMapPositionSelect"
                    />
                    <span class="map-hint">Click on the map to place the marker</span>
                  </div>
                  <div class="field-pair mt-field">
                    <div class="field">
                      <label for="add-model-lon" class="field-label">Longitude <span class="required">*</span></label>
                      <InputText
                        id="add-model-lon"
                        v-model="form.longitude"
                        type="text"
                        placeholder="-180 … 180"
                        class="w-full"
                      />
                    </div>
                    <div class="field">
                      <label for="add-model-lat" class="field-label">Latitude <span class="required">*</span></label>
                      <InputText
                        id="add-model-lat"
                        v-model="form.latitude"
                        type="text"
                        placeholder="-90 … 90"
                        class="w-full"
                      />
                    </div>
                  </div>
                  <div class="field-pair mt-field">
                    <div class="field">
                      <label for="add-model-offset" class="field-label">Elevation offset (m)</label>
                      <InputText id="add-model-offset" v-model="form.offset" type="text" placeholder="0" class="w-full" />
                    </div>
                    <div class="field">
                      <label for="add-model-heading" class="field-label">Heading (°)</label>
                      <InputText id="add-model-heading" v-model="form.heading" type="text" placeholder="0" class="w-full" />
                    </div>
                  </div>
                </section>
              </div>
            </div>

            <!-- Full width: author & license -->
            <section class="form-section form-section--footer" aria-labelledby="add-model-section-author">
              <h2 id="add-model-section-author" class="form-section-title">Author &amp; license</h2>
              <div class="footer-inner">
                <div class="footer-primary">
                  <div class="field-pair">
                    <div class="field">
                      <label for="add-model-author" class="field-label">Author <span class="required">*</span></label>
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
                    </div>
                    <div v-if="form.authorId === '1'" class="field">
                      <label for="add-model-author-name" class="field-label">Your name <span class="required">*</span></label>
                      <InputText
                        id="add-model-author-name"
                        v-model="form.authorName"
                        maxlength="50"
                        placeholder="Full name"
                        class="w-full"
                      />
                    </div>
                    <div v-else-if="!auth.isAuthenticated" class="field">
                      <label for="add-model-contact-email" class="field-label">Contact email <span class="required">*</span></label>
                      <InputText
                        id="add-model-contact-email"
                        v-model="form.contactEmail"
                        type="email"
                        maxlength="50"
                        placeholder="email@example.com"
                        class="w-full"
                      />
                    </div>
                    <div v-else class="field field--spacer" aria-hidden="true" />
                  </div>
                  <div v-if="form.authorId === '1'" class="field-pair mt-field">
                    <div class="field">
                      <label for="add-model-author-email" class="field-label">Your email <span class="required">*</span></label>
                      <InputText
                        id="add-model-author-email"
                        v-model="form.authorEmail"
                        type="email"
                        maxlength="50"
                        placeholder="email@example.com"
                        class="w-full"
                      />
                    </div>
                    <div v-if="!auth.isAuthenticated" class="field">
                      <label for="add-model-contact-email-row2" class="field-label">Contact email <span class="required">*</span></label>
                      <InputText
                        id="add-model-contact-email-row2"
                        v-model="form.contactEmail"
                        type="email"
                        maxlength="50"
                        placeholder="For follow-up on this submission"
                        class="w-full"
                      />
                    </div>
                    <div v-else class="field field--spacer" aria-hidden="true" />
                  </div>
                </div>
                <div class="footer-secondary">
                  <div class="field">
                    <label for="add-model-comment" class="field-label">Comment (optional)</label>
                    <InputText
                      id="add-model-comment"
                      v-model="form.comment"
                      maxlength="100"
                      placeholder="Note for reviewers"
                      class="w-full"
                    />
                  </div>
                  <div class="gpl-row">
                    <input id="add-model-gpl" v-model="form.gplAccepted" type="checkbox" class="gpl-checkbox" />
                    <label for="add-model-gpl" class="gpl-label m-0">
                      I release my contribution under the
                      <a href="https://www.gnu.org/licenses/gpl-2.0.html" target="_blank" rel="noopener noreferrer">GNU GPL v2</a>.
                    </label>
                  </div>
                </div>
              </div>
            </section>

            <div class="submit-bar">
              <Button label="Submit model" :loading="submitting" :disabled="!canSubmit" @click="submit" />
            </div>
          </div>
        </template>
      </Card>
    </template>

    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
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

function onMapPositionSelect(p: { lat: number; lon: number }) {
  form.value.latitude = String(p.lat)
  form.value.longitude = String(p.lon)
}

const canSubmit = computed(() => {
  if (
    (form.value.name?.trim().length ?? 0) === 0 ||
    form.value.groupId == null ||
    ac3dFile.value == null ||
    thumbFile.value == null
  ) {
    return false
  }
  const lon = Number(form.value.longitude)
  const lat = Number(form.value.latitude)
  if (
    !Number.isFinite(lon) ||
    lon < -180 ||
    lon > 180 ||
    !Number.isFinite(lat) ||
    lat < -90 ||
    lat > 90
  ) {
    return false
  }
  const hasContactEmail =
    auth.isAuthenticated && auth.user?.email ? true : (form.value.contactEmail?.trim().length ?? 0) > 0
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
  const matchById = authors.value.find((a) => a.id === u.id)
  const matchByName =
    (u.name &&
      authors.value.find((a) => (a.name || '').trim().toLowerCase() === (u.name || '').trim().toLowerCase())) ??
    null
  const match = matchById ?? matchByName
  if (match) form.value.authorId = String(match.id)
}

async function loadOptions() {
  try {
    const [groupsRes, authorsRes] = await Promise.all([
      fetch(auth.apiUrl('/api/modelgroups')),
      fetch(auth.apiUrl('/api/authors?limit=5000')),
    ])
    if (groupsRes.ok) {
      const d = await groupsRes.json()
      modelGroups.value = d.groups ?? []
      if (form.value.groupId == null && modelGroups.value.length > 0) {
        const staticGroup = modelGroups.value.find((g: { name?: string }) =>
          g.name?.toLowerCase().includes('static')
        )
        form.value.groupId = staticGroup ? String(staticGroup.id) : String(modelGroups.value[0].id)
      }
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
  max-width: min(112rem, 100%);
  margin-inline: auto;
  padding-inline: clamp(0.5rem, 2vw, 1rem);
}
.intro-lead {
  margin-bottom: 1.25rem;
  max-width: 50rem;
}
.add-form-shell {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}
.add-form-columns {
  display: grid;
  gap: 1.5rem;
  align-items: start;
}
@media (min-width: 960px) {
  .add-form-columns {
    grid-template-columns: 1fr minmax(18rem, 42%);
  }
}
.add-form-col--main {
  min-width: 0;
}
.add-form-col--map {
  min-width: 0;
}
.form-section {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.form-section-title {
  margin: 0;
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--p-text-color);
  padding-bottom: 0.25rem;
  border-bottom: 1px solid var(--p-surface-200);
}
.section-hint {
  margin: -0.25rem 0 0;
  font-size: 0.875rem;
  color: var(--p-text-color-secondary);
}
.field-pair {
  display: grid;
  gap: 0.75rem 1rem;
  align-items: start;
}
@media (min-width: 640px) {
  .field-pair {
    grid-template-columns: 1fr 1fr;
  }
}
.field {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  min-width: 0;
}
.field--spacer {
  visibility: hidden;
  min-height: 0;
}
.field-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--p-text-color-secondary);
}
.mt-field {
  margin-top: 0.25rem;
}
.map-box {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  border-radius: var(--p-border-radius, 6px);
  overflow: hidden;
  border: 1px solid var(--p-surface-200);
  min-height: 220px;
}
@media (min-width: 960px) {
  .map-box {
    min-height: min(340px, 42vh);
  }
}
.map-hint {
  font-size: 0.8125rem;
  color: var(--p-text-color-secondary);
  padding: 0 0.5rem 0.5rem;
}
.help-list-compact {
  margin: 0 0 0.5rem;
  padding-left: 1.15rem;
  font-size: 0.8125rem;
  color: var(--p-text-color-secondary);
}
.help-list-compact li {
  margin-bottom: 0.2rem;
}
.help-list-compact code {
  font-size: 0.85em;
  padding: 0.08em 0.3em;
  border-radius: 4px;
  background: var(--p-surface-200);
}
.file-cell {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.file-cell input[type='file'] {
  font-size: 0.8125rem;
  max-width: 100%;
}
.file-name {
  font-size: 0.8125rem;
  color: var(--p-text-color-secondary);
  word-break: break-all;
}
.form-section--footer .footer-inner {
  display: grid;
  gap: 1.25rem;
}
@media (min-width: 900px) {
  .form-section--footer .footer-inner {
    grid-template-columns: 1fr minmax(14rem, 34%);
    align-items: start;
  }
}
.footer-primary {
  min-width: 0;
}
.footer-secondary {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}
.gpl-row {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
}
.gpl-checkbox {
  margin-top: 0.2rem;
  flex-shrink: 0;
}
.gpl-label {
  font-size: 0.875rem;
  line-height: 1.45;
}
.submit-bar {
  display: flex;
  justify-content: flex-end;
  padding-top: 0.25rem;
  border-top: 1px solid var(--p-surface-200);
}
.required {
  color: var(--p-danger-color);
}
</style>
