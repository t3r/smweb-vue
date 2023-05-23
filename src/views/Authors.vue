<script setup>
import SMApi from '../services/smapi.js';
import AuthorLink from '../components/AuthorLink.vue'
</script>

<template>
  <main class="container-fluid">
    <h1>Authors</h1>
    <EasyDataTable
        :headers="headers"
        :items="items"
        :server-items-length="serverItemsLength"
        :loading="loading"
        v-model:server-options="serverOptions"
        buttons-pagination
        alternating
    >
      <template #item-id="{ id }">
        <AuthorLink :id="id">{{ id }}</AuthorLink>
      </template>
      <template #item-name="{ id, name }">
        <AuthorLink :id="id">{{ name }}</AuthorLink>
      </template>
    </EasyDataTable>

  </main>
</template>

<script>
   const headers =  [
      { text: "ID", value: "id", sortable: true },
      { text: "Name", value: "name", sortable: true },
      { text: "Notes", value: "notes", sortable: false },
      { text: "Models", value: "models", sortable: true },
    ];

export default {
  watch: {
    serverOptions: {
      handler(newValue,oldValue) {
        const limit = newValue.rowsPerPage;
        const offset = (newValue.page-1) * limit;

        let items = [];
        this.loading = true;
        SMApi.getAuthors({limit,offset})
        .then( response => {
          if( response )
            items = response;
        })
        .catch( err => {
          console.error(err);
        })
        .finally( () => {
          this.loading = false;
          this.items = items;
        });
      },
      deep: true,
    },
  },

  data() {
    return {
      carouselId: 'carousel-' + crypto. randomUUID(),
      headers,
      items: [],
      serverItemsLength: 100,
      serverOptions: {},
      loading: false,
    }
  },
  computed: {
    carouselIdLink() { return '#' + this.carouselId; }
  },
  created() {
    this.serverOptions = {
      page: 1,
      rowsPerPage: 25,
    };
  },
}
</script>
