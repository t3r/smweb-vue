<script setup>
import { toValue, watchEffect, watch, ref, computed } from 'vue';

const props = defineProps(['obj',
  'title',
  'description',
  'longitude',
  'latitude',
  'elevation',
  'offset',
  'orientation',
  'modelId',
  'readonly',
]);

const emit = defineEmits([
  'update:description',
  'update:longitude',
  'update:latitude',
  'update:elevation',
  'update:offset',
  'update:orientation',
  'update:modelId',
]);

</script>

<template>
<div class="card">
  <div class="card-header">{{ title }}</div>
  <div class="card-body">
    <table v-if="obj" class="table-sm">
      <tr>
        <th>Description</th>
        <td>{{ obj.description }}</td>
      </tr>
      <tr>
        <th>Longitude</th>
        <td>{{ obj.longitude }}</td>
      </tr>
      <tr>
        <th>Latitude</th>
        <td>{{ obj.latitude }}</td>
      </tr>
      <tr>
        <th>Offset</th>
        <td>{{ obj.offset||0 }}m</td>
      </tr>
      <tr>
        <th>Orientation</th>
        <td>{{ obj.orientation||0 }}&deg;</td>
      </tr>
      <tr>
        <th>Model</th>
        <td>{{ obj.modelId }}</td>
      </tr>
    </table>
    <table v-else class="table-sm">
      <tr>
        <th>Description</th>
        <td><div class="input-group">
          <input type="text" class="form-control" aria-label="Description" placeholder="Description" :value="description" @input="$emit('update:description', $event.target.value)" :readonly="readonly">
        </div></td>
      </tr>
      <tr>
        <th>Longitude</th>
        <td><div class="input-group">
          <input type="text" class="form-control" aria-label="Longitude" placeholder="Longitude" :value="longitude" @input="$emit('update:longitude', $event.target.value)" :readonly="readonly">
          <span class="input-group-text">&deg;</span>
        </div></td>
      </tr>
      <tr>
        <th>Latitude</th>
        <td><div class="input-group">
          <input type="text" class="form-control" aria-label="Latitude" placeholder="Latitude" :value="latitude" @input="$emit('update:latitude', $event.target.value)" :readonly="readonly">
          <span class="input-group-text">&deg;</span>
        </div></td>
      </tr>
      <tr>
        <th>Elevation</th>
        <td><div class="input-group">
            <input type="text" class="form-control" aria-label="Elevation" placeholder="Elevation" :value="elevation" @input="$emit('update:elevation', $event.target.value)" readonly>
          <span class="input-group-text">m</span>
        </div></td>
      </tr>
      <tr>
        <th>Offset</th>
        <td><div class="input-group">
          <input type="text" class="form-control" aria-label="Elevation-Offset" placeholder="Elevation-Offset" :value="offset" @input="$emit('update:offset', $event.target.value)" :readonly="readonly">
          <span class="input-group-text">m</span>
        </div></td>
      </tr>
      <tr>
        <th>Orientation</th>
        <td><div class="input-group">
          <input type="text" class="form-control" aria-label="Orientation/Heading" placeholder="Orientation/Heading" :value="orientation" @input="$emit('update:orientation', $event.target.value)" :readonly="readonly">
          <span class="input-group-text">&deg;</span>
        </div></td>
      </tr>
      <tr>
        <th>Model</th>
        <td><div class="input-group">
          <input type="text" class="form-control" aria-label="Model-ID" placeholder="Model-ID" :value="modelId" @input="$emit('update:modelId', $event.target.value)" :readonly="readonly">
        </div></td>
      </tr>
    </table>
  </div>
</div>
</template>
