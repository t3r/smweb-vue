<script setup>
import { toValue, watchEffect } from 'vue';
import SMApi from '../services/smapi.js';

const { data,error } = SMApi.getMe();
watchEffect(() => {
  console.log(toValue(data));
});
</script>
<template>
  <main>
    <h1>Your Profile</h1>
    Data: {{ data }}<br />Error: {{ error }}
  </main>
</template>
