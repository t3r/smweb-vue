<script setup>
const props = defineProps(["id"]);
</script>
<template>
  <RouterLinkById :id="id" route="objects"><slot /></RouterLinkById>
</template>
