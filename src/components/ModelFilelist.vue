<script setup>
</script>

<template>
  <h5>The model is made of these file(s)</h5>
  <table class="table">
    <thead>
      <tr>
        <th scope="col">Filename</th>
        <th scope="col">Size</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="file in files">
        <td>{{ file.filename }}</td>
        <td>{{ file.filesize }}</td>
      </tr>
    </tbody>
  </table>
</template>

<script>
export default {
  props: {
    files: Array
  },
}
</script>
