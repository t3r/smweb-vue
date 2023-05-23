<script setup>
import { ref, watchEffect, toValue } from 'vue';
import SMApi from '../services/smapi.js';
import ModelThumb from '../components/ModelThumb.vue'
import ModelCarousel from '../components/ModelCarousel.vue'

const objects = ref(0);
const models = ref(0);
const authors = ref(0);
const pending = ref(0);
const accepted = ref(0);

const { data, error } = SMApi.getStats();
watchEffect(() => {
  const stats = (toValue(data) ?? {}).stats;
  if( stats ) {
    objects.value = stats.objects;
    models.value = stats.models;
    authors.value = stats.authors;
    pending.value = stats.pending;
    accepted.value = stats.elev;
  }
});

</script>

<template>
  <main>
    <h1>Moin! <sup><small><small><a href="https://en.wikipedia.org/wiki/Moin">?</a></small></small></sup></h1>
    <p>You found the place where some <router-link class="link" to="/authors">{{ authors }} nice people</router-link> from around the world maintain and contribute to the database of scenery objects and models for the fantastic, free and open <a href="https://flightgear.org/">FlightGear</a> flight simulator. What you find here is stored in a database. Every day, this data gets exported to a file and directory structure suitable for FlightGear and eventually mirrored across our <a href="https://wiki.flightgear.org/TerraSync">TerraSync</a> servers.</p>
  <p v-if="error">
    Ops - i there seems to be an issue with the database. It says: {{ error }}
  </p>
  <p v-else>Up to now, we have
     <router-link class="link" to="/models">{{ models }} Models</router-link> 
     at <router-link class="link" to="/objects">{{ objects }} positions</router-link> in our database. 
     There are <router-link class="link" to="/contribs">{{ pending }} pending contributions </router-link>waiting for review and {{ accepted }} item(s) will be updated during the next export.
  </p>
  </main>
</template>
