<template>
  <span
    v-if="linked"
    class="author-idp-badge"
    role="img"
    :aria-label="hint"
    :title="hint"
  >
    <i class="pi pi-shield" aria-hidden="true" />
  </span>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    /** Author has an OAuth-linked account (fgs_extuserids); badge shows "Verified identity" on hover. */
    linked?: boolean
  }>(),
  { linked: false }
)

const hint = 'Verified identity'
</script>

<style scoped>
.author-idp-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--p-text-muted-color, #64748b);
  font-size: 0.9em;
  vertical-align: middle;
}
.author-idp-badge .pi {
  line-height: 1;
}
</style>
