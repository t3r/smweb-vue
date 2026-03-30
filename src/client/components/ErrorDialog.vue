<template>
  <Dialog
    v-model:visible="visible"
    header="Error"
    modal
    :closable="true"
    :style="{ width: 'min(28rem, 100vw - 2rem)' }"
    @hide="onHide"
  >
    <p class="error-dialog-text m-0">{{ message }}</p>
    <template #footer>
      <Button label="OK" autofocus @click="visible = false" />
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'

defineProps<{
  message: string
}>()

const visible = defineModel<boolean>('visible', { required: true })

const emit = defineEmits<{
  /** Fires when the dialog closes; parent may clear the message when appropriate. */
  cleared: []
}>()

function onHide() {
  emit('cleared')
}
</script>

<style scoped>
.error-dialog-text {
  white-space: pre-wrap;
  word-break: break-word;
}
</style>
