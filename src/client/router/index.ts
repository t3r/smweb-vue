import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
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
  MergeConfirm: () => import('@/views/MergeConfirmView.vue'),
  MergeAccount: () => import('@/views/MergeAccountView.vue'),
  PositionRequests: () => import('@/views/PositionRequestsView.vue'),
}

const routes: RouteRecordRaw[] = ROUTES_META.map((m) => ({
  path: m.path,
  name: m.name,
  component: routeComponents[m.name],
  meta: {
    title: m.title,
    requiresAuth: m.name === 'PositionRequests',
  },
}))

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to, _from, next) => {
  if (!to.meta?.requiresAuth) {
    next()
    return
  }
  const auth = useAuthStore()
  if (!auth.loaded) {
    await auth.fetchUser()
  }
  if (!auth.isAuthenticated) {
    next({ path: '/', query: { loginRequired: '1' } })
    return
  }
  next()
})

router.afterEach((to) => {
  document.title = to.meta?.title ? `${to.meta.title} – FlightGear Scenemodels` : 'FlightGear Scenemodels'
})

export default router
