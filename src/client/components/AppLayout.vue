<template>
  <div class="layout-root">
    <Menubar :model="navItems">
      <template #start>
        <router-link to="/" class="logo-link">
          <img src="/FlightGear_logo.svg" alt="" class="navbar-logo" width="32" height="32" />
          <span>FlightGear Scenemodels</span>
        </router-link>
      </template>
      <template #end>
        <div class="menubar-end">
          <div v-if="auth.loaded" class="auth-block">
            <template v-if="auth.isAuthenticated">
              <router-link :to="`/authors/${auth.user.id}`" class="user-name-link" :title="`Role: ${auth.role}`">{{ auth.user.name }}</router-link>
              <Button label="Logout" text size="small" @click="auth.logout()" />
            </template>
            <template v-else>
              <Button label="Login" icon="pi pi-user" size="small" @click="toggleLoginMenu" />
              <Menu ref="loginMenuRef" :model="loginMenuItems" :popup="true" />
            </template>
          </div>
          <ThemePicker />
        </div>
      </template>
    </Menubar>
    <main>
      <router-view />
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import ThemePicker from './ThemePicker.vue'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()
const loginMenuRef = ref(null)

const navItems = computed(() => {
  const items = [
    { label: 'Home', command: () => router.push('/') },
    { label: 'News', command: () => router.push('/news') },
    { label: 'Map', command: () => router.push('/map') },
    { label: 'Models', command: () => router.push('/models') },
    { label: 'Objects', command: () => router.push('/objects') },
    { label: 'Authors', command: () => router.push('/authors') },
  ]
  if (auth.isReviewer) {
    items.push({ label: 'Position requests', command: () => router.push('/position-requests') })
  }
  items.push({
      label: 'Old Site',
      url: 'https://scenery.flightgear.org/',
      target: '_blank',
      rel: 'noopener noreferrer',
  });
  return items
})

const loginMenuItems = computed(() => [
  { label: 'GitHub', icon: 'pi pi-github', command: () => auth.loginWithGitHub() },
  { label: 'GitLab', icon: 'pi pi-code', command: () => auth.loginWithGitLab() },
])

function toggleLoginMenu(event) {
  loginMenuRef.value?.toggle(event)
}
</script>

<style scoped>
.layout-root {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}
main {
  flex: 1 1 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: 1rem;
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
}
main > * {
  flex: 1 1 0;
  min-height: 0;
}
.logo-link {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  text-decoration: none;
  font-weight: 600;
  color: inherit;
}
.logo-link:hover {
  text-decoration: underline;
}
.navbar-logo {
  display: block;
  height: 1.75rem;
  width: auto;
  flex-shrink: 0;
}
.menubar-end {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.auth-block {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.user-name-link {
  font-size: 0.875rem;
  margin-right: 0.25rem;
  color: var(--p-primary-color);
  text-decoration: none;
}
.user-name-link:hover {
  text-decoration: underline;
}
</style>
