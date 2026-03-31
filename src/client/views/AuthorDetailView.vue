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

      <h1 class="mt-0">{{ author.name || `Author #${author.id}` }}</h1>

      <Panel header="Details" class="mb-3">
        <div class="detail-grid">
          <span class="detail-label">ID</span>
          <span>#{{ author.id }}</span>
          <span class="detail-label">Name</span>
          <span>{{ author.name || '—' }}</span>
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
          <span class="detail-label">Models</span>
          <span>
            <router-link v-if="author.modelsCount != null" :to="modelsByAuthorLink">{{ author.modelsCount }} model(s)</router-link>
            <span v-else>—</span>
          </span>
        </div>
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
</style>
