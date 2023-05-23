<script setup>
const props = defineProps(["id"]);
</script>
<template>
  <RouterLinkById route="Author" :id="id"><slot /></RouterLinkById>
</template>
