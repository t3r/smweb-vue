<script setup>
import SMApi from '../services/smapi.js'
import { toValue, watchEffect, watch, ref, onMounted } from 'vue';
import { Map } from "./map/index.js";
import { profile } from '../profile.js';

const props = defineProps(["id"]);
const id = ref(props.id);
const email = ref("");
const isInvalidForm = ref(true);

let map = null;
onMounted(() => {
  map = Map("map", { z: 15, lat: 0, lon: 0 });
})

const objectData = SMApi._getObjectById( id );

const obj = ref(null);
watch( objectData.data, (d) => {
  if( d && d.properties && d.geometry ) {
    obj.value = {
      description: d.properties.title,
      offset: d.properties.elevoffset,
      orientation: d.properties.heading,
      modelId: d.properties.model_id,
      longitude: d.geometry.coordinates[0],
      latitude: d.geometry.coordinates[1],
    }
    map.setView( [ d.geometry.coordinates[1], d.geometry.coordinates[0] ], 17 );
  } else {
    map.setView( [ 53.5, 10], 10 );
  }
});

watchEffect( () => {
console.log("we", profile.isAuthenticated() );
  email.value = profile.isAuthenticated() ? profile.user.email : '';
});

const validEmail = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

watchEffect(() => {
  const _email = toValue( email );  
  if( !validEmail.test( _email ) ) {
    isInvalidForm.value = true;
    return;
  }

  const _d = toValue( objectData.data );
  if( !(_d && _d.properties && _d.geometry) ) {
    console.log("invalid object: ", _d );
    isInvalidForm.value = true;
    return;
  }

  isInvalidForm.value = false;
});

function onSubmit() {
  console.log("submitted");
  SMApi.deleteObjectById( toValue(id), { authorEmail: toValue(email).toString().trim() } )
  .then( res => {
console.log(res);
  })
  .catch( err => {
console.error(err);
  });
}


</script>
<template>
<main>
<h1>Delete a single Object</h1>
<p>Request a deletition of a Model's position (which is what we call "Object"). Enter the Object-ID oder pick the Object on the map below.</p>
<div class="row">
  <div class="col">
    <div class="mb-3">
      <label for="deleteObjectId" class="form-label">Numeric Object-ID</label>
      <input v-model="id" type="number" class="form-control" id="deleteObjectId" aria-describedby="deleteObjectIdHelp">
      <div id="deleteObjectIdHelp" class="form-text">Enter the Object's ID to be removed from the database.</div>
    </div>
    <div class="mb-3">
      <ObjectDetailsCard v-if="obj" title="Database Version" :obj="obj" />
    </div>
    <form>
      <div class="mb-3">
        <label for="deleteObjectEmailId" class="form-label">Email address</label>
        <input type="email" class="form-control" id="deleteObjectEmailId" aria-describedby="deleteObjectEmailHelp" v-model="email">
        <div id="deleteObjectEmailHelp" class="form-text">Please provide a valid email address to sign your request.</div>
      </div>
      <div class="mb-3">
        <button class="btn btn-primary" @click="onSubmit" :disabled="isInvalidForm">Submit Delete Request</button>
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
