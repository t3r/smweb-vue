import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'

const PENDING_COUNT_POLL_MS = 15 * 60 * 1000

export const usePendingRequestCountStore = defineStore('pendingRequestCount', () => {
  const count = ref(0)
  let pollTimer: ReturnType<typeof setInterval> | null = null

  async function fetchCount(): Promise<void> {
    const auth = useAuthStore()
    if (!auth.isReviewer) return
    try {
      const res = await fetch(auth.apiUrl('/api/position-requests/pending-count'), {
        credentials: 'include',
      })
      if (!res.ok) return
      const data = (await res.json()) as { count?: unknown }
      const n = data.count
      count.value = typeof n === 'number' && Number.isFinite(n) ? n : 0
    } catch {
      /* ignore network errors for badge */
    }
  }

  function stopPolling(): void {
    if (pollTimer != null) {
      clearInterval(pollTimer)
      pollTimer = null
    }
  }

  function startPolling(): void {
    stopPolling()
    void fetchCount()
    pollTimer = setInterval(() => void fetchCount(), PENDING_COUNT_POLL_MS)
  }

  function reset(): void {
    stopPolling()
    count.value = 0
  }

  return { count, fetchCount, startPolling, stopPolling, reset }
})
