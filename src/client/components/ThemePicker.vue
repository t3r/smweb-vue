<template>
  <div class="theme-picker">
    <label for="theme-select" class="theme-picker-label">Theme</label>
    <Select
      id="theme-select"
      v-model="selectedKey"
      size="small"
      :options="themeOptions"
      option-label="label"
      option-value="value"
      placeholder="Theme"
      class="theme-picker-dropdown"
    />
    <div
      class="color-scheme-toggle"
      role="group"
      aria-labelledby="color-scheme-label"
    >
      <i
        class="pi pi-sun scheme-icon"
        :class="{ 'scheme-icon--active': !isDarkToggle }"
        aria-hidden="true"
      />
      <ToggleSwitch
        id="color-scheme-toggle"
        v-model="isDarkToggle"
        aria-label="Dark mode"
      />
      <i
        class="pi pi-moon scheme-icon"
        :class="{ 'scheme-icon--active': isDarkToggle }"
        aria-hidden="true"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, inject, onMounted, onUnmounted, watch, computed } from 'vue'
import { usePrimeVue } from 'primevue/config'
import ToggleSwitch from 'primevue/toggleswitch'

const THEME_STORAGE_KEY = 'primevue-theme'
const COLOR_SCHEME_CLASS = 'dark'

const presets = inject('primevueThemePresets', {})
const storageKey = inject('primevueThemeStorageKey', THEME_STORAGE_KEY)
const optionsStorageKey = inject('primevueThemeOptionsKey', 'primevue-theme-options')
const primevue = usePrimeVue()

function themeKeyToLabel(key) {
  if (!key) return ''
  const parts = key.split('-')
  return parts.map((p) => p.charAt(0).toUpperCase() + p.slice(1)).join(' ')
}

const themeOptions = computed(() => {
  const keys = Object.keys(presets).sort((a, b) => {
    const [baseA, colorA] = a.includes('-') ? a.split('-') : [a, '']
    const [baseB, colorB] = b.includes('-') ? b.split('-') : [b, '']
    if (baseA !== baseB) return baseA.localeCompare(baseB)
    return (colorA || '').localeCompare(colorB || '')
  })
  return keys.map((value) => ({ label: themeKeyToLabel(value), value }))
})

const selectedKey = ref(getStoredTheme())
const colorScheme = ref(getStoredColorScheme())

/** OS dark preference when color scheme is "system". */
const prefersDark = ref(false)

function readPrefersDark(): boolean {
  if (typeof window === 'undefined') return false
  return window.matchMedia('(prefers-color-scheme: dark)').matches
}

let mediaQuery: MediaQueryList | null = null
function onPrefersColorSchemeChange() {
  prefersDark.value = readPrefersDark()
}

const isDarkToggle = computed({
  get() {
    if (colorScheme.value === 'dark') return true
    if (colorScheme.value === 'light') return false
    return prefersDark.value
  },
  set(v: boolean) {
    colorScheme.value = v ? 'dark' : 'light'
  },
})

function getStoredTheme() {
  if (typeof localStorage === 'undefined') return 'aura'
  return localStorage.getItem(storageKey) || 'aura'
}

function getStoredColorScheme() {
  if (typeof localStorage === 'undefined') return 'system'
  try {
    const raw = localStorage.getItem(optionsStorageKey)
    if (!raw) return 'system'
    const parsed = JSON.parse(raw)
    const v = parsed.darkModeSelector
    if (v === 'system') return 'system'
    if (v === `.${COLOR_SCHEME_CLASS}`) return 'dark'
    return 'light'
  } catch {
    return 'system'
  }
}

function getThemeOptions() {
  const scheme = colorScheme.value
  let darkModeSelector = 'system'
  if (scheme === 'dark') darkModeSelector = `.${COLOR_SCHEME_CLASS}`
  if (scheme === 'light') darkModeSelector = '.p-theme-light-only' // selector we never add = always light
  return { darkModeSelector }
}

function syncHtmlClass() {
  if (typeof document === 'undefined') return
  const root = document.documentElement
  const dark =
    colorScheme.value === 'dark' ||
    (colorScheme.value === 'system' && prefersDark.value)
  if (dark) {
    root.classList.add(COLOR_SCHEME_CLASS)
  } else {
    root.classList.remove(COLOR_SCHEME_CLASS)
  }
}

function persistThemeOptions() {
  try {
    const options = getThemeOptions()
    localStorage.setItem(optionsStorageKey, JSON.stringify(options))
  } catch (e) {
    console.warn('Failed to persist theme options', e)
  }
}

function applyTheme(key) {
  if (!key || !presets[key]) return
  try {
    localStorage.setItem(storageKey, key)
    const options = getThemeOptions()
    primevue.config.theme = { preset: presets[key], options }
  } catch (e) {
    console.warn('Theme change failed', e)
  }
}

function applyColorScheme() {
  syncHtmlClass()
  persistThemeOptions()
  const options = getThemeOptions()
  const current = primevue.config.theme
  if (current?.preset) {
    primevue.config.theme = { preset: current.preset, options }
  }
}

watch(selectedKey, (key) => {
  applyTheme(key)
})

watch(colorScheme, () => {
  applyColorScheme()
})

watch(prefersDark, () => {
  if (colorScheme.value === 'system') {
    syncHtmlClass()
  }
})

onMounted(() => {
  const key = getStoredTheme()
  if (key && key !== selectedKey.value) selectedKey.value = key
  const scheme = getStoredColorScheme()
  if (scheme && scheme !== colorScheme.value) colorScheme.value = scheme
  prefersDark.value = readPrefersDark()
  if (typeof window !== 'undefined') {
    mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    mediaQuery.addEventListener('change', onPrefersColorSchemeChange)
  }
  syncHtmlClass()
})

onUnmounted(() => {
  mediaQuery?.removeEventListener('change', onPrefersColorSchemeChange)
})
</script>

<style scoped>
.theme-picker {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  opacity: 0.72;
  transition: opacity 0.2s ease;
}
.theme-picker:hover,
.theme-picker:focus-within {
  opacity: 1;
}
.theme-picker-label {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
.theme-picker-dropdown {
  min-width: 7.25rem;
  max-width: 9rem;
}
.color-scheme-toggle {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  transform: scale(0.88);
  transform-origin: center center;
}
.scheme-icon {
  font-size: 0.95rem;
  color: var(--p-text-muted-color);
  opacity: 0.35;
  transition: color 0.15s ease, opacity 0.15s ease;
}
.scheme-icon--active {
  color: var(--p-text-color);
  opacity: 0.88;
}
</style>
