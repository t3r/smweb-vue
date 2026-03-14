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

  function loginWithGitHub(): void {
    window.location.href = apiUrl('/api/auth/github')
  }

  function loginWithGitLab(): void {
    window.location.href = apiUrl('/api/auth/gitlab')
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

  return {
    user,
    loaded,
    isAuthenticated,
    role,
    isReviewer,
    isAdmin,
    fetchUser,
    loginWithGitHub,
    loginWithGitLab,
    logout,
    apiUrl,
  }
})
