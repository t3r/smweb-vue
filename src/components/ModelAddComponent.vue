<script setup>
import SMApi from '../services/smapi.js';
import ModelCard from './ModelCard.vue';
</script>

<template>
  <ModelCard
    :title="content.model.name"
    :authorName="content.model.author"
    :authorId="content.model.author"
    :filename="content.model.filename"
    :description="content.model.description"
    :modelGroupId="content.model.modelgroup"
    :modelGroupName="content.model.modelgroup"
    :thumb="content.model.thumbnail"
    :files="content.model.modelfiles"
  />

  <div class="card float-end">
    <div class="row">
      <div class="col">Description:</div>
      <div class="col">{{ content.object.description }}</div>
    </div>
    <div class="row">
      <div class="col">Country:</div>
      <div class="col">{{ content.object.country }}</div>
    </div>
    <div class="row">
      <div class="col">Longitude:</div>
      <div class="col"><a href="#">{{ content.object.longitude }}</a></div>
    </div>
    <div class="row">
      <div class="col">Latitude:</div>
      <div class="col"><a href="#">{{ content.object.latitude }}</a></div>
    </div>
    <div class="row">
      <div class="col">Offset:</div>
      <div class="col">{{ content.object.offset }}</div>
    </div>
    <div class="row">
      <div class="col">Orientation:</div>
      <div class="col">{{ content.object.orientation }}</div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    content: Object,
  },

  data() {
    return {
      modelAuthor: "",
      modelGroupName: "",
    }
  },
  async created() {
    console.log(this.content);
    const a = await SMApi.getAuthorById( this.content.model.author );
    if( a ) this.modelAuthor = a.name;
    const mg = await SMApi.getModelGroup( this.content.model.modelgroup );
    if( mg ) this.modelGroupName = mg.name;
  },
}
</script>

