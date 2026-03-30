<template>
  <Panel class="add-placements-panel" header="Add object placements">
    <p class="text-secondary mt-0 mb-3">
      Click the map to add positions (shared models only). Set <strong>heading</strong> (true degrees, 0–360) and
      <strong>elevation offset</strong> (metres) per row. You can also paste multiple lines:
      <code>lon lat [heading] [offset_m]</code> (whitespace or comma separated).
    </p>

    <Message v-if="error" severity="error" class="mb-3" :closable="false">{{ error }}</Message>
    <Message v-else-if="successMessage" severity="success" class="mb-3" :closable="true" @close="successMessage = ''">
      {{ successMessage }}
    </Message>

    <div class="map-wrap mb-4">
      <ObjectMap
        :objects="mapDraftObjects"
        :initial-center="mapCenter"
        :initial-zoom="mapZoom"
        selection-mode
        :selection-position="selectionPosition"
        :selection-skip-when-feature-hit="true"
        @position-select="onMapClick"
      />
      <p class="text-secondary text-sm mt-2 mb-0">Crosshair: click the map to add a placement (only new positions are shown).</p>
    </div>

    <div class="form-grid mb-4">
      <template v-if="needsGuestEmail">
        <label for="add-obj-email">Email <span class="req">*</span></label>
        <InputText id="add-obj-email" v-model="email" type="email" class="w-full" maxlength="50" />
      </template>
      <label for="add-obj-comment">Comment <span class="req">*</span></label>
      <InputText
        id="add-obj-comment"
        v-model="comment"
        class="w-full"
        maxlength="100"
        placeholder="Why you are adding these positions (max 100 chars, no | )"
      />
    </div>

    <h3 class="section-title">Pending placements</h3>
    <p v-if="drafts.length === 0" class="text-secondary">None yet — use the map or paste a list below.</p>
    <div v-else class="drafts-table-wrap mb-4">
      <DataTable :value="drafts" data-key="key" responsive-layout="scroll">
        <Column header="#" style="width: 2.5rem">
          <template #body="{ index }">{{ index + 1 }}</template>
        </Column>
        <Column field="lon" header="Lon">
          <template #body="{ data }">
            <InputNumber v-model="data.lon" :min-fraction-digits="3" :max-fraction-digits="8" class="w-full" @blur="onDraftCoordsBlur(data)" />
          </template>
        </Column>
        <Column field="lat" header="Lat">
          <template #body="{ data }">
            <InputNumber v-model="data.lat" :min-fraction-digits="3" :max-fraction-digits="8" class="w-full" @blur="onDraftCoordsBlur(data)" />
          </template>
        </Column>
        <Column field="heading" header="Heading °">
          <template #body="{ data }">
            <InputNumber v-model="data.heading" :min="0" :max="360" class="w-full" />
          </template>
        </Column>
        <Column field="offset" header="Elev offset (m)">
          <template #body="{ data }">
            <InputNumber v-model="data.offset" class="w-full" />
          </template>
        </Column>
        <Column header="Country" style="width: 5rem">
          <template #body="{ data }">
            <span v-if="data.countryLoading" class="text-secondary">…</span>
            <span v-else :title="!data.country ? 'No land polygon (e.g. ocean); stored as unset' : ''">
              {{ data.country || '—' }}
            </span>
          </template>
        </Column>
        <Column style="width: 4rem">
          <template #body="{ data }">
            <Button icon="pi pi-trash" severity="danger" text rounded @click="removeDraft(data.key)" />
          </template>
        </Column>
      </DataTable>
    </div>

    <h3 class="section-title">Paste list</h3>
    <Textarea v-model="pasteText" rows="5" class="w-full paste-area mb-2" placeholder="12.34 55.67 90 0&#10;12.35 55.68" />
    <Button label="Append lines to pending" severity="secondary" class="mb-4" :disabled="!pasteText.trim()" @click="appendFromPaste" />

    <div class="flex gap-2 flex-wrap">
      <Button label="Submit for review" icon="pi pi-send" :loading="submitting" :disabled="!canSubmit" @click="submit" />
      <Button label="Clear pending" severity="secondary" text :disabled="drafts.length === 0" @click="clearDrafts" />
    </div>
  </Panel>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import Panel from 'primevue/panel'
