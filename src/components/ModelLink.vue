<script setup>
const props = defineProps(["id"]);
</script>
<template>
  <RouterLinkById route="Model" :id="id"><slot /></RouterLinkById>
</template>
