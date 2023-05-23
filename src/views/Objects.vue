<script setup>
import SMApi from '../services/smapi.js';
import ModelLink from '../components/ModelLink.vue';
import ObjectMapLink from '../components/ObjectMapLink.vue';
import { watch, toValue, ref } from 'vue';

const headers =  [
  { text: "ID", value: "id" },
  { text: "Description", value: "title", sortable: true },
  { text: "Model", value: "model_name", sortable: true },
  { text: "Country", value: "country", sortable: true },
  { text: "Longitude", value: "longitude", sortable: true },
  { text: "Latitude", value: "latitude", sortable: true },
  { text: "Elevation", value: "gndelev", sortable: true },
  { text: "Offset", value: "elevoffset", sortable: true },
  { text: "Heading", value: "heading", sortable: true },
  { text: "Action", value: "edit" },
];
const items = ref([]);
const serverItemsLength = ref(0);
const loading = ref(false);
const serverOptions = ref(null);

const objectsResponse = SMApi.getObjects( serverOptions, loading );
const objectsData = objectsResponse.data;
const objectsError = objectsResponse.error;

watch( objectsData, () => {
  const obj = toValue( objectsData );
  if( obj ) {
    serverItemsLength.value = Number(obj.properties.totalRows);
    const i = [];
    if( obj.features ) {
      obj.features.forEach( f => {
        f.properties.latitude = f.geometry.coordinates[1];
        f.properties.longitude = f.geometry.coordinates[0];
        f.properties.edit = f.properties.id; // dummy column for edit links
        i.push( f.properties );
      });
    }
    items.value = i;

  } else {
    serverItemsLength.value = 0;
    items.value = [];
  }
});

serverOptions.value = {
      page: 1,
      rowsPerPage: 100,
};


</script>

<template>
  <main class="container-fluid">
    <h1>Objects</h1>
    <EasyDataTable
        :headers="headers"
        :items="items"
        :server-items-length="serverItemsLength"
        :loading="loading"
        v-model:server-options="serverOptions"
        buttons-pagination
        alternating
    >
      <template #item-edit="{ id }">
        <div class="btn-group" role="group" aria-label="Edit Options">
          <RouterLinkById class="btn btn-link" route="UpdateObject" :id="id"><i class="bi bi-pencil"></i></RouterLinkById>
          <RouterLinkById class="btn btn-link" route="DeleteObject" :id="id"><i class="bi bi-trash"></i></RouterLinkById>
        </div>
      </template>
      <template #item-model_name="{ model_name, model_id }">
        <ModelLink :id="model_id">{{ model_name }}</ModelLink>
      </template>
      <template #item-longitude="{ longitude, latitude, model_id }">
        <ObjectMapLink :id="model_id" :longitude="longitude" :latitude="latitude">{{ longitude }}</ObjectMapLink>
      </template>
      <template #item-latitude="{ longitude, latitude, model_id }">
        <ObjectMapLink :id="model_id" :longitude="longitude" :latitude="latitude">{{ latitude }}</ObjectMapLink>
      </template>
    </EasyDataTable>

  </main>
</template>
