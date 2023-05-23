<script setup>
import SMApi from '../services/smapi.js';
import ContribLink from '../components/ContribLink.vue';
</script>

<template>
  <main class="container-fluid">
    <h1>Contributions awaiting review</h1>
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
        <ContribLink :id="id">{{ id }}</ContribLink>
      </template>
    </EasyDataTable>

  </main>
</template>

<script>
   const headers =  [
      { text: "ID", value: "id", sortable: true },
      { text: "Type", value: "request.type", sortable: true },
      { text: "Author", value: "request.email", sortable: true },
      { text: "Comment", value: "request.comment", sortable: true },
    ];

export default {
  watch: {
    serverOptions: {
      handler(newValue,oldValue) {
        const limit = newValue.rowsPerPage;
        const offset = (newValue.page-1) * limit;

        let items = [];
        this.loading = true;
        SMApi.getContribs({limit,offset})
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
          this.serverItemsLength = items.length;
        });
      },
      deep: true,
    },
  },

  data() {
    return {
      headers,
      items: [],
      serverItemsLength: 0,
      serverOptions: {},
      loading: false,
    }
  },
  created() {
    this.serverOptions = {
      page: 1,
      rowsPerPage: 25,
    };
  },
}
</script>

