<script setup>
import SMApi from '../services/smapi.js';
import { computed } from 'vue'
const props = defineProps({
    title: String,
    description: String,
    id: {},
    imageData: String,
    imageClass: {
      type: String,
      default(rawProps) { return  'fg-modelthumb'; },
    },
});

const imageAlt = computed(() => {
  return `Thumbnail image of ${props.title}, ${props.description ? props.description : ""}`
});

const imageUrl = computed(() => {
  if( props.id ) return SMApi.getModelThumbUrl( props.id );
  if( props.imageData ) return `data:image/jpeg;base64,${props.imageData}`;
  return '#';
});

</script>

<template>
  <img :src="imageUrl" :alt="imageAlt" :title="title" :class="imageClass">
</template>

<style scoped>
.fg-modelthumb {
  width: 320px;
  height: 240px;
}
</style>
