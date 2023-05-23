<script setup>
import SMApi from '../services/smapi.js';
</script>

<template>
<div class="container">
  <div class="row">
    <div class="col">
      <ObjectDetailsCard v-if="oldContent" title="Database Version" :obj="oldContent" />
      <b v-else>The Object to be deleted does not seem to exist in the database anymore. This is awkward. This request should be deleted.</b>
    </div>
  </div>
</div>
</template>
<style scoped>
.fg-modelthumbsmall {
  width: 80px;
  height: 60px;
}
</style>

<script>
export default {
  props: {
    content: Object,
  },

  methods: {
  },

  data() {
    return {
      oldContent: {}
    }
  },
  async created() {
    this.oldContent  = await SMApi.getObjectByIdAsUpdateRequestContent( this.content.objId );
  },
}
</script>

