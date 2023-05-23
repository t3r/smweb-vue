<script setup>
const props = defineProps(["id"]);
</script>
<template>
  <RouterLinkById route="Contribution" :id="id"><slot /></RouterLinkById>
</template>
