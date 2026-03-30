<template>
  <span class="news-text-with-links">
    <template v-if="parsed.authorSegment">
      <router-link v-if="authorId > 0" :to="`/authors/${authorId}`" class="news-entity-link">{{ parsed.authorSegment }}</router-link>
      <span v-else>{{ parsed.authorSegment }}</span>
      <!-- Only show restBeforeEntities when there are no entity links; otherwise entitySegments already includes that leading text -->
      <span v-if="!entitySegments.length">{{ restBeforeEntities }}</span>
    </template>
    <template v-else>
      <span v-if="!entitySegments.length">{{ restBeforeEntities }}</span>
    </template>
    <template v-for="(seg, i) in entitySegments" :key="i">
      <router-link v-if="seg.type === 'object'" :to="`/objects/${seg.id}`" class="news-entity-link">object #{{ seg.id }}</router-link>
      <router-link v-else-if="seg.type === 'model'" :to="`/models/${seg.id}`" class="news-entity-link">model #{{ seg.id }}</router-link>
      <span v-else>{{ seg.value }}</span>
    </template>
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { stripHtmlTags } from '@/utils/stripHtmlTags'

const props = withDefaults(
  defineProps<{
    text: string
    authorId?: number | null
    authorName?: string | null
  }>(),
  { authorId: null, authorName: null }
)

/** Raw DB text with any HTML-like tags removed before link parsing and display. */
const safeText = computed(() => stripHtmlTags(props.text ?? ''))

/** Split text into author prefix (before " has ") and the rest. */
const parsed = computed(() => {
  const t = safeText.value
  const hasIndex = t.indexOf(' has ')
  if (hasIndex < 0) return { authorSegment: null as string | null, restWithHas: t }
  return {
    authorSegment: t.slice(0, hasIndex).trim() || null,
    restWithHas: t.slice(hasIndex),
  }
})

/** The rest including " has " - the part we scan for object # / model #. */
const restBeforeEntities = computed(() => {
  const rest = parsed.value.restWithHas
  const re = /(object #\d+)|(model #\d+)/gi
  const first = re.exec(rest)
  if (!first) return rest
  return rest.slice(0, first.index)
})

/** Segments after the author part: text, object #n, model #n. */
const entitySegments = computed(() => {
  const rest = parsed.value.restWithHas
  const segments: { type: 'text' | 'object' | 'model'; value?: string; id?: number }[] = []
  const re = /(object #(\d+))|(model #(\d+))/gi
  let lastIndex = 0
  let m: RegExpExecArray | null
  while ((m = re.exec(rest)) !== null) {
    if (m.index > lastIndex) {
      segments.push({ type: 'text', value: rest.slice(lastIndex, m.index) })
    }
    if (m[2]) segments.push({ type: 'object', id: parseInt(m[2], 10) })
    else if (m[4]) segments.push({ type: 'model', id: parseInt(m[4], 10) })
    lastIndex = re.lastIndex
  }
  if (lastIndex < rest.length) {
    segments.push({ type: 'text', value: rest.slice(lastIndex) })
  }
  return segments
})
</script>

<style scoped>
.news-text-with-links { color: var(--p-text-color); }
.news-entity-link { color: var(--p-primary-color); text-decoration: none; }
.news-entity-link:hover { text-decoration: underline; }
</style>
