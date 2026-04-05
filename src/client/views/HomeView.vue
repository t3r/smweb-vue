<template>
  <div>
    <h1 class="mt-0">FlightGear Scenery Repository</h1>
    <p class="text-color-secondary mb-4">
      Welcome to the New FlightGear Scenery Repository.
    </p>
    <p>
    For decades, our PHP-based scenery platform has been a trusted cornerstone of the FlightGear community — reliably serving thousands of 3D object placements and worldwide position data to simmers across the globe. <br />
Now we've rebuilt it from the ground up. The new platform is based on a modern Vue 3 + Node.js + PostgreSQL architecture, is fully open source, and available on <a href="https://github.com/t3r/smweb-vue">GitHub</a>.
</p>
<p>The codebase is backed by hundreds of automated tests and a continuous build and deployment pipeline, so contributions are easier, improvements and fixes reach you faster.<br />
Dependencies are kept up to date automatically via Dependabot, keeping the platform secure and maintainable long into the future. <br />
Contributing to the dataset has never been easier. A streamlined workflow lets community members submit and manage 3D scenery objects and their geographic positions with less friction, while a cleaner review process helps maintainers evaluate and approve contributions efficiently. <br />
Role-based access control ensures that contributors, reviewers, and administrators each have clearly defined permissions — keeping collaboration both open and well-organized.
</p>
<p>Same trusted data. Modern tools. <br />
Built by the community, for the community.</p>

    <h2>Temporarily limited write access</h2>
    <p>During an initial phase, this site restricts contributions to Admins only. <br />
    We want to make sure everything works as expected before opening all service for public access. </br >
    Feel free to look around. The old site is still available at <a href="https://legacy.scenery.flightgear.org">https://legacy.scenery.flightgear.org</a>.
    </p>
    <Card class="mb-4">
      <template #title>Statistics</template>
      <template #content>
        <p v-if="statsLoading" class="m-0">Loading…</p>
        <p v-else class="m-0">
          {{ stats.models }} models · {{ stats.objects }} objects · {{ stats.authors }} authors ·
          {{ stats.pendingRequests }}
          pending request{{ stats.pendingRequests === 1 ? '' : 's' }}
        </p>
      </template>
    </Card>

    <Card class="mb-4">
      <template #title>News</template>
      <template #content>
        <p v-if="newsLoading" class="m-0">Loading…</p>
        <p v-else-if="newsError" class="m-0 text-color-secondary">{{ newsError }}</p>
        <template v-else-if="news.length">
          <ul class="news-list list-none p-0 m-0">
            <li v-for="item in news" :key="item.id" class="news-item py-2 border-bottom-1 surface-border">
              <span class="news-date text-color-secondary">{{ formatNewsDate(item.timestamp) }}</span>
              <NewsTextWithLinks :text="item.text" :author-id="item.authorId" :author-name="item.authorName" />
            </li>
          </ul>
          <div class="mt-2">
            <router-link to="/news" class="news-more-link">
              <Button label="More" icon="pi pi-arrow-right" icon-pos="right" text size="small" />
            </router-link>
          </div>
        </template>
        <p v-else class="m-0 text-color-secondary">No news yet.</p>
      </template>
    </Card>

    <div class="grid grid-nogutter gap-4">
      <Card>
        <template #title>Recently updated objects</template>
        <template #content>
          <p v-if="recentObjectsLoading" class="m-0">Loading…</p>
          <p v-else-if="recentObjectsError" class="m-0 text-color-secondary">Could not load this list.</p>
          <p v-else-if="!recentObjects.length" class="m-0 text-color-secondary">No objects yet.</p>
          <ul v-else class="list-none p-0 m-0">
            <li v-for="obj in recentObjects" :key="obj.id" class="flex align-items-center gap-2 py-2 border-bottom-1 surface-border">
              <img
                :src="thumbnailUrl(obj.modelId)"
                :alt="obj.description || 'Object'"
                class="object-thumb"
                @error="onThumbError"
              />
              <router-link :to="`/objects/${obj.id}`" class="object-model-link">{{ obj.description || 'Unnamed' }}</router-link>
            </li>
          </ul>
        </template>
      </Card>
      <Card>
        <template #title>Recently updated models</template>
        <template #content>
          <p v-if="recentModelsLoading" class="m-0">Loading…</p>
          <p v-else-if="recentModelsError" class="m-0 text-color-secondary">Could not load this list.</p>
          <p v-else-if="!recentModels.length" class="m-0 text-color-secondary">No models yet.</p>
          <ul v-else class="list-none p-0 m-0">
            <li v-for="model in recentModels" :key="model.id" class="flex align-items-center gap-2 py-2 border-bottom-1 surface-border">
              <img
                :src="thumbnailUrl(model.id)"
                :alt="model.name || 'Model'"
                class="object-thumb"
                @error="onThumbError"
              />
              <router-link :to="`/models/${model.id}`" class="object-model-link">{{ model.name || model.filename || 'Unnamed' }}</router-link>
            </li>
          </ul>
        </template>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import Button from 'primevue/button'
