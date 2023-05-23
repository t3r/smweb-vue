import './assets/main.css'

import { createApp } from 'vue'

import App from './App.vue'
import router from './router'

import 'bootstrap/dist/css/bootstrap.css'
import bootstrap from 'bootstrap/dist/js/bootstrap.js'
import 'bootstrap-icons/font/bootstrap-icons.min.css'

import Vue3EasyDataTable from 'vue3-easy-data-table';
import 'vue3-easy-data-table/dist/style.css';


const app = createApp(App)

app.use(router)
app.component('EasyDataTable', Vue3EasyDataTable);

[ "AuthorLink",
  "ModelLink",
  "ObjectMapLink",
  "ContribLink",
  "ModelGroupLink",
  "ObjectLink",
  "RouterLinkById",
  "ObjectDetailsCard",
].forEach( e => {
  import(`./components/${e}.vue`).then(c => {
    app.component( e, c.default );
  }).catch(ex => {
    console.error("error importing component", e, ": ", ex );
  });;
});

app.mount('#app')
