<template>
  <span v-if="!isTexture" class="texture-fn-wrap">
    <a :href="href" :download="name" class="file-link">{{ name }}</a>
  </span>
  <span
    v-else
    ref="anchorRef"
    class="texture-fn-wrap texture-fn-wrap--texture"
    @mouseenter="onEnter"
    @mouseleave="onLeave"
  >
    <a :href="href" :download="name" class="file-link texture-fn-link">{{ name }}</a>
    <Teleport to="body">
      <div
        v-show="open"
        ref="popRef"
        class="texture-fn-popover"
        :style="popoverStyle"
        role="tooltip"
        @mouseenter="cancelClose"
        @mouseleave="scheduleClose"
      >
        <div class="texture-fn-popover__title">{{ name }}</div>
        <div class="texture-fn-popover__dims">{{ dimLine }}</div>
        <div v-if="previewUrl" class="texture-fn-popover__thumb-wrap">
          <img :src="previewUrl" alt="" class="texture-fn-popover__thumb" />
        </div>
        <div v-else-if="previewLoading" class="texture-fn-popover__thumb-msg">Loading preview…</div>
      </div>
    </Teleport>
  </span>
</template>

<script setup lang="ts">
import { ref, computed, watch, onBeforeUnmount } from 'vue'
import { formatTextureDimensions } from '@/utils/textureFileMeta'

const props = defineProps<{
  name: string
  href: string
  isTexture: boolean
  /** Resolved size; `undefined` = not yet known, `null` = unsupported or failed */
  dimensions: { width: number; height: number } | null | undefined
}>()

const anchorRef = ref<HTMLElement | null>(null)
const popRef = ref<HTMLElement | null>(null)
const open = ref(false)
const popoverStyle = ref<Record<string, string>>({})
let closeTimer: ReturnType<typeof setTimeout> | null = null

const previewUrl = ref<string | null>(null)
const previewLoading = ref(false)

const dimLine = computed(() => {
  if (props.dimensions === undefined) return 'Measuring…'
  return formatTextureDimensions(props.dimensions ?? null)
})

function positionPopover() {
  const el = anchorRef.value
  if (!el) return
  const r = el.getBoundingClientRect()
  const margin = 8
  const popW = 220
  let left = r.left + r.width / 2 - popW / 2
  left = Math.max(margin, Math.min(left, window.innerWidth - popW - margin))
  let top = r.bottom + margin
  const estH = 200
  if (top + estH > window.innerHeight - margin) {
    top = Math.max(margin, r.top - estH - margin)
  }
  popoverStyle.value = {
    position: 'fixed',
    left: `${left}px`,
    top: `${top}px`,
    width: `${popW}px`,
    zIndex: '6000',
  }
}

async function ensurePreview() {
  if (!props.isTexture || !props.href || props.href === '#') return
  if (previewUrl.value || previewLoading.value) return
  previewLoading.value = true
  try {
    const res = await fetch(props.href, { credentials: 'include' })
    if (!res.ok) return
    const blob = await res.blob()
    previewUrl.value = URL.createObjectURL(blob)
  } catch {
    /* no preview */
  } finally {
    previewLoading.value = false
  }
}

function bindPopoverPositionListeners() {
  unbindPopoverPositionListeners()
  window.addEventListener('scroll', positionPopover, true)
  window.addEventListener('resize', positionPopover)
}

function unbindPopoverPositionListeners() {
  window.removeEventListener('scroll', positionPopover, true)
  window.removeEventListener('resize', positionPopover)
}

function onEnter() {
  if (closeTimer) {
    clearTimeout(closeTimer)
    closeTimer = null
  }
  open.value = true
  requestAnimationFrame(() => {
    positionPopover()
    bindPopoverPositionListeners()
    void ensurePreview()
  })
}

function scheduleClose() {
  if (closeTimer) clearTimeout(closeTimer)
  closeTimer = setTimeout(() => {
    closeTimer = null
    open.value = false
    unbindPopoverPositionListeners()
  }, 180)
}

function cancelClose() {
  if (closeTimer) {
    clearTimeout(closeTimer)
    closeTimer = null
  }
}

function onLeave() {
  scheduleClose()
}

watch(open, (v) => {
  if (!v) {
    unbindPopoverPositionListeners()
    if (previewUrl.value) {
      URL.revokeObjectURL(previewUrl.value)
      previewUrl.value = null
    }
  }
})

watch(
  () => props.href,
  () => {
    if (previewUrl.value) {
      URL.revokeObjectURL(previewUrl.value)
      previewUrl.value = null
    }
  }
)

onBeforeUnmount(() => {
  unbindPopoverPositionListeners()
  if (closeTimer) clearTimeout(closeTimer)
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
})
</script>

<style scoped>
.texture-fn-wrap--texture {
  position: relative;
}
.texture-fn-wrap .file-link {
  color: var(--p-primary-color);
  text-decoration: none;
}
.texture-fn-wrap .file-link:hover {
  text-decoration: underline;
}
.texture-fn-link {
  text-decoration: underline;
  text-decoration-style: dotted;
  text-underline-offset: 2px;
}
</style>

<style>
.texture-fn-popover {
  pointer-events: auto;
  padding: 10px 12px;
  border-radius: 8px;
  background: var(--p-surface-0, #fff);
  color: var(--p-text-color, #0f172a);
  border: 1px solid var(--p-content-border-color, rgba(0, 0, 0, 0.12));
  box-shadow: 0 8px 28px rgba(0, 0, 0, 0.15);
}
.dark .texture-fn-popover {
  background: var(--p-surface-800, #1e293b);
  color: var(--p-surface-0, #f8fafc);
  border-color: rgba(255, 255, 255, 0.12);
}
.texture-fn-popover__title {
  font-weight: 600;
  font-size: 0.8125rem;
  word-break: break-all;
  margin-bottom: 4px;
}
.texture-fn-popover__dims {
  font-size: 0.875rem;
  font-variant-numeric: tabular-nums;
  margin-bottom: 8px;
}
.texture-fn-popover__thumb-wrap {
  border-radius: 4px;
  overflow: hidden;
  background: var(--p-surface-100, #f1f5f9);
  text-align: center;
}
.dark .texture-fn-popover__thumb-wrap {
  background: var(--p-surface-900, #0f172a);
}
.texture-fn-popover__thumb {
  max-width: 100%;
  max-height: 140px;
  object-fit: contain;
  vertical-align: middle;
}
.texture-fn-popover__thumb-msg {
  font-size: 0.75rem;
  margin: 0;
  color: var(--p-text-muted-color, #64748b);
}
</style>