import Button from 'primevue/button'
import Message from 'primevue/message'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputNumber from 'primevue/inputnumber'
import ObjectMap from '@/components/ObjectMap.vue'

/** Minimal shape for ObjectMap markers (pending placements only). */
interface DraftMapMarker {
  id: number
  description?: string | null
  type?: string | null
  shared?: number | null
  position?: { lat?: number; lon?: number; heading?: number }
  country?: string | null
}

const props = defineProps<{
  modelId: number
  modelName: string
  mapCenter: [number, number]
}>()

const emit = defineEmits<{
  submitted: []
}>()

const auth = useAuthStore()

interface Draft {
  key: string
  lat: number
  lon: number
  heading: number
  offset: number
  country: string | null
  countryLoading: boolean
}

const drafts = ref<Draft[]>([])
const pasteText = ref('')
const comment = ref('')
const email = ref('')
const error = ref('')
const successMessage = ref('')
const submitting = ref(false)
const selectionPosition = ref<{ lat: number; lon: number } | null>(null)

let keySeq = 0
function newKey() {
  keySeq += 1
  return `d-${keySeq}-${Date.now()}`
}

const needsGuestEmail = computed(
  () => !auth.isAuthenticated || !(auth.user?.email && String(auth.user.email).trim())
)

const mapZoom = computed(() => {
  const [lng, lat] = props.mapCenter
  const isDefault = Math.abs(lng - 10) < 0.01 && Math.abs(lat - 53.5) < 0.01
  return isDefault ? 6 : 8
})

const mapDraftObjects = computed((): DraftMapMarker[] =>
  drafts.value.map((d, i) => ({
    id: -(i + 1),
    description: 'New (pending)',
    type: null,
    shared: 1,
    position: {
      lat: d.lat,
      lon: d.lon,
      heading: d.heading != null && Number.isFinite(Number(d.heading)) ? Number(d.heading) : 0,
    },
    country: null,
  }))
)

const canSubmit = computed(() => {
  if (drafts.value.length === 0) return false
  if (!comment.value.trim() || comment.value.length > 100 || comment.value.includes('|')) return false
  if (needsGuestEmail.value) {
    const e = email.value.trim()
    if (!e || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e)) return false
  }
  return drafts.value.every(
    (d) =>
      Number.isFinite(d.lat) &&
      Number.isFinite(d.lon) &&
      d.lat >= -90 &&
      d.lat <= 90 &&
      d.lon >= -180 &&
      d.lon <= 180
  )
})

async function fetchCountry(lat: number, lon: number): Promise<string | null> {
  try {
    const res = await fetch(
      auth.apiUrl(`/api/countries/at?lon=${encodeURIComponent(lon)}&lat=${encodeURIComponent(lat)}`),
      { credentials: 'include' }
    )
    if (!res.ok) return null
    const data = (await res.json()) as { country?: { code?: string } | null }
    const c = data.country?.code?.trim().toLowerCase().slice(0, 2)
    return c || null
  } catch {
    return null
  }
}

async function hydrateCountry(d: Draft) {
  d.countryLoading = true
  d.country = await fetchCountry(d.lat, d.lon)
  d.countryLoading = false
}

function onMapClick(p: { lat: number; lon: number }) {
  error.value = ''
  successMessage.value = ''
  selectionPosition.value = { lat: p.lat, lon: p.lon }
  const d: Draft = {
    key: newKey(),
    lat: p.lat,
    lon: p.lon,
    heading: 0,
    offset: 0,
    country: null,
    countryLoading: true,
  }
  drafts.value = [...drafts.value, d]
  void hydrateCountry(d)
}

function onDraftCoordsBlur(d: Draft) {
  d.country = null
  d.countryLoading = true
  void hydrateCountry(d)
}

function removeDraft(key: string) {
  drafts.value = drafts.value.filter((x) => x.key !== key)
}

function clearDrafts() {
  drafts.value = []
  pasteText.value = ''
  selectionPosition.value = null
}

