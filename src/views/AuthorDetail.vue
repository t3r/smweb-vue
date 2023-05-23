<script setup>
import { toValue, watchEffect } from 'vue';
import SMApi from '../services/smapi.js';
import ModelGroupName from '../components/ModelGroupName.vue';
import ModelLink from '../components/ModelLink.vue';
import ModelImage from '../components/ModelImage.vue';

const { data,error } = SMApi.getMe();
watchEffect(() => {
  console.log(toValue(data));
});
</script>

<template>
  <main>
    <h1>Author #{{ author.id }}: {{ author.name }}</h1>
    <p>{{ author.notes }}</p>
    <p>{{ data }} - {{ error }} </p>
    This person generously created and donated these models for our database:
    <EasyDataTable
        :headers="headers"
        :items="models"
        :server-items-length="serverItemsLength"
        :loading="loading"
        v-model:server-options="serverOptions"
        buttons-pagination
        alternating
    >
      <template #item-id="{ name, id }">
        <ModelLink :id="id">{{id}}</ModelLink>
      </template>
      <template #item-name="{ name, id }">
        <ModelLink :id="id">{{name}}</ModelLink>
      </template>
      <template #item-filename="{ id, name }">
        <ModelLink :id="id">
          <ModelImage :id="id" class="fg-modelthumbsmall"/>
        </ModelLink>
      </template>
      <template #item-shared="{ shared }">
        <ModelGroupName :id="shared"></ModelGroupName>
      </template>
    </EasyDataTable>
  </main>
</template>
<style scoped>
.fg-modelthumbsmall {
  width: 80px;
  height: 60px;
}
</style>

<script>
   const headers =  [
      { text: "ID", value: "id" },
      { text: "Thumb", value: "filename" },
      { text: "Name", value: "name", sortable: true },
      { text: "Model Group", value: "shared", sortable: true },
      { text: "modified", value: "modified", sortable: true },
    ];

export default {
  props: ["id"],
  data() {
    return {
      headers,
      author: {},
      models: [],
      serverItemsLength: 100,
      serverOptions: {},
      loading: false,
    }
  },
  created() {
    this.serverOptions = {
      page: 1,
      rowsPerPage: 25,
    };
    this.loading = true;

    SMApi.getAuthorById( this.id )
    .then( data => {
      this.author = data ? data : {};
      return SMApi.getModels({ author: this.author.id, limit: 100, offset: 0 });
    })
    .then( data => {
      this.models = data;
    })
    .catch( err => {
      console.error(err);
    })
    .finally( () => {
      this.loading = false;
    });
  },
} 
</script>
