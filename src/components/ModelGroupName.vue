<script setup>
import SMApi from '../services/smapi.js'
</script>

<template>
  <span>{{ name }}</span>
</template>

<style scoped>
</style>

<script>
export default {
  props: {
    id: Number,
  },
  data() {
    return {
      name: "bar",
    }
  },
  watch: {
    id( newValue ) {
      this.updateName( newValue );  
    },
  },
  created() {
    this.updateName( this.id );  
  },
  methods: {
    updateName() {
      SMApi.getModelGroup( this.id )
      .then( data => {
        this.name = data.name;
      })
      .catch( err => {
        console.error(err);
        this.name = "unknown";
      });
    }
  },
}
</script>
