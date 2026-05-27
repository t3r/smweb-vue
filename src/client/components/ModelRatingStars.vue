<template>
  <div class="model-rating-stars" :class="{ 'model-rating-stars--compact': compact }">
    <div
      class="model-rating-stars__row"
      :class="{ 'model-rating-stars__row--interactive': interactive }"
      role="img"
      :aria-label="ariaLabel"
    >
      <button
        v-for="star in 5"
        :key="star"
        type="button"
        class="model-rating-stars__star"
        :class="starClass(star)"
        :disabled="!interactive || saving"
        :aria-label="interactive ? `Rate ${star} out of 5` : undefined"
        :aria-pressed="interactive && displayScore === star ? 'true' : 'false'"
        @click="onStarClick(star)"
        @mouseenter="interactive ? (hoverScore = star) : null"
        @mouseleave="interactive ? (hoverScore = 0) : null"
      >
        <i :class="star >= filledThreshold ? 'pi pi-star-fill' : 'pi pi-star'" aria-hidden="true" />
      </button>
    </div>
    <p v-if="showSummary" class="model-rating-stars__summary m-0 text-color-secondary">
      <template v-if="ratingCount > 0 && ratingAverage != null">
        {{ ratingAverage.toFixed(1) }} · {{ ratingCount }} {{ ratingCount === 1 ? 'rating' : 'ratings' }}
      </template>
      <template v-else>No ratings yet</template>
      <span v-if="interactive && !auth.isAuthenticated" class="model-rating-stars__hint">
        · <router-link :to="{ path: '/', query: { loginRequired: '1' } }">Sign in</router-link> to rate
      </span>
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const props = withDefaults(
  defineProps<{
    modelId: number
    ratingAverage?: number | null
    ratingCount?: number
    userRating?: number | null
    /** Allow signed-in users to submit a rating. */
    interactive?: boolean
    compact?: boolean
    showSummary?: boolean
  }>(),
  {
    ratingAverage: null,
    ratingCount: 0,
    userRating: null,
    interactive: false,
    compact: false,
    showSummary: true,
  }
)

const emit = defineEmits<{
  rated: [payload: { ratingAverage: number | null; ratingCount: number; userRating: number }]
}>()

const auth = useAuthStore()
const hoverScore = ref(0)
const saving = ref(false)

const displayScore = computed(() => {
  if (hoverScore.value > 0) return hoverScore.value
  if (props.userRating != null && props.userRating > 0) return props.userRating
  if (props.ratingAverage != null && props.ratingCount > 0) return Math.round(props.ratingAverage)
  return 0
})

const filledThreshold = computed(() => displayScore.value)

const ariaLabel = computed(() => {
  if (props.ratingCount > 0 && props.ratingAverage != null) {
    return `Average rating ${props.ratingAverage.toFixed(1)} out of 5 from ${props.ratingCount} ratings`
  }
  return 'No ratings yet'
})

function starClass(star: number) {
  return {
    'model-rating-stars__star--on': star <= filledThreshold.value,
    'model-rating-stars__star--off': star > filledThreshold.value,
  }
}

async function onStarClick(star: number) {
  if (!props.interactive || saving.value || !auth.isAuthenticated) return
  saving.value = true
  try {
    const res = await fetch(auth.apiUrl(`/api/models/${props.modelId}/rating`), {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ score: star }),
    })
    const data = await res.json().catch(() => ({}))
    if (!res.ok) {
      throw new Error((data as { error?: string }).error || res.statusText)
    }
    emit('rated', {
      ratingAverage: (data as { ratingAverage?: number | null }).ratingAverage ?? null,
      ratingCount: Number((data as { ratingCount?: number }).ratingCount) || 0,
      userRating: Number((data as { userRating?: number }).userRating) || star,
    })
  } catch {
    /* parent may show toast; keep UI unchanged on failure */
  } finally {
    saving.value = false
    hoverScore.value = 0
  }
}
</script>

<style scoped>
.model-rating-stars__row {
  display: inline-flex;
  gap: 0.1rem;
  align-items: center;
}
.model-rating-stars__row--interactive .model-rating-stars__star {
  cursor: pointer;
}
.model-rating-stars__star {
  border: none;
  background: transparent;
  padding: 0;
  line-height: 1;
  color: var(--p-text-muted-color, #94a3b8);
  font-size: 1.1rem;
}
.model-rating-stars--compact .model-rating-stars__star {
  font-size: 0.95rem;
}
.model-rating-stars__star--on {
  color: var(--p-yellow-500, #eab308);
}
.model-rating-stars__star:disabled {
  cursor: default;
}
.model-rating-stars__summary {
  margin-top: 0.25rem;
  font-size: 0.8125rem;
}
.model-rating-stars--compact .model-rating-stars__summary {
  font-size: 0.75rem;
}
.model-rating-stars__hint a {
  color: var(--p-primary-color);
  text-decoration: none;
}
.model-rating-stars__hint a:hover {
  text-decoration: underline;
}
.m-0 {
  margin: 0;
}
.text-color-secondary {
  color: var(--p-text-muted-color, #64748b);
}
</style>
