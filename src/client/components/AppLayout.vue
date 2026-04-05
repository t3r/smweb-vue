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
    <footer class="site-footer">
      <p class="site-footer-text">
        Data on this site is licensed under
        <a href="https://www.gnu.org/licenses/gpl-2.0.html" target="_blank" rel="noopener noreferrer">GPL-2.0+</a>.
        Copyright of each model is owned by the author. Website by and © Torsten Dreyer.
        <span class="site-footer-version">
          Version-Tag:
          <a
            v-if="gitCommitUrl"
            :href="gitCommitUrl"
            target="_blank"
            rel="noopener noreferrer"
            >{{ gitSlug }}</a
          >
          <template v-else>{{ gitSlug }}</template>
        </span>
      </p>
    </footer>
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

const gitSlug = typeof __FGS_GIT_SLUG__ !== 'undefined' ? __FGS_GIT_SLUG__ : 'dev'
const repoWebUrl =
  typeof __FGS_REPO_WEB_URL__ !== 'undefined' ? __FGS_REPO_WEB_URL__.replace(/\/$/, '') : ''

/** GitHub (etc.) /commit/&lt;sha&gt; only when the slug looks like a revision id, not e.g. `dev`. */
function isGitCommitSlug(s: string): boolean {
  return /^[0-9a-f]{7,40}$/i.test(s)
}

const gitCommitUrl =
  repoWebUrl && isGitCommitSlug(gitSlug) ? `${repoWebUrl}/commit/${gitSlug}` : null

const navItems = computed(() => {
  const items = [
    { label: 'Home', command: () => router.push('/') },
    { label: 'News', command: () => router.push('/news') },
    { label: 'Map', command: () => router.push('/map') },
    { label: 'Models', command: () => router.push('/models') },
    { label: 'Objects', command: () => router.push('/objects') },
    { label: 'Authors', command: () => router.push('/authors') },
    { label: 'About', command: () => router.push('/about') },
  ]
  if (auth.isReviewer) {
    items.push({ label: 'Pending requests', command: () => router.push('/position-requests') })
  }
  items.push({
      label: 'Old Site',
      url: 'https://legacy.scenery.flightgear.org/',
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
}
main {
  flex: 0 1 auto;
  display: flex;
  flex-direction: column;
  padding: 1rem;
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
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
.site-footer {
  flex-shrink: 0;
  padding: 0.75rem 1rem 1rem;
  border-top: 1px solid var(--p-content-border-color, rgba(0, 0, 0, 0.12));
  background: var(--p-surface-50, rgba(0, 0, 0, 0.02));
}
.site-footer-text {
  margin: 0;
  max-width: 56rem;
  margin-left: auto;
  margin-right: auto;
  font-size: 0.75rem;
  line-height: 1.5;
  color: var(--p-text-muted-color, var(--p-text-secondary-color, #64748b));
  text-align: center;
}
.site-footer-text a {
  color: var(--p-primary-color);
  text-decoration: none;
}
.site-footer-text a:hover {
  text-decoration: underline;
}
.site-footer-version {
  display: inline-block;
  margin-left: 0.35rem;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
</style>
