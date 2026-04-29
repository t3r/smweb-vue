import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface AuthUser {
  id: number
  name: string
  email?: string
  role?: string
  [key: string]: unknown
}

const API_BASE = typeof import.meta !== 'undefined' && import.meta.env?.VITE_API_URL
  ? String(import.meta.env.VITE_API_URL).replace(/\/$/, '')
  : ''

function apiUrl(path: string): string {
  return `${API_BASE}${path.startsWith('/') ? path : `/${path}`}`
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<AuthUser | null>(null)
  const loaded = ref(false)

  const isAuthenticated = computed(() => !!user.value)
  const role = computed(() => user.value?.role ?? null)
  const isReviewer = computed(() => role.value === 'reviewer' || role.value === 'admin')
  const isAdmin = computed(() => role.value === 'admin')

  async function fetchUser(): Promise<void> {
    try {
      const res = await fetch(apiUrl('/api/auth/me'), { credentials: 'include' })
      const data = (await res.json().catch(() => ({}))) as { user?: AuthUser }
      if (res.ok && data.user) {
        user.value = data.user
      } else {
        user.value = null
      }
    } catch {
      user.value = null
    } finally {
      loaded.value = true
    }
  }

  function loginRedirectUrl(path: string): string {
    const returnTo = `${window.location.pathname}${window.location.search}`
    const qs = new URLSearchParams({ returnTo })
    return `${apiUrl(path)}?${qs.toString()}`
  }

  function loginWithGitHub(): void {
    window.location.href = loginRedirectUrl('/api/auth/github')
  }

  function loginWithGitLab(): void {
    window.location.href = loginRedirectUrl('/api/auth/gitlab')
  }

  function loginWithGoogle(): void {
    window.location.href = loginRedirectUrl('/api/auth/google')
  }

  async function logout(): Promise<void> {
    try {
      await fetch(apiUrl('/api/auth/logout'), {
        method: 'POST',
        credentials: 'include',
      })
    } finally {
      user.value = null
    }
  }

  async function initiateAccountMerge(body: {
    targetEmail?: string
    targetAuthorId?: number
  }): Promise<{ mergeRequestId: string; expiresAt: string }> {
    const res = await fetch(apiUrl('/api/auth/merge/initiate'), {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
    const data = (await res.json().catch(() => ({}))) as {
      error?: string
      mergeRequestId?: string
      expiresAt?: string
    }
    if (!res.ok) throw new Error(data.error || res.statusText)
    return {
      mergeRequestId: data.mergeRequestId ?? '',
      expiresAt: data.expiresAt ?? '',
    }
  }

  async function previewAccountMerge(token: string, mergeRequestId: string): Promise<Record<string, unknown>> {
    const q = new URLSearchParams({ token, id: mergeRequestId })
    const res = await fetch(apiUrl(`/api/auth/merge/preview?${q.toString()}`), { credentials: 'include' })
    const data = (await res.json().catch(() => ({}))) as { error?: string } & Record<string, unknown>
    if (!res.ok) throw new Error(data.error || res.statusText)
    return data
  }

  async function confirmAccountMerge(
    token: string,
    mergeRequestId: string
  ): Promise<{ keeperAuthorId: number }> {
    const res = await fetch(apiUrl('/api/auth/merge/confirm'), {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token, id: mergeRequestId }),
    })
    const data = (await res.json().catch(() => ({}))) as { error?: string; keeperAuthorId?: number }
    if (!res.ok) throw new Error(data.error || res.statusText)
    const keeperAuthorId = data.keeperAuthorId
    if (keeperAuthorId == null || !Number.isFinite(Number(keeperAuthorId))) {
      throw new Error('Invalid server response')
    }
    return { keeperAuthorId: Number(keeperAuthorId) }
  }

  async function cancelAccountMerge(mergeRequestId: string): Promise<void> {
    const res = await fetch(apiUrl('/api/auth/merge/cancel'), {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: mergeRequestId }),
    })
    const data = (await res.json().catch(() => ({}))) as { error?: string }
    if (!res.ok) throw new Error(data.error || res.statusText)
  }

  return {
    user,
    loaded,
    isAuthenticated,
    role,
    isReviewer,
    isAdmin,
    fetchUser,
    loginWithGitHub,
    loginWithGoogle,
    loginWithGitLab,
    logout,
    initiateAccountMerge,
    previewAccountMerge,
    confirmAccountMerge,
    cancelAccountMerge,
    apiUrl,
  }
})
