<template>
  <div>
    <p v-if="loading" class="m-0">Loading…</p>
    <template v-else-if="author">
      <Breadcrumb :model="breadcrumbItems" class="mb-3">
        <template #item="{ item }">
          <router-link v-if="item.to" :to="item.to" class="p-breadcrumb-link">{{ item.label }}</router-link>
          <span v-else>{{ item.label }}</span>
        </template>
      </Breadcrumb>

      <h1 class="mt-0">
        <span class="author-title-row inline-flex align-items-center flex-wrap gap-2">
          <span>{{ author.name || `Author #${author.id}` }}</span>
        </span>
      </h1>

      <Panel header="Details" class="mb-3">
        <div class="detail-grid">
          <span class="detail-label">ID</span>
          <span>#{{ author.id }}</span>
          <span class="detail-label">Name</span>
          <span class="inline-flex align-items-center flex-wrap gap-1">
            <span>{{ author.name || '—' }}</span>
            <AuthorIdentityProviderBadge :linked="Boolean(author.linkedIdentityProvider)" />
          </span>
          <template v-if="author.email != null">
            <span class="detail-label">Email</span>
            <span>{{ author.email || '—' }}</span>
          </template>
          <span class="detail-label">Description</span>
          <div v-if="isOwnProfile" class="detail-desc-cell">
            <div class="desc-input-row">
              <InputText
                id="author-desc-input"
                v-model="descriptionDraft"
                class="desc-input"
                maxlength="128"
                placeholder="Short description (max 128 characters)"
              />
              <Button
                label="Save description"
                size="small"
                :loading="descriptionSaving"
                :disabled="descriptionSaving"
                @click="saveDescription"
              />
            </div>
            <div class="desc-meta">
              <span class="char-count">{{ descriptionDraft.length }} / 128</span>
              <span v-if="descriptionSaveStatus" class="desc-save-status">{{ descriptionSaveStatus }}</span>
            </div>
          </div>
          <span v-else-if="publicAuthorBlurb" class="detail-description-readonly">{{ publicAuthorBlurb }}</span>
          <span v-else class="text-placeholder">—</span>
          <template v-if="author.lastLogin">
            <span class="detail-label">Last login</span>
            <span>{{ formatLastLogin(author.lastLogin) }}</span>
          </template>
          <template v-if="author.role != null">
            <span class="detail-label">Role</span>
            <span v-if="!isAdmin">{{ roleLabel(author.role) }}</span>
            <span v-else class="role-edit">
              <Select
                v-model="selectedRole"
                :options="roleOptions"
                option-label="label"
                option-value="value"
                class="w-10rem"
                @change="onRoleChange"
              />
              <span v-if="roleSaveStatus" class="role-save-status ml-2">{{ roleSaveStatus }}</span>
            </span>
          </template>
        </div>
      </Panel>

      <Panel class="mb-3">
        <template #header>
          <div class="recent-models-panel-header flex flex-wrap align-items-baseline gap-2">
            <span class="recent-models-head-title">Recent models</span>
            <template v-if="author.modelsCount != null">
              <span class="text-color-secondary">-</span>
              <router-link :to="modelsByAuthorLink" class="recent-models-show-all">
                show all {{ author.modelsCount }}
                {{ author.modelsCount === 1 ? 'model' : 'models' }}
              </router-link>
            </template>
          </div>
        </template>
        <p v-if="recentModelsLoading" class="m-0">Loading…</p>
        <p v-else-if="recentModelsError" class="m-0 text-color-secondary">{{ recentModelsError }}</p>
        <p v-else-if="!recentModels.length" class="m-0 text-color-secondary">No models for this author yet.</p>
        <ul v-else class="recent-models-list list-none p-0 m-0">
          <li
            v-for="m in recentModels"
            :key="m.id"
            class="recent-model-row flex gap-3 py-3 border-bottom-1 surface-border align-items-start"
          >
            <router-link :to="`/models/${m.id}`" class="recent-model-thumb-link flex-shrink-0">
              <img
                :src="modelThumbnailUrl(m.id)"
                :alt="modelDisplayName(m)"
                class="recent-model-thumb"
                @error="onModelThumbError"
              />
            </router-link>
            <div class="recent-model-body min-w-0 flex-1">
              <div class="recent-model-desc text-break">
                {{ modelDescriptionLine(m) }}
              </div>
              <div class="recent-model-meta text-color-secondary text-sm mt-1">
                <span>{{ formatModelDate(m.lastUpdated) }}</span>
                <span class="mx-2">·</span>
                <router-link :to="objectsForModelLink(m.id)">Objects</router-link>
              </div>
            </div>
          </li>
        </ul>
      </Panel>
    </template>

    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import ErrorDialog from '@/components/ErrorDialog.vue'
import AuthorIdentityProviderBadge from '@/components/AuthorIdentityProviderBadge.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
import { stripHtmlTags } from '@/utils/stripHtmlTags'

const MAX_DESC_LEN = 128

