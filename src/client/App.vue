<template>
  <Message v-if="authConfigError" severity="warn" :closable="true" class="auth-config-message" @close="authConfigError = false">
    Login is not configured. Set GITHUB_CLIENT_ID / GITHUB_CLIENT_SECRET or GITLAB_CLIENT_ID / GITLAB_CLIENT_SECRET in the server .env (see .env.example).
  </Message>
  <Message v-else-if="loginError" severity="error" :closable="true" class="auth-error-message" @close="loginError = null">
    <strong>Login failed</strong>
    <p class="auth-error-reason m-0 mt-2">{{ loginError.title }}</p>
    <p v-if="loginError.detail" class="auth-error-detail m-0 mt-1">{{ loginError.detail }}</p>
    <p class="auth-error-hint m-0 mt-2 text-muted">Check the server console for details. You can try logging in again.</p>
  </Message>
  <AppLayout />
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import AppLayout from './components/AppLayout.vue'
import { useAuthStore } from './stores/auth'
import Message from 'primevue/message'

const route = useRoute()
const authStore = useAuthStore()
const authConfigError = ref(false)
const loginError = ref<{ title: string; detail?: string | null } | null>(null)

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
.auth-config-message,
.auth-error-message {
  margin: 0;
  border-radius: 0;
}
.auth-error-reason { font-weight: 500; }
.auth-error-detail { font-size: 0.9rem; word-break: break-word; }
.auth-error-hint { font-size: 0.85rem; }
.text-muted { opacity: 0.85; }
.m-0 { margin: 0; }
.mt-1 { margin-top: 0.25rem; }
.mt-2 { margin-top: 0.5rem; }
</style>

<style>
* { box-sizing: border-box; }
body { margin: 0; font-family: system-ui, -apple-system, sans-serif; color: var(--p-text-color); line-height: 1.5; }
h1, h2, h3, h4, h5, h6 { color: var(--p-text-color, inherit); }
</style>
