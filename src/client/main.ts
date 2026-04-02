import { createApp } from 'vue'
import { createPinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import { definePreset } from '@primeuix/themes'
import Aura from '@primeuix/themes/aura'
import Lara from '@primeuix/themes/lara'
import Nora from '@primeuix/themes/nora'
import Material from '@primeuix/themes/material'
import 'primeicons/primeicons.css'
import App from './App.vue'
import router from './router'

import Menubar from 'primevue/menubar'
import Card from 'primevue/card'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Select from 'primevue/select'
import Breadcrumb from 'primevue/breadcrumb'
import Button from 'primevue/button'
import Toast from 'primevue/toast'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Skeleton from 'primevue/skeleton'
import Panel from 'primevue/panel'
import Tag from 'primevue/tag'
import Menu from 'primevue/menu'

const THEME_STORAGE_KEY = 'primevue-theme'

const COLOR_KEYS = ['blue', 'indigo', 'violet', 'purple', 'teal', 'green', 'amber', 'cyan', 'pink', 'lime', 'emerald'] as const

function buildThemeRegistry(): Record<string, unknown> {
  const presets = { Aura, Lara, Nora, Material }
  const registry: Record<string, unknown> = {}
  for (const [presetName, Preset] of Object.entries(presets)) {
    const key = presetName.toLowerCase()
    registry[key] = Preset
    const primitive = (Preset as { primitive?: Record<string, unknown> })?.primitive || {}
    for (const color of COLOR_KEYS) {
      if (primitive[color]) {
        const variantKey = `${key}-${color}`
        registry[variantKey] = definePreset(Preset as Parameters<typeof definePreset>[0], {
          semantic: {
            primary: primitive[color],
          },
        })
      }
    }
  }
  return registry
}

const PRESETS = buildThemeRegistry()

const THEME_OPTIONS_STORAGE_KEY = 'primevue-theme-options'
const DEFAULT_DARK_MODE_SELECTOR = 'system'

interface ThemeOptions {
  darkModeSelector?: string
}

function getStoredThemeOptions(): ThemeOptions {
  if (typeof localStorage === 'undefined') return {}
  try {
    const raw = localStorage.getItem(THEME_OPTIONS_STORAGE_KEY)
    if (!raw) return {}
    const parsed = JSON.parse(raw) as { darkModeSelector?: string }
    return typeof parsed.darkModeSelector === 'string' ? { darkModeSelector: parsed.darkModeSelector } : {}
  } catch {
    return {}
  }
}

const initialThemeKey = typeof localStorage !== 'undefined'
  ? (localStorage.getItem(THEME_STORAGE_KEY) || 'aura')
  : 'aura'
const initialPreset = PRESETS[initialThemeKey] || Aura
const storedOptions = getStoredThemeOptions()
const initialOptions: ThemeOptions = { darkModeSelector: storedOptions.darkModeSelector || DEFAULT_DARK_MODE_SELECTOR }

if (typeof document !== 'undefined') {
  if (initialOptions.darkModeSelector === '.dark') {
    document.documentElement.classList.add('dark')
  } else if (
    initialOptions.darkModeSelector === 'system' &&
    typeof window !== 'undefined' &&
    window.matchMedia('(prefers-color-scheme: dark)').matches
  ) {
    document.documentElement.classList.add('dark')
  }
}

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.use(PrimeVue, {
  theme: {
    preset: initialPreset,
    options: initialOptions,
  },
})
app.use(ToastService)
app.provide('primevueThemePresets', PRESETS)
app.provide('primevueThemeStorageKey', THEME_STORAGE_KEY)
app.provide('primevueThemeOptionsKey', THEME_OPTIONS_STORAGE_KEY)

app.component('Menubar', Menubar)
app.component('Card', Card)
app.component('DataTable', DataTable)
app.component('Column', Column)
app.component('Select', Select)
app.component('Breadcrumb', Breadcrumb)
app.component('Button', Button)
app.component('Toast', Toast)
app.component('InputText', InputText)
app.component('Textarea', Textarea)
app.component('Skeleton', Skeleton)
app.component('Panel', Panel)
app.component('Tag', Tag)
app.component('Menu', Menu)

app.mount('#app')
