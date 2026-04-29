<template>
  <div class="merge-account">
    <h1 class="mt-0">Merge accounts</h1>
    <p class="text-color-secondary mb-4">
      Combine your current signed-in author with another author record (for example a legacy entry whose email did not match your OAuth email).
      We send a confirmation link to the <strong>other</strong> account’s email address. Open that link while still signed in with
      <strong>this</strong> account to review and confirm.
    </p>

    <Panel header="Target author">
      <div class="flex flex-column gap-3">
        <div>
          <label for="merge-target-email" class="block mb-1 font-medium">Target email</label>
          <InputText
            id="merge-target-email"
            v-model="targetEmail"
            type="email"
            class="w-full max-w-30rem"
            placeholder="author@example.com"
            autocomplete="off"
          />
        </div>
        <p class="m-0 text-color-secondary text-sm">— or —</p>
        <div>
          <label for="merge-target-id" class="block mb-1 font-medium">Target author ID</label>
          <InputNumber
            id="merge-target-id"
            v-model="targetAuthorId"
            :min="1"
            input-class="w-full"
            class="max-w-15rem"
            placeholder="Numeric id"
            :use-grouping="false"
          />
        </div>
        <Button
          label="Send verification email"
          icon="pi pi-envelope"
          :loading="loading"
          :disabled="loading || !canSubmit"
          @click="onSubmit"
        />
        <p v-if="successMessage" class="m-0 text-green-600">{{ successMessage }}</p>
        <p v-if="error" class="m-0 text-red-600">{{ error }}</p>
      </div>
    </Panel>

    <p class="mt-4 text-sm text-color-secondary">
      <router-link to="/">Home</router-link>
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import Panel from 'primevue/panel'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Button from 'primevue/button'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

const targetEmail = ref('')
const targetAuthorId = ref<number | null>(null)
const loading = ref(false)
const error = ref('')
const successMessage = ref('')

const canSubmit = computed(() => {
  const e = targetEmail.value.trim()
  const id = targetAuthorId.value
  return e.length > 3 || (id != null && Number.isInteger(id) && id >= 1)
})

onMounted(async () => {
  await auth.fetchUser()
  if (!auth.isAuthenticated) {
    router.replace({ path: '/', query: { login: 'required' } })
  }
})

async function onSubmit() {
  error.value = ''
  successMessage.value = ''
  loading.value = true
  try {
    const body: { targetEmail?: string; targetAuthorId?: number } = {}
    const e = targetEmail.value.trim()
    const id = targetAuthorId.value
    if (e) body.targetEmail = e
    if (id != null && Number.isInteger(id) && id >= 1) body.targetAuthorId = id
    await auth.initiateAccountMerge(body)
    successMessage.value =
      'If the target exists and has an email, a confirmation message was queued. Check that inbox and open the link while signed in with this account.'
    targetEmail.value = ''
    targetAuthorId.value = null
  } catch (err) {
    error.value = (err as Error).message || 'Request failed'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.merge-account {
  max-width: 40rem;
}
.mt-0 {
  margin-top: 0;
}
.mb-1 {
  margin-bottom: 0.25rem;
}
.mb-4 {
  margin-bottom: 1rem;
}
.mt-4 {
  margin-top: 1rem;
}
.flex {
  display: flex;
}
.flex-column {
  flex-direction: column;
}
.gap-3 {
  gap: 0.75rem;
}
.block {
  display: block;
}
.font-medium {
  font-weight: 500;
}
.w-full {
  width: 100%;
}
.max-w-30rem {
  max-width: 30rem;
}
.max-w-15rem {
  max-width: 15rem;
}
.m-0 {
  margin: 0;
}
.text-sm {
  font-size: 0.875rem;
}
</style>
