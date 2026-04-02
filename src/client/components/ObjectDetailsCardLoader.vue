<template>
  <div class="object-details-loader">
    <p v-if="loading" class="m-0 text-color-secondary">Loading object…</p>
    <ObjectDetailsCard v-else-if="object" :object="object" :countries="countries" />
    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
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
const { error, errorDialogVisible, showError, onErrorDialogCleared } = useErrorDialog()
const object = ref<ObjectDetailsObject | null>(null)
const loading = ref(true)

async function fetchObject() {
  if (props.objId == null || !Number.isFinite(Number(props.objId))) {
    loading.value = false
    showError('Invalid object id')
    return
  }
  loading.value = true
  object.value = null
  try {
    const url = auth.apiUrl(`/api/objects/${props.objId}`)
    const res = await fetch(url, { credentials: 'include' })
    if (!res.ok) {
      if (res.status === 404) showError('Object not found')
      else throw new Error(res.statusText)
      return
    }
    const data = await res.json()
    object.value = data as ObjectDetailsObject
  } catch (err) {
    showError((err as Error).message || 'Failed to load object')
  } finally {
    loading.value = false
  }
}

onMounted(fetchObject)
watch(() => props.objId, fetchObject)
</script>

<style scoped>
.object-details-loader {
  margin: 0;
}
.m-0 {
  margin: 0;
}
.text-color-secondary {
  color: var(--p-text-muted-color);
}
</style>
