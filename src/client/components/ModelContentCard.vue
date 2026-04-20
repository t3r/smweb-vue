<template>
  <Panel header="Model content" :class="{ 'model-content-card': true, 'model-content-card--compact': compact }">
    <div class="model-content-row">
      <div v-if="hasModelId" class="model-content-preview">
        <div v-if="previewLoading" class="preview-placeholder">
          <i class="pi pi-spin pi-spinner"></i> 3D…
        </div>
        <ModelViewer3d
          v-else-if="previewData"
          :preview-data="previewData"
          :width="previewWidth"
          :height="previewHeight"
        />
        <p v-else class="preview-unavailable text-color-secondary m-0">No 3D preview</p>
      </div>
      <div v-else-if="requestSig" class="model-content-preview">
        <div v-if="requestPreviewLoading" class="preview-placeholder">
          <i class="pi pi-spin pi-spinner"></i> 3D…
        </div>
        <ModelViewer3d
          v-else-if="previewData"
          :preview-data="previewData"
          :width="previewWidth"
          :height="previewHeight"
        />
        <p v-else class="preview-unavailable text-color-secondary m-0">No 3D preview</p>
      </div>
      <div v-else class="model-content-preview model-content-pending">
        <p class="m-0 text-color-secondary">Preview not available (model not yet in database)</p>
      </div>
      <div class="model-content-files">
        <template v-if="hasModelId || requestSig">
          <p v-if="requestSig && filename" class="m-0 mb-2 text-color-secondary">
            Submitted filename: {{ filename }}
          </p>
          <p v-if="packageDownloadUrl !== '#'" class="m-0 mb-2">
            <a :href="packageDownloadUrl" class="download-link" download>
              <i class="pi pi-download"></i>
              {{ hasModelId ? 'Download model package (.tar.gz)' : 'Download submission package (.tar.gz)' }}
            </a>
          </p>
          <p v-if="filesLoading" class="m-0">Loading file list…</p>
          <DataTable
            v-else
            :value="modelFiles"
            data-key="name"
            responsive-layout="scroll"
            class="p-datatable-sm"
          >
            <Column field="name" header="Filename">
              <template #body="{ data }">
                <TextureFilenameCell
                  :name="data.name"
                  :href="fileDownloadUrl(data.name)"
                  :is-texture="isRasterTextureFilename(data.name)"
                  :dimensions="textureDimsByName[data.name]"
                />
              </template>
            </Column>
            <Column header="Dimensions">
              <template #body="{ data }">
                <span v-if="!isRasterTextureFilename(data.name)" class="text-color-secondary">—</span>
                <span v-else-if="!(data.name in textureDimsByName)" class="text-color-secondary">…</span>
                <span v-else>{{ formatTextureDimensions(textureDimsByName[data.name] ?? null) }}</span>
              </template>
            </Column>
            <Column field="size" header="Size">
              <template #body="{ data }">{{ formatBytes(data.size) }}</template>
            </Column>
            <template #empty>
              <p class="m-0 text-color-secondary">No file list available for this model.</p>
            </template>
          </DataTable>
        </template>
        <template v-else>
          <p v-if="filename" class="m-0 mb-2">Filename: {{ filename }}</p>
          <p class="m-0 text-color-secondary">Model files are part of the submission.</p>
        </template>
      </div>
    </div>
  </Panel>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import Panel from 'primevue/panel'
import ModelViewer3d from '@/components/ModelViewer3d.vue'
import TextureFilenameCell from '@/components/TextureFilenameCell.vue'
import { useAuthStore } from '@/stores/auth'
import {
  isRasterTextureFilename,
  probeRasterImageDimensions,
  formatTextureDimensions,
} from '@/utils/textureFileMeta'

const auth = useAuthStore()

const props = withDefaults(
  defineProps<{
    modelId?: number | null
    /** When set (e.g. MODEL_ADD position request sig), lazy-load preview from request package */
    requestSig?: string | null
    filename?: string | null
    compact?: boolean
  }>(),
  { modelId: null, requestSig: null, filename: null, compact: false }
)

const modelFiles = ref<{ name: string; size?: number }[]>([])
const filesLoading = ref(false)
/** Raster texture filenames → decoded pixel size, or `null` if probe failed */
const textureDimsByName = ref<Record<string, { width: number; height: number } | null>>({})
const previewData = ref<unknown>(null)
const previewLoading = ref(false)
const requestPreviewLoading = ref(false)

const hasModelId = computed(() => props.modelId != null && Number.isFinite(Number(props.modelId)))

const previewWidth = computed(() => (props.compact ? 180 : 240))
const previewHeight = computed(() => (props.compact ? 135 : 180))

const packageDownloadUrl = computed(() => {
  if (hasModelId.value && props.modelId != null) {
    return auth.apiUrl(`/api/models/${props.modelId}/package`)
  }
  if (props.requestSig) {
    return auth.apiUrl(`/api/position-requests/${encodeURIComponent(props.requestSig)}/package`)
  }
  return '#'
})

