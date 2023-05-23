<script setup>
import ModelImage from './ModelImage.vue'
</script>

<template>

  <div class="card" style="width: 18rem;">
    <div class="card-header">
      {{ title }} <span v-if="author">({{ author }})</span>
    </div>
    <div class="card-body">
      <ModelImage :id="id" :title="title" class="card-img-top"></ModelImage>
      <p class="card-text">{{ description}}</p>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    title: String,
    author: String,
    filename: String,
    description: String,
    id: Number
  },
  created() {
    console.log(this.author);
  }
}
</script>
