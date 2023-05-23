<script setup>
import SMApi from '../services/smapi.js';
import ObjectsAddComponent from '../components/ObjectsAddComponent.vue';
import ObjectsUpdateComponent from '../components/ObjectsUpdateComponent.vue';
import ObjectsDeleteComponent from '../components/ObjectsDeleteComponent.vue';
import ModelAddComponent from '../components/ModelAddComponent.vue';
import ModelUpdateComponent from '../components/ModelUpdateComponent.vue';
</script>

<template>
  <main class="container-fluid">
    <h1>Contribution Request #{{ this.id }}</h1>
    <strong>{{ this.request.type}}</strong>
    <ObjectsAddComponent v-if="this.request.type == 'OBJECTS_ADD'" :content="request.content" />
    <ObjectsUpdateComponent v-else-if="this.request.type == 'OBJECT_UPDATE'" :content="request.content"/>
    <ObjectsDeleteComponent v-else-if="this.request.type == 'OBJECT_DELETE'" :content="request.content" />
    <ModelAddComponent v-else-if="this.request.type == 'MODEL_ADD'" :content="request.content" />
    <ModelUpdateComponent v-else-if="this.request.type == 'MODEL_UPDATE'" :content="request.content" />
    <div v-else>
      <b>This is an unknown request type</b>
    </div>
  </main>
</template>

<script>

export default {
  props: [ "id" ],

  methods: {
    loadData() {
        let request;
        SMApi.getContribById(this.id)
        .then( response => {
          request = response && response.request;
        })
        .catch( err => {
          console.error(err);
        })
        .finally( () => {
          this.request = request;
        });
    },
  },

  data() {
    return {
      request: {},
    }
  },
  created() {
    this.loadData();
  },
}
</script>

