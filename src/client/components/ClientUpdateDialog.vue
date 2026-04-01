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

const loadedBuildId =
  typeof __FGS_GIT_SLUG__ !== 'undefined' && __FGS_GIT_SLUG__ ? __FGS_GIT_SLUG__ : ''

const POLL_MS = 5 * 60 * 1000

let intervalId: ReturnType<typeof setInterval> | null = null

async function checkForNewerBuild(): Promise<void> {
  if (!import.meta.env.PROD || !loadedBuildId || visible.value) return
  try {
    const res = await fetch('/api/client-build', { cache: 'no-store' })
    if (!res.ok) return
    const data = (await res.json()) as { buildId?: string }
    const serverId = typeof data.buildId === 'string' ? data.buildId.trim() : ''
    if (serverId && serverId !== loadedBuildId) {
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
