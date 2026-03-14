<template>
  <div>
    <Message v-if="error" severity="error" class="mb-3">{{ error }}</Message>
    <p v-else-if="loading" class="m-0">Loading…</p>
    <template v-else-if="author">
      <Breadcrumb :model="breadcrumbItems" class="mb-3">
        <template #item="{ item }">
          <router-link v-if="item.to" :to="item.to" class="p-breadcrumb-link">{{ item.label }}</router-link>
          <span v-else>{{ item.label }}</span>
        </template>
      </Breadcrumb>

      <h1 class="mt-0">{{ author.name || `Author #${author.id}` }}</h1>
      <p v-if="author.description" class="author-description mt-0 mb-3">{{ author.description }}</p>

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
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const auth = useAuthStore()
const author = ref(null)
const loading = ref(true)
const error = ref(null)
const selectedRole = ref(null)
const roleSaveStatus = ref('')

const isAdmin = computed(() => auth.isAdmin)

const roleOptions = [
  { label: 'User', value: 'user' },
  { label: 'Reviewer', value: 'reviewer' },
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
  const labels = { user: 'User', reviewer: 'Reviewer', admin: 'Admin' }
  return labels[role] || role
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
    roleSaveStatus.value = 'Saved'
    setTimeout(() => { roleSaveStatus.value = '' }, 2000)
  } catch (err) {
    roleSaveStatus.value = 'Failed'
    error.value = (err as Error).message || 'Failed to update role'
    selectedRole.value = author.value?.role ?? 'user'
  }
}

async function fetchAuthor() {
  const id = route.params.id
  if (!id) return
  loading.value = true
  error.value = null
  author.value = null
  selectedRole.value = null
  roleSaveStatus.value = ''
  try {
    const res = await fetch(`/api/authors/${id}`, { credentials: 'include' })
    if (!res.ok) {
      if (res.status === 404) error.value = 'Author not found'
      else throw new Error(res.statusText)
      return
    }
    const data = await res.json()
    author.value = data
    if (data.role != null) selectedRole.value = data.role
  } catch (err) {
    error.value = (err as Error).message || 'Failed to load author'
  } finally {
    loading.value = false
  }
}

onMounted(() => fetchAuthor())
watch(() => route.params.id, () => fetchAuthor())
</script>

<style scoped>
.detail-grid {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 0.5rem 1.5rem;
  align-items: baseline;
}
.detail-label {
  font-weight: 500;
  color: var(--p-text-muted-color, #64748b);
}
.author-description {
  font-size: 1rem;
  color: var(--p-text-muted-color, #64748b);
  white-space: pre-wrap;
  word-break: break-word;
  line-height: 1.4;
}
.mt-0 { margin-top: 0; }
.mb-3 { margin-bottom: 0.75rem; }
.m-0 { margin: 0; }
.ml-2 { margin-left: 0.5rem; }
.role-edit { display: flex; align-items: center; flex-wrap: wrap; }
.role-save-status { font-size: 0.875rem; color: var(--p-text-muted-color, #64748b); }
.w-10rem { width: 10rem; }
</style>
