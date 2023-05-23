import { createRouter, createWebHistory, createWebHashHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'

const router = createRouter({
//  history: createWebHistory(import.meta.env.BASE_URL),
  history: createWebHashHistory(),
  routes: [
    {
      path: '/login/callback',
      name: 'LoginCallback',
      component: () => import('../views/LoginCallbackView.vue'),
      props: route => ({ code: route.query.code }),
    },
    {
      path: '/login',
      name: 'Login',
      component: () => import('../views/LoginView.vue'),
    },
    {
      path: '/logout',
      name: 'Logout',
      component: () => import('../views/LogoutView.vue'),
    },
    {
      path: '/',
      name: 'home',
      component: HomeView
    },
    {
      path: '/models',
      name: 'Models',
      component: () => import('../views/Models.vue'),
      props: route => ({ shared: route.query.shared, author: route.query.author }),
    },
    {
      path: '/model/:id',
      name: 'Model',
      component: () => import('../views/ModelDetail.vue'),
      props: true,
    },
    {
      path: '/objects',
      name: 'Objects',
      component: () => import('../views/Objects.vue')
    },
    {
      path: '/authors',
      name: 'Authors',
      component: () => import('../views/Authors.vue')
    },
    {
      path: '/author/:id',
      name: 'Author',
      component: () => import('../views/AuthorDetail.vue'),
      props: true,
    },
    {
      path: '/contribs',
      name: 'Contributions',
      component: () => import('../views/Contribs.vue')
    },
    {
      path: '/contrib/object/delete/:id?',
      name: 'DeleteObject',
      component: () => import('../views/ObjectDeleteView.vue'),
      props: true,
    },
    {
      path: '/contrib/object/import',
      name: 'ImportObject',
      component: () => import('../views/ObjectImportView.vue')
    },
    {
      path: '/contrib/object/add',
      name: 'AddObject',
      component: () => import('../views/ObjectAddView.vue')
    },
    {
      path: '/contrib/object/update/:id?',
      name: 'UpdateObject',
      component: () => import('../views/ObjectUpdateView.vue'),
      props: true,
    },
    {
      path: '/contrib/model/add',
      name: 'AddModel',
      component: () => import('../views/ModelAddView.vue')
    },
    {
      path: '/contrib/model/update/:id?',
      name: 'UpdateModel',
      component: () => import('../views/ModelUpdateView.vue'),
      props: true,
    },
    {
      path: '/contrib/:id',
      name: 'Contribution',
      component: () => import('../views/ContributionDetail.vue'),
      props: true,
    },
    {
      path: '/map',
      name: 'Map',
      component: () => import('../views/MapView.vue'),
      props: route => ({ z: route.query.z, lat: route.query.lat, lon: route.query.lon }),

    }
  ]
})

export default router
