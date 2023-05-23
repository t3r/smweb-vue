<template>
  <RouterLink :to="{
    name: route,
    params: { id: id }
  }">
    <slot />
  </RouterLink>
</template>
<script>
import { RouterLink } from 'vue-router'

export default {
  name: 'RouterLinkById',
  inheritAttrs: true,
  props: {
    id: {
      default: 0,
    },
    route: {
      type: String,
      default: '/',
    },
  }
}
</script>
