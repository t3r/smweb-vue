<script setup>

import { ref, onMounted } from 'vue'
import { Map } from "./map/index.js";

const props = defineProps(["lat","lon","z"]);
onMounted(() => {
  const map = Map("map", props);
})

</script>

<template>
  <main>
    <div id="map">The map should be here.</div>
  </main>
</template>
<style scoped>
#map{
 width: 100%;
 height: 500px;
}
</style>
