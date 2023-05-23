<script setup>
const props = defineProps(["id"]);
</script>
<template>
  <RouterLink :to="{
    name: 'Models',
    query: { shared: id }
  }">
    <slot />
  </RouterLink>
</template>