import NewsTextWithLinks from '@/components/NewsTextWithLinks.vue'
import { useAuthStore } from '@/stores/auth'
import { useAppToast } from '@/composables/useAppToast'

const HOME_NEWS_LIMIT = 5
const auth = useAuthStore()
const { toastInfo, toastWarn } = useAppToast()
let authHintToasted = false

interface NewsItem {
  id: number
  timestamp: string
  authorId: number
  authorName: string | null
  text: string
}

const stats = ref({ models: 0, objects: 0, authors: 0, pendingRequests: 0 })
const statsLoading = ref(true)
const recentObjects = ref([])
const recentObjectsLoading = ref(true)
const recentObjectsError = ref<string | null>(null)
const recentModels = ref([])
const recentModelsLoading = ref(true)
const recentModelsError = ref<string | null>(null)
const news = ref<NewsItem[]>([])
const newsLoading = ref(true)
const newsError = ref<string | null>(null)

function formatNewsDate(iso: string) {
  if (!iso) return '—'
  try {
    const d = new Date(iso)
    return d.toLocaleDateString(undefined, { dateStyle: 'short' })
  } catch {
    return iso
  }
}

function thumbnailUrl(modelId: number) {
  return `/api/models/${modelId}/thumbnail`
}

function onThumbError(e: Event) {
  const t = e.target as HTMLImageElement
  if (t) t.style.display = 'none'
}

watch(
  () => [auth.loaded, auth.isAuthenticated] as const,
  ([loaded, isAuthed]) => {
    if (!loaded || isAuthed || authHintToasted) return
    authHintToasted = true
    toastInfo(
      'You need to be signed in to place a model request. This may change once the system is stable.',
      'Signing in'
    )
  },
  { immediate: true }
)

watch(newsError, (msg) => {
  if (msg) toastWarn(msg, 'News')
})

watch(recentObjectsError, (msg) => {
  if (msg) toastWarn(msg, 'Recent objects')
})

watch(recentModelsError, (msg) => {
  if (msg) toastWarn(msg, 'Recent models')
})

onMounted(async () => {
  try {
    const res = await fetch('/api/statistics')
    if (res.ok) {
      const data = await res.json()
      stats.value = {
        models: data.models ?? 0,
        objects: data.objects ?? 0,
        authors: data.authors ?? 0,
        pendingRequests: data.pendingRequests ?? 0,
      }
    }
  } catch (_) { /* ignore */ }
  finally {
    statsLoading.value = false
  }

  try {
    const res = await fetch('/api/objects?limit=10&offset=0')
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    recentObjects.value = data.objects || []
  } catch (err) {
    recentObjectsError.value = (err as Error).message || 'Failed to load objects'
  } finally {
    recentObjectsLoading.value = false
  }

  try {
    const res = await fetch('/api/models/recent')
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    recentModels.value = data.models || []
  } catch (err) {
    recentModelsError.value = (err as Error).message || 'Failed to load models'
  } finally {
    recentModelsLoading.value = false
  }

  try {
    const res = await fetch(`/api/news?limit=${HOME_NEWS_LIMIT}&offset=0`)
    if (!res.ok) throw new Error(res.statusText)
    const data = await res.json()
    const raw = (data.news ?? []) as NewsItem[]
    news.value = raw.filter((n, i, a) => a.findIndex((x) => x.id === n.id) === i)
  } catch (err) {
    newsError.value = (err as Error).message || 'Failed to load news'
  } finally {
    newsLoading.value = false
  }
})
</script>

<style scoped>
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
@media (max-width: 768px) { .grid { grid-template-columns: 1fr; } }
.object-thumb { width: 80px; height: 60px; object-fit: cover; border-radius: 4px; flex-shrink: 0; }
.list-none { list-style: none; }
.p-0 { padding: 0; }
.m-0 { margin: 0; }
.mb-4 { margin-bottom: 1rem; }
.mt-0 { margin-top: 0; }
.gap-4 { gap: 1rem; }
.gap-2 { gap: 0.5rem; }
.py-2 { padding-top: 0.5rem; padding-bottom: 0.5rem; }
.flex { display: flex; }
.align-items-center { align-items: center; }
.border-bottom-1 { border-bottom: 1px solid var(--p-content-border-color, #e2e8f0); }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
.object-model-link { color: var(--p-primary-color); text-decoration: none; }
.object-model-link:hover { text-decoration: underline; }
.news-list { display: flex; flex-direction: column; gap: 0.25rem; }
.news-item { display: flex; flex-direction: column; gap: 0.15rem; }
.news-date { font-size: 0.8rem; }
.news-text { font-size: 0.9rem; color: var(--p-text-color); }
.news-more-link { text-decoration: none; color: var(--p-primary-color); }
.mt-2 { margin-top: 0.5rem; }
</style>
