<script setup>
import ModelCard from '../components/ModelCard.vue';
import ObjectLink from '../components/ObjectLink.vue';
import ObjectMapLink from '../components/ObjectMapLink.vue';
import SMApi from '../services/smapi.js';
import { watch, toValue, ref, watchEffect } from 'vue';

const props = defineProps(["id"]);

const id = ref(props.id)
const modelResponse = SMApi.getModelById( id );
const model = modelResponse.data;
const modelError = modelResponse.error;

let positions = ref([]);

const modelPositions = SMApi.getModelPositionsById( id ).data;
watch(modelPositions, () => {
  const p = toValue(modelPositions);
  if( p ) {
    const features = p.features || [];
    features.forEach( f => {
      f.longitude = f.geometry.coordinates[0];
      f.latitude = f.geometry.coordinates[1];
      for( var p in f.properties ) {
        f[p] = f.properties[p];
      }
    });
    positions.value = features;
  } else {
    positions.value = [];
    }
});

const headers =  [
  { text: "ID", value: "id", sortable: true },
  { text: "Country", value: "properties.country", sortable: true },
  { text: "Longitude", value: "longitude", sortable: true },
  { text: "Latitude", value: "latitude", sortable: true },
  { text: "Elevation", value: "properties.gndelev", sortable: true },
];

</script>

<template>
  <main>
    <div class="container">
      <p>
          <ModelCard v-if="model"
            :id="id" 
            :title="model.name" 
            :description="model.notes"
            :authorId="model.authorId"
            :authorName="model.author"
            :modelGroupId="model.shared"
            :modelGroupName="model.groupName"
            :filename="model.filename"
            :files="model.content"
          />
          <div v-else>
            <strong>Error loading model: {{ modelError }}</strong>
          </div>
      </p>
      <p v-if="positions && positions.length">
          <h5>It exists at the following location(s)</h5>
          <EasyDataTable
                 :headers="headers"
                 :items="positions"
                 buttons-pagination
                 alternating
          >
            <template #item-id="{ id }">
              <ObjectLink route="Objects" :id="id">{{ id }}</ObjectLink>
            </template>
            <template #item-longitude="{ longitude, latitude, id }">
              <ObjectMapLink :id="id" :longitude="longitude" :latitude="latitude">{{ longitude }}</ObjectMapLink>
            </template>
            <template #item-latitude="{ longitude, latitude, id }">
              <ObjectMapLink :id="id" :longitude="longitude" :latitude="latitude">{{ latitude }}</ObjectMapLink>
            </template>
          </EasyDataTable>
      </p>
      <p v-else>
          <h5>It is currently unused, no objects refer to this model.</h5>
      </p>
    </div>
  </main>
</template>
