<template>
  <div class="merge-confirm">
    <h1 class="mt-0">Confirm account merge</h1>

    <p v-if="!token || !mergeId" class="text-color-secondary">
      Missing token or id. Use the link from your email.
    </p>

    <p v-else-if="loading" class="m-0">Loading…</p>

    <template v-else-if="preview">
      <Panel header="Summary" class="mb-3">
        <p class="m-0 mb-2">
          The merged profile will keep author id <strong>#{{ preview.keeperId }}</strong> (lower id). Data from both authors will be combined.
        </p>
        <ul class="pl-3 m-0">
          <li>Models (non-deleted): {{ preview.counts?.models ?? 0 }}</li>
          <li>News posts: {{ preview.counts?.news ?? 0 }}</li>
          <li>OAuth identities: {{ preview.counts?.oauthIdentities ?? 0 }}</li>
          <li>
            Effective role after merge:
            <strong>{{ preview.roles?.merged }}</strong>
            (was {{ preview.roles?.source }} / {{ preview.roles?.target }})
          </li>
        </ul>
      </Panel>

      <div class="flex flex-wrap gap-2 mb-3">
        <Button
          label="Confirm merge"
          icon="pi pi-check"
          severity="danger"
          :loading="confirming"
          :disabled="confirming"
          @click="onConfirm"
        />
        <Button label="Cancel" severity="secondary" outlined :disabled="confirming" @click="onCancel" />
      </div>

      <p v-if="error" class="text-red-600 m-0">{{ error }}</p>
    </template>

    <p v-else-if="error" class="text-red-600 m-0">{{ error }}</p>

    <p class="mt-4">
      <router-link to="/">Home</router-link>
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import Panel from 'primevue/panel'
import Button from 'primevue/button'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const loading = ref(true)
const confirming = ref(false)
const error = ref('')
const preview = ref<Record<string, unknown> | null>(null)

const token = computed(() => (typeof route.query.token === 'string' ? route.query.token : ''))
const mergeId = computed(() => (typeof route.query.id === 'string' ? route.query.id : ''))

onMounted(async () => {
  await auth.fetchUser()
  if (!auth.isAuthenticated) {
    router.replace({ path: '/', query: { ...route.query, login: 'required' } })
    return
  }
  await loadPreview()
})

watch(
  () => [route.query.token, route.query.id],
  () => void loadPreview()
)

async function loadPreview() {
  preview.value = null
  error.value = ''
  if (!token.value || !mergeId.value) {
    loading.value = false
    return
  }
  loading.value = true
  try {
    preview.value = await auth.previewAccountMerge(token.value, mergeId.value)
  } catch (e) {
    error.value = (e as Error).message || 'Could not load merge preview'
  } finally {
    loading.value = false
  }
}

async function onConfirm() {
  if (!token.value || !mergeId.value) return
  confirming.value = true
  error.value = ''
  try {
    const out = await auth.confirmAccountMerge(token.value, mergeId.value)
    await auth.fetchUser()
    const kid = (out as { keeperAuthorId?: number }).keeperAuthorId
    if (kid != null) {
      await router.replace(`/authors/${kid}`)
    } else {
      await router.replace('/')
    }
  } catch (e) {
    error.value = (e as Error).message || 'Merge failed'
  } finally {
    confirming.value = false
  }
}

async function onCancel() {
  if (!mergeId.value) {
    router.push('/account/merge')
    return
  }
  confirming.value = true
  error.value = ''
  try {
    await auth.cancelAccountMerge(mergeId.value)
    await router.push('/account/merge')
  } catch (e) {
    error.value = (e as Error).message || 'Could not cancel'
  } finally {
    confirming.value = false
  }
}
</script>

<style scoped>
.merge-confirm {
  max-width: 42rem;
}
.mt-0 {
  margin-top: 0;
}
.mb-2 {
  margin-bottom: 0.5rem;
}
.mb-3 {
  margin-bottom: 0.75rem;
}
.mt-4 {
  margin-top: 1rem;
}
.m-0 {
  margin: 0;
}
.pl-3 {
  padding-left: 1rem;
}
.flex {
  display: flex;
}
.flex-wrap {
  flex-wrap: wrap;
}
.gap-2 {
  gap: 0.5rem;
}
</style>
