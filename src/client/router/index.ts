import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { ROUTES_META, type AppRouteName } from './routesMeta'

const routeComponents: Record<AppRouteName, () => Promise<RouteRecordRaw['component']>> = {
  Home: () => import('@/views/HomeView.vue'),
  News: () => import('@/views/NewsView.vue'),
  About: () => import('@/views/AboutView.vue'),
  Models: () => import('@/views/ModelsView.vue'),
  AddModel: () => import('@/views/AddModelView.vue'),
  EditModel: () => import('@/views/AddModelView.vue'),
  ModelDetail: () => import('@/views/ModelDetailView.vue'),
  Map: () => import('@/views/MapView.vue'),
  Objects: () => import('@/views/ObjectsView.vue'),
  ObjectMassImport: () => import('@/views/ObjectMassImportView.vue'),
  ObjectDetail: () => import('@/views/ObjectDetailView.vue'),
  Authors: () => import('@/views/AuthorsView.vue'),
  AuthorDetail: () => import('@/views/AuthorDetailView.vue'),
  PositionRequests: () => import('@/views/PositionRequestsView.vue'),
}

const routes: RouteRecordRaw[] = ROUTES_META.map((m) => ({
  path: m.path,
  name: m.name,
  component: routeComponents[m.name],
  meta: { title: m.title },
}))

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.afterEach((to) => {
  document.title = to.meta?.title ? `${to.meta.title} – FlightGear Scenemodels` : 'FlightGear Scenemodels'
})

export default router
