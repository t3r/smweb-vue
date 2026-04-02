import { useToast } from 'primevue/usetoast'

const DEFAULT_LIFE_MS = 8000

/**
 * Bottom toasts (see root `Toast` in App.vue): non-blocking info, success, and warnings.
 * Use ErrorDialog / modal Dialog when the user must acknowledge or confirm an action.
 */
export function useAppToast() {
  const toast = useToast()

  function add(
    severity: 'info' | 'success' | 'warn' | 'error',
    detail: string,
    summary: string,
    life = DEFAULT_LIFE_MS
  ) {
    toast.add({
      severity,
      summary,
      detail,
      life,
      closable: true,
    })
  }

  return {
    toastInfo: (detail: string, summary = 'Information') => add('info', detail, summary),
    toastSuccess: (detail: string, summary = 'Success') => add('success', detail, summary),
    toastWarn: (detail: string, summary = 'Warning') => add('warn', detail, summary),
    /** Use sparingly; prefer ErrorDialog for failures that need explicit dismissal. */
    toastError: (detail: string, summary = 'Error') => add('error', detail, summary),
  }
}
