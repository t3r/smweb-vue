<template>
  <div>
    <h1 class="mt-0">News</h1>
    <p class="text-color-secondary mb-4">Recent activity: processed position requests and other updates.</p>

    <p v-if="loading" class="m-0">Loading…</p>
    <template v-else-if="news.length">
      <ul class="news-full-list list-none p-0 m-0">
        <li v-for="item in news" :key="item.id" class="news-full-item py-3 border-bottom-1 surface-border">
          <span class="news-full-date text-color-secondary">{{ formatNewsDate(item.timestamp) }}</span>
          <p class="news-full-text m-0 mt-1">
            <NewsTextWithLinks :text="item.text" :author-id="item.authorId" :author-name="item.authorName" />
          </p>
        </li>
      </ul>
      <div v-if="hasMore" class="mt-3">
        <Button label="Load more" icon="pi pi-chevron-down" :loading="loadingMore" @click="loadMore" />
      </div>
    </template>
    <p v-else-if="initialLoadOk" class="m-0 text-color-secondary">No news yet.</p>
    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import Button from 'primevue/button'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
import NewsTextWithLinks from '@/components/NewsTextWithLinks.vue'

const PAGE_SIZE = 20

interface NewsItem {
  id: number
  timestamp: string
  authorId: number
  authorName: string | null
  text: string
}

const news = ref<NewsItem[]>([])
const total = ref(0)
const loading = ref(true)
const loadingMore = ref(false)
const initialLoadOk = ref(false)
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()

const hasMore = ref(false)

function formatNewsDate(iso: string) {
  if (!iso) return '—'
  try {
    const d = new Date(iso)
    return d.toLocaleDateString(undefined, { dateStyle: 'medium' })
  } catch {
    return iso
  }
}

async function fetchNews(offset: number, append: boolean) {
  const res = await fetch(`/api/news?limit=${PAGE_SIZE}&offset=${offset}`)
  if (!res.ok) throw new Error(res.statusText)
  const data = await res.json()
  const items = (data.news ?? []) as NewsItem[]
  const totalCount = Number(data.total ?? 0)
  const dedupe = (arr: NewsItem[]) => arr.filter((n, i, a) => a.findIndex((x) => x.id === n.id) === i)
  if (append) {
    news.value = dedupe([...news.value, ...items])
  } else {
    news.value = dedupe(items)
  }
  total.value = totalCount
  hasMore.value = news.value.length < totalCount
}

async function loadMore() {
  loadingMore.value = true
  clearError()
  try {
    await fetchNews(news.value.length, true)
  } catch (err) {
    showError((err as Error).message || 'Failed to load more')
  } finally {
    loadingMore.value = false
  }
}

onMounted(async () => {
  loading.value = true
  initialLoadOk.value = false
  clearError()
  try {
    await fetchNews(0, false)
    initialLoadOk.value = true
  } catch (err) {
    showError((err as Error).message || 'Failed to load news')
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.list-none { list-style: none; }
.p-0 { padding: 0; }
.m-0 { margin: 0; }
.mt-0 { margin-top: 0; }
.mt-1 { margin-top: 0.25rem; }
.mt-3 { margin-top: 0.75rem; }
.mb-3 { margin-bottom: 0.75rem; }
.mb-4 { margin-bottom: 1rem; }
.text-color-secondary { color: var(--p-text-muted-color); }
.border-bottom-1 { border-bottom: 1px solid var(--p-content-border-color, #e2e8f0); }
.news-full-list { display: flex; flex-direction: column; gap: 0; }
.news-full-item { display: flex; flex-direction: column; }
.news-full-date { font-size: 0.8rem; }
.news-full-text { font-size: 0.95rem; color: var(--p-text-color); }
</style>
