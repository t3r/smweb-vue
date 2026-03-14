<template>
  <div class="object-details-loader">
    <p v-if="loading" class="m-0 text-color-secondary">Loading object…</p>
    <Message v-else-if="error" severity="error" class="m-0">{{ error }}</Message>
    <ObjectDetailsCard v-else-if="object" :object="object" :countries="countries" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import Message from 'primevue/message'
import ObjectDetailsCard from '@/components/ObjectDetailsCard.vue'
import type { ObjectDetailsObject } from '@/components/ObjectDetailsCard.vue'
import type { CountryOption } from '@/components/ObjectDetailsCard.vue'

const props = withDefaults(
  defineProps<{
    objId: number
    countries?: CountryOption[]
  }>(),
  { countries: () => [] }
)

const auth = useAuthStore()
const object = ref<ObjectDetailsObject | null>(null)
const loading = ref(true)
const error = ref<string | null>(null)

async function fetchObject() {
  if (props.objId == null || !Number.isFinite(Number(props.objId))) {
    loading.value = false
    error.value = 'Invalid object id'
    return
  }
  loading.value = true
  error.value = null
  object.value = null
  try {
    const url = auth.apiUrl(`/api/objects/${props.objId}`)
    const res = await fetch(url, { credentials: 'include' })
    if (!res.ok) {
      if (res.status === 404) error.value = 'Object not found'
      else throw new Error(res.statusText)
      return
    }
    const data = await res.json()
    object.value = data as ObjectDetailsObject
  } catch (err) {
    error.value = (err as Error).message || 'Failed to load object'
  } finally {
    loading.value = false
  }
}

onMounted(fetchObject)
watch(() => props.objId, fetchObject)
</script>

<style scoped>
.object-details-loader { margin: 0; }
.m-0 { margin: 0; }
.text-color-secondary { color: var(--p-text-muted-color); }
</style>
