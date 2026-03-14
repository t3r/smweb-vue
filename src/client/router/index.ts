import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/', name: 'Home', component: () => import('@/views/HomeView.vue'), meta: { title: 'Home' } },
  { path: '/news', name: 'News', component: () => import('@/views/NewsView.vue'), meta: { title: 'News' } },
  { path: '/models', name: 'Models', component: () => import('@/views/ModelsView.vue'), meta: { title: 'Models' } },
  { path: '/models/add', name: 'AddModel', component: () => import('@/views/AddModelView.vue'), meta: { title: 'Add model' } },
  { path: '/models/:id', name: 'ModelDetail', component: () => import('@/views/ModelDetailView.vue'), meta: { title: 'Model' } },
  { path: '/map', name: 'Map', component: () => import('@/views/MapView.vue'), meta: { title: 'Map' } },
  { path: '/objects', name: 'Objects', component: () => import('@/views/ObjectsView.vue'), meta: { title: 'Objects' } },
  { path: '/objects/import', name: 'ObjectMassImport', component: () => import('@/views/ObjectMassImportView.vue'), meta: { title: 'Mass import objects' } },
  { path: '/objects/:id', name: 'ObjectDetail', component: () => import('@/views/ObjectDetailView.vue'), meta: { title: 'Object' } },
  { path: '/authors', name: 'Authors', component: () => import('@/views/AuthorsView.vue'), meta: { title: 'Authors' } },
  { path: '/authors/:id', name: 'AuthorDetail', component: () => import('@/views/AuthorDetailView.vue'), meta: { title: 'Author' } },
  { path: '/position-requests', name: 'PositionRequests', component: () => import('@/views/PositionRequestsView.vue'), meta: { title: 'Position requests' } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.afterEach((to) => {
  document.title = to.meta?.title ? `${to.meta.title} – FlightGear Scenemodels` : 'FlightGear Scenemodels'
})

export default router
