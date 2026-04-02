<template>
  <Panel :header="headerTitle" :class="{ 'model-details-card': true, 'model-details-card--compact': compact }">
    <div class="model-details-row">
      <div class="model-details-text">
        <p v-if="model.filename" class="m-0 mb-2">Filename: {{ model.filename }}</p>
        <p v-if="authorDisplay" class="m-0 mb-2 author-line">
          Author:
          <template v-if="authorDisplay.type === 'link'">
            <router-link :to="`/authors/${authorDisplay.id}`">{{ authorDisplay.name }}</router-link>
            <router-link v-if="model.id" :to="`/models?author=${authorDisplay.id}`" class="more-from-author">more from this author</router-link>
          </template>
          <span v-else>{{ authorDisplay.text }}</span>
        </p>
        <p v-if="model.description" class="m-0 mb-2 text-color-secondary">Description: {{ model.description }}</p>
        <router-link
          v-if="model.id"
          :to="{ path: '/objects', query: { model: String(model.id) } }"
        >
          Browse objects using this model
        </router-link>
      </div>
      <div v-if="showRightVisual" class="model-details-thumb">
        <template v-if="model.id != null">
          <img
            :src="thumbnailUrl"
            :alt="model.name || model.filename || 'Model'"
            class="model-details-thumb-img"
            @error="onThumbError"
          />
        </template>
        <template v-else-if="requestSig">
          <div class="model-details-request-thumb">
            <div v-if="requestThumbPending" class="model-details-thumb-placeholder" aria-hidden="true">
              <i class="pi pi-spin pi-spinner" />
            </div>
            <img
              v-show="!requestThumbFailed"
              :src="requestThumbnailSrc"
              :alt="model.name || model.filename || 'Model thumbnail'"
              class="model-details-thumb-img"
              @load="onRequestThumbLoad"
              @error="onRequestThumbError"
            />
            <p v-if="requestThumbFailed" class="model-details-thumb-missing m-0 text-color-secondary">No thumbnail</p>
          </div>
        </template>
      </div>
    </div>
  </Panel>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Panel from 'primevue/panel'
import { useAuthStore } from '@/stores/auth'

export interface ModelAuthor {
  id: number
  name?: string
}

export interface ModelDetailsModel {
  id?: number
  name?: string
  filename?: string
  description?: string
  /** From API: { id, name }. From request overview: may be author id (number) */
  author?: ModelAuthor | number
}

export interface AuthorOverride {
  name: string
  email?: string
}

const auth = useAuthStore()

const props = withDefaults(
  defineProps<{
    model: ModelDetailsModel
    /** When set (e.g. MODEL_ADD request with new author), shown as author text when model.author has no id */
    authorOverride?: AuthorOverride | null
    compact?: boolean
    /** MODEL_ADD review: show stored 320×240 submission thumbnail (reviewer-only URL). */
    requestSig?: string | null
  }>(),
  { authorOverride: null, compact: false, requestSig: null }
)

const headerTitle = computed(() => props.model.name || props.model.filename || (props.model.id != null ? `Model #${props.model.id}` : 'Model'))

const thumbnailUrl = computed(() => (props.model.id != null ? `/api/models/${props.model.id}/thumbnail` : ''))

const showRightVisual = computed(() => props.model.id != null || !!props.requestSig)

const requestThumbnailSrc = computed(() => {
  if (props.model.id != null || !props.requestSig) return ''
  return auth.apiUrl(`/api/position-requests/${encodeURIComponent(props.requestSig)}/thumbnail`)
})

const requestThumbPending = ref(false)
const requestThumbFailed = ref(false)

watch(
  requestThumbnailSrc,
  (url) => {
    requestThumbFailed.value = false
    requestThumbPending.value = !!url
  },
  { immediate: true }
)

function onRequestThumbLoad() {
  requestThumbPending.value = false
}

function onRequestThumbError() {
  requestThumbPending.value = false
  requestThumbFailed.value = true
}

const authorDisplay = computed(() => {
  const a = props.model.author
  if (a != null && typeof a === 'object' && a.id != null) return { type: 'link' as const, id: a.id, name: a.name || `Author #${a.id}` }
  if (props.authorOverride?.name) {
    return { type: 'text' as const, text: props.authorOverride.email ? `${props.authorOverride.name} (${props.authorOverride.email})` : props.authorOverride.name }
  }
  if (typeof a === 'number') return { type: 'text' as const, text: `Author #${a}` }
  return null
})

function onThumbError(e: Event) {
  (e.target as HTMLImageElement).style.display = 'none'
}
</script>

<style scoped>
.model-details-row {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: 1rem;
}
.model-details-text {
  flex: 0 1 auto;
  min-width: 0;
  width: fit-content;
  max-width: 100%;
}
.model-details-thumb {
  flex-shrink: 0;
}
/* 320×240 submission / model thumbnails — 4:3 box, scaled down */
.model-details-thumb-img {
  width: 120px;
  height: 90px;
  object-fit: contain;
  object-position: left top;
  border-radius: 6px;
  background: var(--p-surface-100, #f1f5f9);
  border: 1px solid var(--p-content-border-color, rgba(0, 0, 0, 0.08));
  display: block;
}
.model-details-card--compact .model-details-thumb-img {
  width: 80px;
  height: 60px;
}
.model-details-request-thumb {
  position: relative;
  min-width: 120px;
  min-height: 90px;
}
.model-details-card--compact .model-details-request-thumb {
  min-width: 80px;
  min-height: 60px;
}
.model-details-thumb-placeholder {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.25rem;
  color: var(--p-text-muted-color);
  background: var(--p-surface-100, #f1f5f9);
  border-radius: 6px;
  border: 1px solid var(--p-content-border-color, rgba(0, 0, 0, 0.08));
}
.model-details-card--compact .model-details-thumb-placeholder {
  font-size: 1rem;
}
.model-details-thumb-missing {
  font-size: 0.8rem;
  padding: 0.25rem 0;
  max-width: 120px;
}
.model-details-card--compact .model-details-thumb-missing {
  max-width: 80px;
}
.author-line {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.5rem;
}
.more-from-author {
  font-size: 0.875rem;
  opacity: 0.85;
}
.m-0 { margin: 0; }
.mb-2 { margin-bottom: 0.5rem; }
.text-color-secondary { color: var(--p-text-muted-color, #64748b); }
</style>
