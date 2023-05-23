<script setup>
import ModelLink from './ModelLink.vue';
import ModelImage from './ModelImage.vue';
</script>

<template>
  <div>add request</div>
  <EasyDataTable
        :headers="headers"
        :items="content"
        buttons-pagination
        alternating
    >
      <template #item-modelId="{ modelId, name, description }">
        <ModelLink :id="modelId">
          <ModelImage :id="modelId" :title="description" imageClass="fg-modelthumbsmall"/>
        </ModelLink>
      </template>
      <template #item-description="{ modelId, description }">
        <ModelLink :id="modelId" :name="description" />
      </template>
    </EasyDataTable>
</template>
<style scoped>
.fg-modelthumbsmall {
  width: 80px;
  height: 60px;
}
</style>

<script>
const headers = [
  { text: "Model", value: "modelId" },
  { text: "Descriptions", value: "description" },
  { text: "Longitude", value: "longitude" },
  { text: "Latitude", value: "latitude" },
  { text: "Country", value: "country" },
  { text: "Offset", value: "offset" },
  { text: "Orientation", value: "orientation" },
];
export default {
  props: {
    content: Array,
  },

  data() {
    return {
      headers,
    }
  },
  created() {
  },
}
</script>

