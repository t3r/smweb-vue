<script setup>
import SMApi from '../services/smapi.js'
import { toValue, watchEffect, watch, ref, onMounted } from 'vue';
import { Map } from "./map/index.js";

const props = defineProps(["id"]);
const id = ref(props.id);
const email = ref("");
const isInvalidForm = ref(true);

let map = null;
onMounted(() => {
  map = Map("map", { z: 15, lat: 0, lon: 0 });
})

const newObject = ref({});

const objectData = SMApi._getObjectById( id );

const obj = ref(null);
watch( objectData.data, (d) => {
  if( d && d.properties && d.geometry ) {
    newObject.value = structuredClone(obj.value = {
      description: d.properties.title,
      offset: d.properties.elevoffset,
      orientation: d.properties.heading,
      modelId: d.properties.model_id,
      longitude: d.geometry.coordinates[0],
      latitude: d.geometry.coordinates[1],
    });
    map.setView( [ d.geometry.coordinates[1], d.geometry.coordinates[0] ], 17 );
  } else {
    map.setView( [ 53.5, 10], 10 );
  }
});


</script>
<template>
<main>
<h1>Update a single Object</h1>
<p>Request a update of a model's position (which is what we call "Object"). Enter the Object-ID oder pick the Object on the map below.</p>
<div class="row">
  <div class="col">
    <div class="mb-3">
      <label for="updateObjectId" class="form-label">Numeric Object-ID</label>
      <input v-model="id" type="number" class="form-control" id="updateObjectId" aria-describedby="updateObjectIdHelp">
      <div id="updateObjectIdHelp" class="form-text">Enter the Object's ID to be removed from the database.</div>
    </div>
    <div class="mb-3">
      <ObjectDetailsCard title="Database Version" :obj="obj" />
    </div>
    <div class="mb-3">
      <ObjectDetailsCard title="Your Updates" 
        v-model:description="newObject.description" 
        v-model:longitude="newObject.longitude" 
        v-model:latitude="newObject.latitude" 
        v-model:offset="newObject.offset" 
        v-model:orientation="newObject.orientation" 
        v-model:modelId="newObject.modelId" 
        :readonly="false"
      />
    </div>
    <form>
      <div class="mb-3">
        <label for="updateObjectEmailId" class="form-label">Email address</label>
        <input type="email" class="form-control" id="updateObjectEmailId" aria-describedby="updateObjectEmailHelp" v-model="email">
        <div id="updateObjectEmailHelp" class="form-text">Please provide a valid email address to sign you request.</div>
      </div>
      <div class="mb-3">
        <button class="btn btn-primary" @click="onSubmit" :disabled="isInvalidForm">Submit Update Request</button>
      </div>
    </form>
  </div>
  <div class="col">
    <div id="map">The map should be here.</div>
  </div>
</div>
</main>
</template>
<style scoped>
#map{     
 width: 100%; 
 height: 100%;
}   
</style>