const route = useRoute()
const auth = useAuthStore()
const author = ref(null)
const loading = ref(true)
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()
const selectedRole = ref(null)
const roleSaveStatus = ref('')
const descriptionDraft = ref('')
const descriptionSaving = ref(false)
const descriptionSaveStatus = ref('')

interface RecentModelRow {
  id: number
  name?: string | null
  filename?: string | null
  description?: string | null
  lastUpdated?: string | null
}

const recentModels = ref<RecentModelRow[]>([])
const recentModelsLoading = ref(false)
const recentModelsError = ref('')

const isAdmin = computed(() => auth.isAdmin)

const isOwnProfile = computed(() => {
  const uid = auth.user?.id
  const aid = author.value?.id
  return !!(auth.isAuthenticated && uid != null && aid != null && Number(uid) === Number(aid))
})

/** Plain-text blurb for visitors (tags stripped; not shown on own profile — editor is used instead). */
const publicAuthorBlurb = computed(() => {
  if (isOwnProfile.value) return ''
  const d = author.value?.description
  if (d == null || String(d).trim() === '') return ''
  return stripHtmlTags(String(d)).trim()
})

const roleOptions = [
  { label: 'User', value: 'user' },
  { label: 'Reviewer', value: 'reviewer' },
  { label: 'Tester', value: 'tester' },
  { label: 'Admin', value: 'admin' },
]

const breadcrumbItems = computed(() => [
  { label: 'Authors', to: '/authors' },
  { label: author.value?.name || `Author #${author.value?.id}` || 'Author', to: null },
])

const modelsByAuthorLink = computed(() => {
  const id = author.value?.id
  return id != null ? `/models?author=${id}` : '/models'
})

function modelThumbnailUrl(modelId: number) {
  return auth.apiUrl(`/api/models/${modelId}/thumbnail`)
}

function objectsForModelLink(modelId: number) {
  return { path: '/objects', query: { model: String(modelId) } }
}

function modelDisplayName(m: RecentModelRow) {
  return (m.name && String(m.name).trim()) || (m.filename && String(m.filename).trim()) || `Model #${m.id}`
}

function modelDescriptionLine(m: RecentModelRow) {
  const raw = m.description != null ? String(m.description).trim() : ''
  if (raw) return stripHtmlTags(raw).trim() || raw
  return modelDisplayName(m)
}

function formatModelDate(iso: unknown) {
  if (!iso) return '—'
  try {
    const d = new Date(String(iso))
    return d.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })
  } catch {
    return String(iso)
  }
}

function onModelThumbError(e: Event) {
  const t = e.target as HTMLImageElement
  if (t) t.style.display = 'none'
}

async function fetchRecentModels(authorId: number) {
  if (!Number.isFinite(authorId) || authorId < 1) {
    recentModels.value = []
    return
  }
  recentModelsLoading.value = true
  recentModelsError.value = ''
  try {
    const params = new URLSearchParams({
      author: String(authorId),
      offset: '0',
      limit: '10',
      sortField: 'lastUpdated',
      sortOrder: '-1',
    })
    const res = await fetch(auth.apiUrl(`/api/models?${params}`), { credentials: 'include' })
    if (!res.ok) throw new Error(res.statusText)
    const data = (await res.json()) as { models?: RecentModelRow[] }
    recentModels.value = Array.isArray(data.models) ? data.models : []
  } catch {
    recentModels.value = []
    recentModelsError.value = 'Could not load recent models.'
  } finally {
    recentModelsLoading.value = false
  }
}

function formatLastLogin(isoString) {
  if (!isoString) return '—'
  try {
    const d = new Date(isoString)
    return d.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })
  } catch {
    return isoString
  }
}

function roleLabel(role) {
  if (!role) return '—'
  const labels = { user: 'User', reviewer: 'Reviewer', tester: 'Tester', admin: 'Admin' }
  return labels[role] || role
}

async function saveDescription() {
  const id = author.value?.id
  if (id == null || !isOwnProfile.value) return
  descriptionSaveStatus.value = ''
  clearError()
  descriptionSaving.value = true
  const plain = stripHtmlTags(descriptionDraft.value).trim().slice(0, MAX_DESC_LEN)
  try {
    const res = await fetch(auth.apiUrl(`/api/authors/${id}`), {
      method: 'PATCH',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ description: plain }),
    })
    const data = await res.json().catch(() => ({}))
    if (!res.ok) {
      throw new Error((data as { error?: string }).error || res.statusText)
    }
    const desc = (data as { description?: string | null }).description ?? null
    author.value = { ...author.value, description: desc }
    descriptionDraft.value = (desc != null ? stripHtmlTags(String(desc)) : '').trim().slice(0, MAX_DESC_LEN)
    descriptionSaveStatus.value = 'Saved'
    setTimeout(() => {
      descriptionSaveStatus.value = ''
    }, 2000)
  } catch (err) {
    descriptionSaveStatus.value = ''
    showError((err as Error).message || 'Failed to save description')
  } finally {
    descriptionSaving.value = false
  }
}

