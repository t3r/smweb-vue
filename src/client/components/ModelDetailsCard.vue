<template>
  <Panel :header="headerTitle" :class="{ 'model-details-card': true, 'model-details-card--compact': compact }">
    <div class="model-details-row">
      <div v-if="showThumbnail" class="model-details-thumb">
        <img
          :src="thumbnailUrl"
          :alt="model.name || model.filename || 'Model'"
          class="model-details-thumb-img"
          @error="onThumbError"
        />
      </div>
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
    </div>
  </Panel>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import Panel from 'primevue/panel'

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

const props = withDefaults(
  defineProps<{
    model: ModelDetailsModel
    /** When set (e.g. MODEL_ADD request with new author), shown as author text when model.author has no id */
    authorOverride?: AuthorOverride | null
    compact?: boolean
  }>(),
  { authorOverride: null, compact: false }
)

const headerTitle = computed(() => props.model.name || props.model.filename || (props.model.id != null ? `Model #${props.model.id}` : 'Model'))

const showThumbnail = computed(() => props.model.id != null)

const thumbnailUrl = computed(() => (props.model.id != null ? `/api/models/${props.model.id}/thumbnail` : ''))

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
  align-items: flex-start;
  gap: 1rem;
}
.model-details-thumb {
  flex-shrink: 0;
}
.model-details-text {
  flex: 1;
  min-width: 0;
}
.model-details-thumb-img {
  width: 120px;
  height: 120px;
  object-fit: cover;
  border-radius: 6px;
}
.model-details-card--compact .model-details-thumb-img {
  width: 80px;
  height: 80px;
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
