import { ref } from 'vue'

/** Shared state for PrimeVue error modal + message text. */
export function useErrorDialog() {
  const error = ref('')
  const errorDialogVisible = ref(false)

  function clearError() {
    error.value = ''
    errorDialogVisible.value = false
  }

  function showError(message: string) {
    error.value = message
    errorDialogVisible.value = true
  }

  function onErrorDialogCleared() {
    error.value = ''
  }

  return {
    error,
    errorDialogVisible,
    clearError,
    showError,
    onErrorDialogCleared,
  }
}
