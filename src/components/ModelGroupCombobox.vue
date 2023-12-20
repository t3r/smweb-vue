<script setup>

defineProps(['modelValue'])
defineEmits(['update:modelValue'])

import SMApi from '../services/smapi.js';

const modelGroups = SMApi._getModelGroups();

</script>

<template>
  <select :value="modelValue" @input="$emit('update:modelValue', $event.target.value)">
    <option value="0">Static</option>
    <option v-for="mg in modelGroups" :value="mg.id">{{ mg.name }}</option>
  </select>
</template>
