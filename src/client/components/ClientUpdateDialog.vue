<template>
  <Dialog
    v-model:visible="visible"
    header="Update available"
    modal
    :closable="true"
    :draggable="false"
    :style="{ width: 'min(26rem, 100vw - 2rem)' }"
  >
    <p class="client-update-dialog__text m-0">
      A newer version of this site is available. Refresh the page to load it and avoid running outdated
      code.
    </p>
    <template #footer>
      <Button label="Later" severity="secondary" @click="visible = false" />
      <Button label="Refresh now" autofocus @click="reload" />
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'

const visible = ref(false)

function normalizeBuildId(raw: unknown): string {
  if (raw == null) return ''
  return String(raw).trim().toLowerCase()
}

const loadedBuildId = normalizeBuildId(
  typeof __FGS_GIT_SLUG__ !== 'undefined' && __FGS_GIT_SLUG__ ? __FGS_GIT_SLUG__ : ''
)

/** Same-origin path, respecting Vite `base` when the SPA is mounted under a subpath. */
function clientBuildUrl(): string {
  const base = import.meta.env.BASE_URL || '/'
  const prefix = base === '/' ? '' : base.replace(/\/+$/, '')
  const path = `${prefix}/api/client-build`.replace(/\/{2,}/g, '/')
  return path.startsWith('/') ? path : `/${path}`
}

const POLL_MS = 5 * 60 * 1000

let intervalId: ReturnType<typeof setInterval> | null = null

async function checkForNewerBuild(): Promise<void> {
  if (!import.meta.env.PROD || !loadedBuildId || visible.value) return
  try {
    const res = await fetch(clientBuildUrl(), { cache: 'no-store' })
    if (!res.ok) return
    const data = (await res.json()) as { buildId?: string }
    const serverId = normalizeBuildId(data.buildId)
    // "dev" is a non-specific fallback; comparing it to a real slug causes endless false positives.
    if (!serverId || serverId === 'dev' || loadedBuildId === 'dev') return
    if (serverId !== loadedBuildId) {
      visible.value = true
    }
  } catch {
    /* offline or transient errors — ignore */
  }
}

function reload() {
  window.location.reload()
}

function onVisibilityChange() {
  if (document.visibilityState === 'visible') void checkForNewerBuild()
}

onMounted(() => {
  if (!import.meta.env.PROD || !loadedBuildId) return
  void checkForNewerBuild()
  intervalId = window.setInterval(() => void checkForNewerBuild(), POLL_MS)
  document.addEventListener('visibilitychange', onVisibilityChange)
})

onUnmounted(() => {
  if (intervalId !== null) {
    window.clearInterval(intervalId)
    intervalId = null
  }
  document.removeEventListener('visibilitychange', onVisibilityChange)
})
</script>

<style scoped>
.client-update-dialog__text {
  line-height: 1.5;
}
.m-0 {
  margin: 0;
}
</style>