function parsePasteLines(text: string): { lat: number; lon: number; heading: number; offset: number }[] {
  const out: { lat: number; lon: number; heading: number; offset: number }[] = []
  for (const line of text.split('\n')) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith('#')) continue
    const parts = trimmed.split(/[\s,;]+/).filter(Boolean)
    if (parts.length < 2) continue
    const lon = Number(parts[0])
    const lat = Number(parts[1])
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) continue
    let heading = parts.length >= 3 ? Number(parts[2]) : 0
    let offset = parts.length >= 4 ? Number(parts[3]) : 0
    if (!Number.isFinite(heading)) heading = 0
    if (!Number.isFinite(offset)) offset = 0
    out.push({ lat, lon, heading, offset })
  }
  return out
}

function appendFromPaste() {
  error.value = ''
  const parsed = parsePasteLines(pasteText.value)
  if (parsed.length === 0) {
    error.value = 'No valid lines. Use: lon lat [heading] [offset_m]'
    return
  }
  const next = [...drafts.value]
  let lastPos: { lat: number; lon: number } | null = null
  for (const p of parsed) {
    const d: Draft = {
      key: newKey(),
      lat: p.lat,
      lon: p.lon,
      heading: p.heading,
      offset: p.offset,
      country: null,
      countryLoading: true,
    }
    next.push(d)
    lastPos = { lat: p.lat, lon: p.lon }
    void hydrateCountry(d)
  }
  drafts.value = next
  if (lastPos) selectionPosition.value = lastPos
}

async function submit() {
  error.value = ''
  successMessage.value = ''
  if (!canSubmit.value) return
  submitting.value = true
  try {
    for (const d of drafts.value) {
      if (d.countryLoading) await hydrateCountry(d)
    }
    const desc = props.modelName.trim().slice(0, 100)
    const payload: Record<string, unknown> = {
      comment: comment.value.trim(),
      objects: drafts.value.map((d) => ({
        modelId: props.modelId,
        lat: d.lat,
        lon: d.lon,
        country: d.country,
        elevationOffset: d.offset,
        heading: d.heading,
        description: desc,
      })),
    }
    if (needsGuestEmail.value) payload.email = email.value.trim()

    const res = await fetch(auth.apiUrl('/api/submissions/objects'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify(payload),
    })
    const data = (await res.json().catch(() => ({}))) as { error?: string; message?: string; id?: number }
    if (!res.ok) {
      error.value = data.error || 'Submit failed'
      return
    }
    successMessage.value = data.message || `Queued for review (request #${data.id ?? '?'})`
    clearDrafts()
    comment.value = ''
    emit('submitted')
  } catch (e) {
    error.value = (e as Error).message || 'Network error'
  } finally {
    submitting.value = false
  }
}

watch(needsGuestEmail, () => {
  if (!needsGuestEmail.value) email.value = ''
})
</script>

<style scoped>
.add-placements-panel {
  margin-top: 1rem;
}
.map-wrap {
  width: 100%;
}
.text-secondary {
  color: var(--p-text-muted-color);
  font-size: 0.875rem;
}
.text-sm {
  font-size: 0.8125rem;
}
.section-title {
  margin: 0 0 0.5rem 0;
  font-size: 1rem;
  font-weight: 600;
}
.form-grid {
  display: grid;
  grid-template-columns: minmax(6rem, 10rem) 1fr;
  gap: 0.5rem 1rem;
  align-items: center;
}
@media (max-width: 520px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
}
.req {
  color: var(--p-red-500);
}
.w-full {
  width: 100%;
}
.paste-area {
  font-family: ui-monospace, monospace;
  font-size: 0.8125rem;
}
.drafts-table-wrap :deep(.p-inputnumber) {
  width: 100%;
}
.flex {
  display: flex;
}
.gap-2 {
  gap: 0.5rem;
}
.flex-wrap {
  flex-wrap: wrap;
}
.mb-2 {
  margin-bottom: 0.5rem;
}
.mb-3 {
  margin-bottom: 0.75rem;
}
.mb-4 {
  margin-bottom: 1rem;
}
.mt-0 {
  margin-top: 0;
}
.mt-2 {
  margin-top: 0.5rem;
}
</style>
