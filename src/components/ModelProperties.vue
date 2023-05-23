<script setup>
</script>

<template>
<div class="container">
  <div class="row">
    <div class="col">Name</div>
    <div class="col">{{ name }}</div>
  </div>
  <div class="row">
    <div class="col">Description</div>
    <div class="col">{{ description }}</div>
  </div>
  <div class="row">
    <div class="col">Type</div>
    <div class="col">{{ type }}</div>
  </div>
  <div class="row">
    <div class="col">Author</div>
    <div class="col">{{ author }}</div>
  </div>
</div>
</template>

<script>
export default {
  props: {
    name: String,
    title: String,
    author: String,
    type: String,
    description: String,
    id: Number
  },
  created() {
  }
}
</script>
