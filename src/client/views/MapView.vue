<template>
  <div class="map-view-root">
    <Card class="map-view-card">
      <template #content>
        <div class="map-view-card-content">
          <ObjectMap
            :map-objects-api-url="auth.apiUrl('/api/objects/map')"
            :initial-center="[10, 53.5]"
            :initial-zoom="7"
            @object-click="onObjectClick"
          />
        </div>
      </template>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import ObjectMap from '@/components/ObjectMap.vue'

const router = useRouter()
const auth = useAuthStore()
const objectsForDemo = ref([])

function onObjectClick(id) {
  router.push(`/objects/${id}`)
}

async function fetchObjectsForDemo() {
  const bbox = '9,52.5,11,54.5'
  try {
    const res = await fetch(`${auth.apiUrl('/api/objects/map')}?bbox=${bbox}&limit=20`, { credentials: 'include' })
    if (!res.ok) return
    const data = await res.json()
    objectsForDemo.value = data.objects ?? []
  } catch {
    objectsForDemo.value = []
  }
}

onMounted(() => {
  fetchObjectsForDemo()
})
</script>

<style scoped>
/* Tall map; chrome ≈ menubar + main padding + footer below main. */
.map-view-root {
  display: flex;
  flex-direction: column;
  min-height: calc(100vh - 9.5rem);
  min-height: calc(100dvh - 9.5rem);
}
.map-view-card {
  flex: 1 1 0;
  display: flex;
  flex-direction: column;
  min-height: 0;
}
.map-view-card :deep(.p-card-body) {
  flex: 1 1 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
}
.map-view-card :deep(.p-card-content) {
  flex: 1 1 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: 0;
}
.map-view-card-content {
  flex: 1 1 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
}
.map-view-card-content :deep(.object-map-container) {
  flex: 1 1 0;
  min-height: 200px;
  height: auto;
}
.mt-0 { margin-top: 0; }
.mb-2 { margin-bottom: 0.5rem; }
.mb-3 { margin-bottom: 0.75rem; }
.mb-4 { margin-bottom: 1rem; }
.mt-2 { margin-top: 0.5rem; }
.m-0 { margin: 0; }
.p-4 { padding: 1rem; }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
.flex { display: flex; }
.align-items-center { align-items: center; }
.justify-content-center { justify-content: center; }
.map-hint { font-size: 0.875rem; }
.mr-2 { margin-right: 0.5rem; }
.ml-2 { margin-left: 0.5rem; }
</style>