function fileDownloadUrl(name: string) {
  if (!name) return '#'
  const q = `?name=${encodeURIComponent(name)}`
  if (hasModelId.value && props.modelId != null) {
    return auth.apiUrl(`/api/models/${props.modelId}/file${q}`)
  }
  if (props.requestSig) {
    return auth.apiUrl(`/api/position-requests/${encodeURIComponent(props.requestSig)}/file${q}`)
  }
  return '#'
}

let textureDimGeneration = 0

function formatBytes(bytes: unknown) {
  if (bytes == null || !Number.isFinite(Number(bytes)) || Number(bytes) < 0) return '—'
  const b = Number(bytes)
  if (b === 0) return '0 B'
  const k = 1024
  const i = Math.floor(Math.log(b) / Math.log(k))
  const v = b / k ** i
  const unit = ['B', 'KB', 'MB', 'GB'][i] || 'B'
  return `${v.toFixed(i > 1 ? 1 : 0)} ${unit}`
}

async function fetchFiles() {
  const id = props.modelId
  if (id == null) return
  filesLoading.value = true
  modelFiles.value = []
  try {
    const res = await fetch(auth.apiUrl(`/api/models/${id}/files`), { credentials: 'include' })
    if (res.ok) {
      const data = await res.json()
      modelFiles.value = data.files || []
    }
  } catch {
    modelFiles.value = []
  } finally {
    filesLoading.value = false
  }
}

async function fetchPreview() {
  const id = props.modelId
  if (id == null) return
  previewData.value = null
  previewLoading.value = true
  try {
    const res = await fetch(auth.apiUrl(`/api/models/${id}/preview`), { credentials: 'include' })
    if (res.ok) {
      const data = await res.json()
      previewData.value = data
    }
  } catch {
    previewData.value = null
  } finally {
    previewLoading.value = false
  }
}

async function fetchRequestPreview() {
  const sig = props.requestSig
  if (!sig || typeof sig !== 'string') return
  previewData.value = null
  requestPreviewLoading.value = true
  try {
    const res = await fetch(auth.apiUrl(`/api/position-requests/${encodeURIComponent(sig)}/model-preview`), {
      credentials: 'include',
    })
    if (res.ok) {
      const data = await res.json()
      previewData.value = data
    }
  } catch {
    previewData.value = null
  } finally {
    requestPreviewLoading.value = false
  }
}

async function fetchRequestFiles() {
  const sig = props.requestSig
  if (!sig || typeof sig !== 'string') return
  filesLoading.value = true
  modelFiles.value = []
  try {
    const res = await fetch(auth.apiUrl(`/api/position-requests/${encodeURIComponent(sig)}/model-files`), {
      credentials: 'include',
    })
    if (res.ok) {
      const data = await res.json()
      modelFiles.value = data.files || []
    }
  } catch {
    modelFiles.value = []
  } finally {
    filesLoading.value = false
  }
}

function loadContent() {
  if (hasModelId.value) {
    fetchFiles()
    fetchPreview()
    return
  }
  if (props.requestSig) {
    fetchRequestPreview()
    fetchRequestFiles()
  }
}

onMounted(loadContent)
watch(
  modelFiles,
  (files) => {
    textureDimGeneration++
    const gen = textureDimGeneration
    textureDimsByName.value = {}
    for (const f of files) {
      if (!isRasterTextureFilename(f.name)) continue
      const name = f.name
      const url = fileDownloadUrl(name)
      void probeRasterImageDimensions(url).then((dims) => {
        if (gen !== textureDimGeneration) return
        textureDimsByName.value = { ...textureDimsByName.value, [name]: dims }
      })
    }
  },
  { deep: true }
)

watch(() => [props.modelId, props.requestSig], loadContent)
</script>

<style scoped>
.model-content-row {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
}
.model-content-preview {
  flex-shrink: 0;
}
.model-content-files {
  flex: 1;
  min-width: 0;
}
.model-content-pending {
  min-width: 180px;
  padding: 0.5rem 0;
  font-size: 0.875rem;
}
.preview-placeholder {
  border-radius: 6px;
  background: var(--p-surface-100, #f1f5f9);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.875rem;
}
.model-content-card .preview-placeholder {
  width: 240px;
  height: 180px;
}
.model-content-card--compact .preview-placeholder {
  width: 180px;
  height: 135px;
}
.preview-unavailable {
  padding: 0.5rem 0;
  font-size: 0.875rem;
}
.model-content-card .preview-unavailable {
  width: 240px;
}
.model-content-card--compact .preview-unavailable {
  width: 180px;
}
.m-0 { margin: 0; }
.mb-2 { margin-bottom: 0.5rem; }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
.download-link, .file-link { color: var(--p-primary-color); text-decoration: none; }
.download-link:hover, .file-link:hover { text-decoration: underline; }
</style>
