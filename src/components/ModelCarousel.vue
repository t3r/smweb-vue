<script setup>
import ModelImage from './ModelImage.vue'
</script>

<template>
<div :id="carouselId" class="carousel slide carousel-fade" data-bs-ride="carousel" data-bs-interval="2000">
  <div class="carousel-indicators">
    <button v-for="(m,index) in models" type="button" :data-bs-target="carouselIdLink" :data-bs-slide-to="index" :class="{active: index == 0}" aria-current="true" :aria-label="m.title"></button>
  </div>
  <div class="carousel-inner">
    <div v-for="(m,index) in models" class="carousel-item" :class="{active: index == 0}">
      <ModelImage class="d-block w-100" :id="m.id" :title="m.title"></ModelImage>
      <div class="carousel-caption d-none d-md-block">
        <h5>{{ m.title }}</h5>
        <p>{{ m.description }}</p>
      </div>
    </div>
  </div>
  <button class="carousel-control-prev" type="button" :data-bs-target="carouselIdLink" data-bs-slide="prev">
    <span class="carousel-control-prev-icon" aria-hidden="true"></span>
    <span class="visually-hidden">Previous</span>
  </button>
  <button class="carousel-control-next" type="button" :data-bs-target="carouselIdLink" data-bs-slide="next">
    <span class="carousel-control-next-icon" aria-hidden="true"></span>
    <span class="visually-hidden">Next</span>
  </button>
</div>
</template>

<script>
export default {
  props: {
    models: Array
  },
  data() {
    return {
      carouselId: 'carousel-' + crypto. randomUUID(),
    }
  },
  computed: {
    carouselIdLink() { return '#' + this.carouselId; }
  },
  created() {
  }
}
</script>
