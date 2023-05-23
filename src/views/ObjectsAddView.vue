<script setup>
</script>

<template>
  <main class="container-fluid">
    <h1>Contributions awaiting review</h1>
    <EasyDataTable
        :headers="headers"
        :items="items"
        alternating
    >
    </EasyDataTable>

  </main>
</template>

<script>
   const headers =  [
      { text: "Description", value: "description", sortable: true },
      { text: "Longitude", value: "longitude", sortable: true },
      { text: "Latitude", value: "latitude", sortable: true },
      { text: "Offset", value: "offset", sortable: true },
      { text: "Orientation", value: "orientation", sortable: true },
      { text: "Country", value: "country", sortable: true },
      { text: "Model-ID", value: "modelId", sortable: true },
    ];

export default {
  props: {
    items,
  },

  data() {
    return {
      headers,
    }
  },
  created() {
  },
}
</script>
