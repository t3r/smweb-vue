<script setup>
import { watch, watchEffect, toValue, ref } from 'vue';
import SMApi from '../services/smapi.js';
import ModelGroupName from '../components/ModelGroupName.vue';
import ModelImage from '../components/ModelImage.vue';
import ModelLink from '../components/ModelLink.vue';
import AuthorLink from '../components/AuthorLink.vue';

const props = defineProps(["shared","author"]);

const headers =  [
  { text: "ID", value: "id" },
  { text: "Thumb", value: "filename" },
  { text: "Name", value: "name", sortable: true },
  { text: "Author", value: "author", sortable: true },
  { text: "Model Group", value: "shared", sortable: true },
  { text: "modified", value: "modified", sortable: true },
];

const loading = ref( false );
const selectedModelGroup = ref(props.shared || "");
const selectedAuthor = ref(props.author || "");

const showSharedFilter = ref(false);
const showAuthorFilter = ref(false);

const items = ref([]);
const serverItemsLength = ref(0);
const serverOptions = ref({
  page: 1,
  rowsPerPage: 25,
});

watchEffect(() => {
  const mg = toValue(selectedModelGroup);
  const author = toValue(selectedAuthor);
  const opts = toValue(serverOptions);

  const limit = opts.rowsPerPage;
  const offset = (opts.page-1) * limit;
  loading.value = true;

  const options = {limit,offset};

  if( mg != "" ) options.shared = mg;

  if( author != "" ) options.author = author;

  let data = [];
  SMApi.getModels(options)
  .then( response => {
    data = response;
  })
  .catch( err => {
    console.error(err);
  })
  .finally( () => {
    loading.value = false;
    items.value = data;;
  });
});


const authors = SMApi._getAuthors({ page: 1, rowsPerPage: 10000}).data;
const modelGroups = SMApi._getModelGroups();

</script>

<template>
  <main class="container-fluid">
    <h1>Models</h1>
    <p>These are all the models we have. You can <router-link class="link" to="/contrib/model/add">add a new Model here</router-link>.</p>
    <EasyDataTable
        :headers="headers"
        :items="items"
        :server-items-length="serverItemsLength"
        :loading="loading"
        v-model:server-options="serverOptions"
        buttons-pagination
        alternating
    >
      <template #header-shared="header">
        <div class="row">
          <div class="col-md-auto">
            <i class="bi bi-funnel filter-icon" @click.stop="showSharedFilter=!showSharedFilter"></i>
          </div>
          <div class="col" v-if="!showSharedFilter">{{ header.text }}</div>
          <div class="col" v-if="showSharedFilter">
            <select class="form-select form-select-sm" v-model="selectedModelGroup" name="shared">
              <option value="">All</option>
              <option v-for="mg in modelGroups" :value="mg.id">{{ mg.name }}</option>
            </select>
          </div>
        </div>
      </template>

      <template #header-author="header">
        <div class="row">
          <div class="col-md-auto">
            <i class="bi bi-funnel filter-icon" @click.stop="showAuthorFilter=!showAuthorFilter"></i>
          </div>
          <div class="col" v-if="!showAuthorFilter">{{ header.text }}</div>
          <div class="col" v-if="showAuthorFilter">
            <select class="form-select form-select-sm" v-model="selectedAuthor" name="shared">
              <option value="">All</option>
              <option v-for="au in authors" :value="au.id">{{ au.name }}</option>
            </select>
          </div>
        </div>
      </template>

      <template #item-id="{ name, id }">
        <ModelLink :id="id">{{ id }}</ModelLink>
      </template>
      <template #item-name="{ name, id }">
        <ModelLink :id="id">{{ name }}</ModelLink>
      </template>
      <template #item-author="{ author, authorId }">
        <AuthorLink :id="authorId">{{ author }}</AuthorLink>
      </template>
      <template #item-filename="{ id, name, notes }">
        <ModelLink :id="id">
          <ModelImage :title="name" :description="notes" :id="id" imageClass="fg-modelthumbsmall"/>
        </ModelLink>
      </template>
      <template #item-shared="{ shared }">
        <ModelGroupName :id="shared"></ModelGroupName>
      </template>
    </EasyDataTable>
  </main>
</template>
<style scoped>
.fg-modelthumbsmall {
  width: 80px;
  height: 60px;
}
</style>

<!--script>
   const headers =  [
      { text: "ID", value: "id" },
      { text: "Thumb", value: "filename" },
      { text: "Name", value: "name", sortable: true },
      { text: "Author", value: "author", sortable: true },
      { text: "Model Group", value: "shared", sortable: true },
      { text: "modified", value: "modified", sortable: true },
    ];

export default {
  props: {
    shared: Number,
    author: Number,
  },

  methods: {
    loadModels() {
      const limit = this.serverOptions.rowsPerPage;
      const offset = (this.serverOptions.page-1) * limit;
      let items = [];
      this.loading = true;
      const options = {limit,offset};
      if( this.selectedModelGroup != "" )
        options.shared = this.selectedModelGroup;
      if( this.selectedAuthor != "" )
        options.author = this.selectedAuthor;
      SMApi.getModels(options)
      .then( response => {
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
    buildQuery() {
      const query = {}
      if( this.selectedModelGroup != "" )
        query.shared = this.selectedModelGroup;
      if( this.selectedAuthor != "" )
        query.author = this.selectedAuthor;
      return query;
    },
  },

  watch: {
    selectedModelGroup() {
      this.$router.replace({ name: "Models", query: this.buildQuery() })
      this.loadModels();
    },
    selectedAuthor() {
      this.$router.replace({ name: "Models", query: this.buildQuery() })
      this.loadModels();
    },
    serverOptions: {
      handler(newValue,oldValue) {
        this.loadModels();
      },
      deep: true,
    },
  },

  data() {
    return {
      loading: false,
      modelGroups: [],
      selectedModelGroup: "",
      selectedAuthor: "",
      showSharedFilter: false,
      showAuthorFilter: false,
      authors: [],

      headers,
      items: [],
      serverItemsLength: 100,
      serverOptions: {},
      loading: false,
    }
  },
  created() {
    this.selectedModelGroup = this.shared || "";
    this.selectedAuthor = this.author || "";
    this.serverOptions = {
      page: 1,
      rowsPerPage: 25,
    };

    Promise.all([
      SMApi.getModelGroups(),
      SMApi.getAuthors({limit:1000,order:"name"}),
    ])
    .then( data => {
      this.modelGroups = data[0];
      this.authors = data[1];
    })
    .catch( err => {
      console.error(err);
    })
    .finally( () => {
    });
  },
}
</script-->
