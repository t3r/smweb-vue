<template>
  <RouterLink :to="{
    name: 'Map',
    query: { 
       z: zoom, 
     obj: id,
     lat: latitude,
     lon: longitude,
    }
  }">
    <slot />
  </RouterLink>
</template>
<script>
import { RouterLink } from 'vue-router'

export default {
  name: 'ObjectMapLink',
  props: {
    id: {
      default: 0,
    },
    longitude: {
      default: 0,
    },
    latitude: {
      default: 0,
    },
    zoom: {
      default: 15,
    },
  }
}
</script>