async function onRoleChange() {
  const id = author.value?.id
  const role = selectedRole.value
  if (id == null || !role) return
  roleSaveStatus.value = 'Saving…'
  try {
    const res = await fetch(auth.apiUrl(`/api/authors/${id}/role`), {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role }),
    })
    if (!res.ok) {
      const data = await res.json().catch(() => ({}))
      throw new Error(data.error || res.statusText)
    }
    author.value = { ...author.value, role }
    await auth.fetchUser()
    roleSaveStatus.value = 'Saved'
    setTimeout(() => { roleSaveStatus.value = '' }, 2000)
  } catch (err) {
    roleSaveStatus.value = 'Failed'
    showError((err as Error).message || 'Failed to update role')
    selectedRole.value = author.value?.role ?? 'user'
  }
}

async function fetchAuthor() {
  const id = route.params.id
  if (!id) return
  loading.value = true
  clearError()
  author.value = null
  recentModels.value = []
  recentModelsError.value = ''
  selectedRole.value = null
  roleSaveStatus.value = ''
  descriptionSaveStatus.value = ''
  try {
    const res = await fetch(auth.apiUrl(`/api/authors/${id}`), { credentials: 'include' })
    if (!res.ok) {
      if (res.status === 404) showError('Author not found')
      else throw new Error(res.statusText)
      return
    }
    const data = await res.json()
    author.value = data
    if (data.role != null) selectedRole.value = data.role
    if (auth.user?.id != null && Number(data.id) === Number(auth.user.id)) {
      descriptionDraft.value = stripHtmlTags(data.description ?? '')
        .trim()
        .slice(0, MAX_DESC_LEN)
    } else {
      descriptionDraft.value = ''
    }
    void fetchRecentModels(Number(data.id))
  } catch (err) {
    showError((err as Error).message || 'Failed to load author')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await auth.fetchUser()
  await fetchAuthor()
})
watch(() => route.params.id, () => void fetchAuthor())
</script>

<style scoped>
.detail-grid {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 0.5rem 1.5rem;
  align-items: start;
}
.detail-label {
  font-weight: 500;
  color: var(--p-text-muted-color, #64748b);
}
.mt-0 { margin-top: 0; }
.mb-3 { margin-bottom: 0.75rem; }
.m-0 { margin: 0; }
.ml-2 { margin-left: 0.5rem; }
.role-edit { display: flex; align-items: center; flex-wrap: wrap; }
.role-save-status { font-size: 0.875rem; color: var(--p-text-muted-color, #64748b); }
.w-10rem { width: 10rem; }
.detail-desc-cell {
  min-width: 0;
}
.desc-hint {
  font-size: 0.875rem;
  color: var(--p-text-muted-color, #64748b);
}
.desc-input-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  width: 100%;
  min-width: 0;
}
.desc-input {
  flex: 1 1 0;
  min-width: 0;
}
.desc-input:deep(.p-inputtext) {
  width: 100%;
}
.desc-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
  margin-top: 0.35rem;
}
.char-count {
  font-size: 0.8125rem;
  color: var(--p-text-muted-color, #64748b);
}
.desc-save-status {
  font-size: 0.8125rem;
  color: var(--p-text-muted-color, #64748b);
}
.detail-description-readonly {
  color: var(--p-text-color);
  line-height: 1.4;
  word-break: break-word;
}
.text-placeholder {
  color: var(--p-text-muted-color, #64748b);
}
.mb-2 { margin-bottom: 0.5rem; }
.inline-flex { display: inline-flex; }
.align-items-center { align-items: center; }
.flex-wrap { flex-wrap: wrap; }
.gap-1 { gap: 0.25rem; }
.gap-2 { gap: 0.5rem; }
.gap-3 { gap: 0.75rem; }
.flex { display: flex; }
.flex-1 { flex: 1 1 0; }
.flex-shrink-0 { flex-shrink: 0; }
.align-items-start { align-items: flex-start; }
.min-w-0 { min-width: 0; }
.text-break { word-break: break-word; overflow-wrap: anywhere; }
.text-sm { font-size: 0.875rem; }
.mt-1 { margin-top: 0.25rem; }
.mx-2 { margin-left: 0.5rem; margin-right: 0.5rem; }
.border-bottom-1 { border-bottom: 1px solid var(--p-content-border-color, #e2e8f0); }
.surface-border { border-color: var(--p-content-border-color, #e2e8f0); }
.recent-models-list li:last-child {
  border-bottom: none;
}
.recent-model-thumb {
  width: 80px;
  height: 60px;
  object-fit: cover;
  border-radius: 4px;
  display: block;
}
.recent-model-thumb-link {
  line-height: 0;
}
.recent-models-head-title {
  font-weight: 600;
}
.align-items-baseline {
  align-items: baseline;
}
.recent-models-show-all {
  font-weight: 500;
}
</style>
