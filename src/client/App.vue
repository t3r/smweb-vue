<template>
  <Toast position="bottom-center" class="app-toast-host" />

  <Dialog
    v-model:visible="authConfigError"
    header="Login not configured"
    modal
    :closable="true"
    :style="{ width: 'min(32rem, 100vw - 2rem)' }"
    @hide="authConfigError = false"
  >
    <p class="m-0">
      Login is not configured. Set at least one OAuth pair in the server <code>.env</code> (see
      <code>.env.example</code>): <code>GITHUB_CLIENT_ID</code> / <code>GITHUB_CLIENT_SECRET</code>,
      <code>GOOGLE_CLIENT_ID</code> / <code>GOOGLE_CLIENT_SECRET</code>, or
      <code>GITLAB_CLIENT_ID</code> / <code>GITLAB_CLIENT_SECRET</code>.
    </p>
    <template #footer>
      <Button label="OK" autofocus @click="authConfigError = false" />
    </template>
  </Dialog>

  <Dialog
    v-model:visible="loginErrorDialogVisible"
    header="Login failed"
    modal
    :closable="true"
    :style="{ width: 'min(32rem, 100vw - 2rem)' }"
    @hide="loginError = null"
  >
    <p class="m-0 font-medium">{{ loginError?.title }}</p>
    <p v-if="loginError?.detail" class="auth-error-detail m-0 mt-2">{{ loginError.detail }}</p>
    <p class="auth-error-hint m-0 mt-2 text-muted">Check the server console for details. You can try logging in again.</p>
    <template #footer>
      <Button label="OK" autofocus @click="loginError = null" />
    </template>
  </Dialog>

  <AppLayout />
  <ClientUpdateDialog />
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import AppLayout from './components/AppLayout.vue'
import ClientUpdateDialog from './components/ClientUpdateDialog.vue'
import { useAuthStore } from './stores/auth'
import Toast from 'primevue/toast'
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'

const route = useRoute()
const authStore = useAuthStore()
const authConfigError = ref(false)
const loginError = ref<{ title: string; detail?: string | null } | null>(null)

const loginErrorDialogVisible = computed({
  get: () => loginError.value != null,
  set: (v: boolean) => {
    if (!v) loginError.value = null
  },
})

const loginErrorReasons = {
  strategy_error: 'Authentication with the provider failed.',
  no_user: 'The provider did not return a user.',
  session_error: 'Your session could not be saved.',
}

onMounted(() => {
  authStore.fetchUser()
  if (route.query?.auth_error === 'config') {
    authConfigError.value = true
  } else if (route.query?.auth_error === '1') {
    const reason = (Array.isArray(route.query?.reason) ? route.query.reason[0] : route.query?.reason) || 'unknown'
    const message = (Array.isArray(route.query?.message) ? route.query.message[0] : route.query?.message) || ''
    loginError.value = {
      title: loginErrorReasons[reason as keyof typeof loginErrorReasons] || 'Login failed.',
      detail: message || null,
    }
  }
  if (route.query?.auth_error) {
    window.history.replaceState({}, '', route.path)
  }
})
</script>

<style scoped>
.auth-error-detail {
  font-size: 0.9rem;
  word-break: break-word;
}
.auth-error-hint {
  font-size: 0.85rem;
}
.text-muted {
  opacity: 0.85;
}
.m-0 {
  margin: 0;
}
.mt-2 {
  margin-top: 0.5rem;
}
.font-medium {
  font-weight: 500;
}
</style>

<style>
* {
  box-sizing: border-box;
}
body {
  margin: 0;
  font-family: system-ui, -apple-system, sans-serif;
  color: var(--p-text-color);
  line-height: 1.5;
}
h1,
h2,
h3,
h4,
h5,
h6 {
  color: var(--p-text-color, inherit);
}
/* Keep bottom toasts readable and off the very edge */
.app-toast-host.p-toast {
  --p-toast-width: min(32rem, calc(100vw - 1.5rem));
}
</style>
